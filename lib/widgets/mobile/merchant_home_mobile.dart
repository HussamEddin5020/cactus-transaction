import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transaction.dart';
import '../../providers/auth_provider.dart';
import '../../services/data_service.dart';
import '../../services/language_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/chart_card.dart';
import '../../screens/merchant/merchant_transactions_screen.dart';

class MerchantHomeMobile extends StatefulWidget {
  const MerchantHomeMobile({super.key});

  @override
  State<MerchantHomeMobile> createState() => _MerchantHomeMobileState();
}

class _MerchantHomeMobileState extends State<MerchantHomeMobile> {
  String _selectedPeriod = 'all';
  int _selectedIndex = 0;

  List<Transaction> _getFilteredTransactions() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser?.merchantId == null) return [];
    
    var transactions = DataService.instance
        .getTransactionsByMerchant(authProvider.currentUser!.merchantId!);
    
    // For 'all', return all transactions
    if (_selectedPeriod == 'all') {
      return transactions;
    }
    
    // For other periods, filter by date range
    final now = DateTime.now();
    transactions = transactions.where((t) {
      try {
        final date = DateTime.parse(t.date);
        switch (_selectedPeriod) {
          case 'week':
            return date.isAfter(now.subtract(const Duration(days: 7)));
          case 'month':
            return date.isAfter(now.subtract(const Duration(days: 30)));
          case 'year':
            return date.isAfter(now.subtract(const Duration(days: 365)));
          default:
            return true;
        }
      } catch (e) {
        return true;
      }
    }).toList();
    
    return transactions;
  }

  Map<String, dynamic> _getStatistics() {
    final transactions = _getFilteredTransactions();
    final total = transactions.fold<double>(
      0.0,
      (sum, t) => sum + (t.status == TransactionStatus.success ? t.amount : 0),
    );
    final successful = transactions
        .where((t) => t.status == TransactionStatus.success)
        .length;
    final rejected = transactions
        .where((t) => t.status == TransactionStatus.rejected)
        .length;
    final pending = transactions
        .where((t) => t.status == TransactionStatus.pending)
        .length;

    return {
      'total': total,
      'successful': successful,
      'rejected': rejected,
      'pending': pending,
      'totalCount': transactions.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isRTL = languageService.isRTL;
    final stats = _getStatistics();

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: Text(
            languageService.getText('لوحة التحكم', 'Dashboard'),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: AppTheme.textSecondary),
              onPressed: () {
                _showSettingsDialog(context);
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: DropdownButton<String>(
                      value: _selectedPeriod,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text(languageService.getText('الكل', 'All')),
                        ),
                        DropdownMenuItem(
                          value: 'week',
                          child: Text(languageService.getText('أسبوع', 'Week')),
                        ),
                        DropdownMenuItem(
                          value: 'month',
                          child: Text(languageService.getText('شهر', 'Month')),
                        ),
                        DropdownMenuItem(
                          value: 'year',
                          child: Text(languageService.getText('سنة', 'Year')),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedPeriod = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Statistics Cards
              StatCard(
                title: languageService.getText('إجمالي التحويلات', 'Total Transactions'),
                value: '${(stats['total'] as double).toStringAsFixed(2)} د.ل',
                subtitle: languageService.getText('إجمالي المبلغ', 'Total Amount'),
                icon: Icons.account_balance_wallet,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: languageService.getText('نجحت', 'Successful'),
                      value: '${stats['successful']}',
                      subtitle: languageService.getText('تحويلات', 'transactions'),
                      icon: Icons.check_circle,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: languageService.getText('مرفوضة', 'Rejected'),
                      value: '${stats['rejected']}',
                      subtitle: languageService.getText('تحويلات', 'transactions'),
                      icon: Icons.cancel,
                      color: AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StatCard(
                title: languageService.getText('معلقة', 'Pending'),
                value: '${stats['pending']}',
                subtitle: languageService.getText('تحويلات', 'transactions'),
                icon: Icons.pending,
                color: AppTheme.warningColor,
              ),
              const SizedBox(height: 24),
              // Charts
              ChartCard(
                title: languageService.getText('الحركة المالية', 'Financial Activity'),
                period: _selectedPeriod,
                transactions: _getFilteredTransactions(),
              ),
              const SizedBox(height: 16),
              ChartCard(
                title: languageService.getText('حالة التحويلات', 'Transaction Status'),
                period: _selectedPeriod,
                transactions: _getFilteredTransactions(),
                isPieChart: true,
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppTheme.borderColor, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBottomNavItem(
                    icon: Icons.dashboard,
                    label: languageService.getText('الرئيسية', 'Home'),
                    isSelected: _selectedIndex == 0,
                    onTap: () {
                      setState(() {
                        _selectedIndex = 0;
                      });
                    },
                  ),
                  _buildBottomNavItem(
                    icon: Icons.receipt_long,
                    label: languageService.getText('التحويلات', 'Transactions'),
                    isSelected: _selectedIndex == 1,
                    onTap: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              const MerchantTransactionsScreen(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1.0, 0.0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOut,
                              )),
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 300),
                        ),
                      );
                    },
                  ),
                  _buildBottomNavItem(
                    icon: Icons.notifications_outlined,
                    label: languageService.getText('الإشعارات', 'Notifications'),
                    isSelected: false,
                    onTap: () {
                      // Handle notifications
                    },
                  ),
                  _buildBottomNavItem(
                    icon: Icons.settings,
                    label: languageService.getText('الإعدادات', 'Settings'),
                    isSelected: false,
                    onTap: () {
                      _showSettingsDialog(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    showDialog(
      context: context,
      builder: (dialogContext) => Consumer<LanguageService>(
        builder: (context, langService, child) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(langService.getText('الإعدادات', 'Settings')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.inputBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<Locale>(
                  isExpanded: true,
                  value: langService.locale,
                  underline: const SizedBox(),
                  icon: Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                  items: const [
                    DropdownMenuItem(
                      value: Locale('ar'),
                      child: Text('العربية'),
                    ),
                    DropdownMenuItem(
                      value: Locale('en'),
                      child: Text('English'),
                    ),
                  ],
                  onChanged: (locale) {
                    if (locale != null) {
                      langService.setLocale(locale);
                      Navigator.pop(dialogContext);
                    }
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(langService.getText('إغلاق', 'Close')),
            ),
          ],
        ),
      ),
    );
  }
}

