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

class MerchantHomeDesktop extends StatefulWidget {
  const MerchantHomeDesktop({super.key});

  @override
  State<MerchantHomeDesktop> createState() => _MerchantHomeDesktopState();
}

class _MerchantHomeDesktopState extends State<MerchantHomeDesktop> {
  String _selectedPeriod = 'all'; // all, week, month, year

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  List<Transaction> _getFilteredTransactions() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser?.merchantId == null) return [];
    
    var transactions = DataService.instance
        .getTransactionsByMerchant(authProvider.currentUser!.merchantId!);
    
    // For testing, return all transactions if period is 'all'
    // In production, filter by actual date range
    if (_selectedPeriod == 'all') {
      return transactions;
    }
    
    // Sort by date descending to show latest first
    transactions.sort((a, b) => b.date.compareTo(a.date));
    
    // Return limited results based on period
    switch (_selectedPeriod) {
      case 'week':
        return transactions.take(7).toList();
      case 'month':
        return transactions.take(30).toList();
      case 'year':
        return transactions.take(365).toList();
      default:
        return transactions;
    }
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
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.dashboard, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              Text(
                languageService.getText('لوحة التحكم', 'Dashboard'),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              icon: Container(
                margin: const EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    authProvider.currentUser?.username[0].toUpperCase() ?? 'M',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout, size: 20, color: AppTheme.textPrimary),
                      const SizedBox(width: 8),
                      Text(languageService.getText('تسجيل الخروج', 'Logout')),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'logout') {
                  authProvider.logout();
                }
              },
            ),
          ],
        ),
        body: Row(
          children: [
            // Sidebar
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  right: BorderSide(color: AppTheme.borderColor, width: 1),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildNavItem(
                    icon: Icons.dashboard,
                    title: languageService.getText('الرئيسية', 'Home'),
                    isSelected: true,
                    onTap: () {},
                  ),
                  _buildNavItem(
                    icon: Icons.receipt_long,
                    title: languageService.getText('التحويلات', 'Transactions'),
                    isSelected: false,
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
                  const Spacer(),
                  // Settings and Notifications in Sidebar
                  _buildNavItem(
                    icon: Icons.notifications_outlined,
                    title: languageService.getText('الإشعارات', 'Notifications'),
                    isSelected: false,
                    onTap: () {
                      // Handle notifications
                    },
                  ),
                  _buildNavItem(
                    icon: Icons.settings,
                    title: languageService.getText('الإعدادات', 'Settings'),
                    isSelected: false,
                    onTap: () {
                      _showSettingsDialog(context);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            // Main content
            Expanded(
              child: Container(
                color: AppTheme.backgroundColor,
                padding: const EdgeInsets.all(32.0),
                child: SingleChildScrollView(
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
                                  icon: Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'all',
                                      child: Text(
                                        languageService.getText('الكل', 'All'),
                                        style: const TextStyle(color: AppTheme.textPrimary),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'week',
                                      child: Text(
                                        languageService.getText('أسبوع', 'Week'),
                                        style: const TextStyle(color: AppTheme.textPrimary),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'month',
                                      child: Text(
                                        languageService.getText('شهر', 'Month'),
                                        style: const TextStyle(color: AppTheme.textPrimary),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'year',
                                      child: Text(
                                        languageService.getText('سنة', 'Year'),
                                        style: const TextStyle(color: AppTheme.textPrimary),
                                      ),
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
                      const SizedBox(height: 32),
                      // Statistics Cards
                      Row(
                        children: [
                          Expanded(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: child,
                                  ),
                                );
                              },
                              child: StatCard(
                                title: languageService.getText('إجمالي التحويلات', 'Total Transactions'),
                                value: '${(stats['total'] as double).toStringAsFixed(2)} د.ل',
                                subtitle: languageService.getText(
                                  'إجمالي المبلغ',
                                  'Total Amount',
                                ),
                                icon: Icons.account_balance_wallet,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: child,
                                  ),
                                );
                              },
                              child: StatCard(
                                title: languageService.getText('نجحت', 'Successful'),
                                value: '${stats['successful']}',
                                subtitle: languageService.getText(
                                  'تحويلات ناجحة',
                                  'Successful transactions',
                                ),
                                icon: Icons.check_circle,
                                color: AppTheme.secondaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: child,
                                  ),
                                );
                              },
                              child: StatCard(
                                title: languageService.getText('مرفوضة', 'Rejected'),
                                value: '${stats['rejected']}',
                                subtitle: languageService.getText(
                                  'تحويلات مرفوضة',
                                  'Rejected transactions',
                                ),
                                icon: Icons.cancel,
                                color: AppTheme.errorColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: child,
                                  ),
                                );
                              },
                              child: StatCard(
                                title: languageService.getText('معلقة', 'Pending'),
                                value: '${stats['pending']}',
                                subtitle: languageService.getText(
                                  'تحويلات معلقة',
                                  'Pending transactions',
                                ),
                                icon: Icons.pending,
                                color: AppTheme.warningColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Charts
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: ChartCard(
                              title: languageService.getText('الحركة المالية', 'Financial Activity'),
                              period: _selectedPeriod,
                              transactions: _getFilteredTransactions(),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: ChartCard(
                              title: languageService.getText('حالة التحويلات', 'Transaction Status'),
                              period: _selectedPeriod,
                              transactions: _getFilteredTransactions(),
                              isPieChart: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
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

