import 'dart:ui' as ui show TextDirection;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../utils/web_utils.dart';
import '../../utils/app_theme.dart';
import '../../models/terminal.dart';
import '../../providers/auth_provider.dart';
import '../../services/data_service.dart';
import '../../services/language_service.dart';
import '../../services/csv_service.dart';

class MerchantDashboardMobile extends StatefulWidget {
  const MerchantDashboardMobile({super.key});

  @override
  State<MerchantDashboardMobile> createState() => _MerchantDashboardMobileState();
}

class _MerchantDashboardMobileState extends State<MerchantDashboardMobile> {
  final _searchController = TextEditingController();
  String? _selectedTerminalId;
  DateTimeRange? _dateRange;
  TransactionStatus? _selectedStatus;
  List<Transaction> _filteredTransactions = [];
  List<Transaction> _allTransactions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTransactions();
    });
  }

  void _loadTransactions() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser?.merchantId != null) {
      setState(() {
        _allTransactions = DataService.instance
            .getTransactionsByMerchant(authProvider.currentUser!.merchantId!);
        // Set default date range to cover all transactions (from 2020 to now)
        final now = DateTime.now();
        _dateRange = DateTimeRange(
          start: DateTime(2020, 1, 1),
          end: now,
        );
        _filteredTransactions = _allTransactions;
        _filterTransactions();
      });
    }
  }

  void _filterTransactions() {
    setState(() {
      var transactions = _allTransactions;

      if (_selectedTerminalId != null && _selectedTerminalId!.isNotEmpty) {
        transactions = transactions
            .where((t) => t.terminalId == _selectedTerminalId)
            .toList();
      }

      final query = _searchController.text.toLowerCase();
      if (query.isNotEmpty) {
        transactions = transactions.where((t) {
          return t.code.toLowerCase().contains(query) ||
              t.customerName.toLowerCase().contains(query) ||
              t.customerNameEn.toLowerCase().contains(query) ||
              t.cardNumber.contains(query);
        }).toList();
      }

      // Filter by date range
      if (_dateRange != null) {
        transactions = transactions.where((t) {
          try {
            final date = DateTime.parse(t.date);
            final transactionDate = DateTime(date.year, date.month, date.day);
            final startDate = DateTime(_dateRange!.start.year, _dateRange!.start.month, _dateRange!.start.day);
            final endDate = DateTime(_dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day);
            // Check if transaction date is within the range (inclusive on both ends)
            return (transactionDate.isAtSameMomentAs(startDate) || transactionDate.isAfter(startDate)) &&
                   (transactionDate.isAtSameMomentAs(endDate) || transactionDate.isBefore(endDate));
          } catch (e) {
            debugPrint('Error parsing date for transaction ${t.code}: $e');
            // If date parsing fails, include the transaction
            return true;
          }
        }).toList();
      }

      // Filter by status
      if (_selectedStatus != null) {
        transactions = transactions.where((t) => t.status == _selectedStatus).toList();
      }

      _filteredTransactions = transactions;
    });
  }

  void _exportToCsv() {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final csv = CsvService.exportTransactionsToCsv(_filteredTransactions, languageService);
    downloadCsv(csv, 'transactions_${DateTime.now().millisecondsSinceEpoch}.csv');
  }

  Map<String, dynamic> _getStatistics() {
    final total = _filteredTransactions.fold<double>(
      0.0,
      (sum, t) => sum + (t.status == TransactionStatus.success ? t.amount : 0),
    );
    final successful = _filteredTransactions
        .where((t) => t.status == TransactionStatus.success)
        .length;
    final rejected = _filteredTransactions
        .where((t) => t.status == TransactionStatus.rejected)
        .length;
    final pending = _filteredTransactions
        .where((t) => t.status == TransactionStatus.pending)
        .length;

    return {
      'total': total,
      'successful': successful,
      'rejected': rejected,
      'pending': pending,
      'totalCount': _filteredTransactions.length,
    };
  }

  Map<String, dynamic> _getSelectedStatusStatistics() {
    if (_selectedStatus == null) {
      return {'count': 0, 'total': 0.0};
    }

    final filtered = _filteredTransactions.where((t) => t.status == _selectedStatus).toList();
    final count = filtered.length;
    final total = filtered.fold<double>(
      0.0,
      (sum, t) => sum + t.amount,
    );

    return {
      'count': count,
      'total': total,
    };
  }

  String _getStatusLabel(TransactionStatus status, LanguageService languageService) {
    switch (status) {
      case TransactionStatus.success:
        return languageService.getText('العمليات الناجحة', 'Successful Transactions');
      case TransactionStatus.rejected:
        return languageService.getText('العمليات المرفوضة', 'Rejected Transactions');
      case TransactionStatus.pending:
        return languageService.getText('العمليات المعلقة', 'Pending Transactions');
    }
  }

  Color _getStatusColorForCard(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.success:
        return AppTheme.secondaryColor;
      case TransactionStatus.rejected:
        return AppTheme.errorColor;
      case TransactionStatus.pending:
        return AppTheme.warningColor;
    }
  }

  IconData _getStatusIconForCard(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.success:
        return Icons.check_circle;
      case TransactionStatus.rejected:
        return Icons.cancel;
      case TransactionStatus.pending:
        return Icons.pending;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final merchantId = authProvider.currentUser?.merchantId;
    final terminals = merchantId != null
        ? DataService.instance.getTerminalsByMerchant(merchantId)
        : <Terminal>[];

    final textDir = languageService.isRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr;
    
    return Directionality(
      textDirection: textDir,
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
                child: const Icon(Icons.account_balance_wallet, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  languageService.getText('التحويلات', 'Transactions'),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.download, color: AppTheme.primaryColor),
              onPressed: _exportToCsv,
              tooltip: languageService.getText('تصدير CSV', 'Export CSV'),
            ),
            PopupMenuButton<String>(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
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
                    isSelected: false,
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildBottomNavItem(
                    icon: Icons.receipt_long,
                    label: languageService.getText('التحويلات', 'Transactions'),
                    isSelected: true,
                    onTap: () {},
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                decoration: AppTheme.cardDecoration,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languageService.getText('التحويلات', 'Transactions'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      languageService.getText(
                        'عرض جميع التحويلات المالية',
                        'View all financial transactions',
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Filters Card
              Container(
                decoration: AppTheme.cardDecoration,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Search Field
                    TextField(
                      controller: _searchController,
                      decoration: AppTheme.inputDecoration(
                        hintText: languageService.getText(
                          'البحث عن تحويل...',
                          'Search transaction...',
                        ),
                        prefixIcon: Icons.search,
                      ),
                      onChanged: (_) => _filterTransactions(),
                    ),
                    const SizedBox(height: 12),
                    // Terminal Filter
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedTerminalId ?? 'all',
                        underline: const SizedBox(),
                        icon: Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                        items: [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text(
                              languageService.getText('جميع الماكينات', 'All Terminals'),
                              style: const TextStyle(color: AppTheme.textPrimary),
                            ),
                          ),
                          ...terminals.map((terminal) => DropdownMenuItem(
                                value: terminal.id,
                                child: Text(
                                  languageService.locale.languageCode == 'ar'
                                      ? terminal.name
                                      : terminal.nameEn,
                                  style: const TextStyle(color: AppTheme.textPrimary),
                                ),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedTerminalId = value == 'all' ? null : value;
                          });
                          _filterTransactions();
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Status Filter
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButton<TransactionStatus?>(
                        isExpanded: true,
                        value: _selectedStatus,
                        underline: const SizedBox(),
                        icon: Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                        hint: Text(
                          languageService.getText('جميع الحالات', 'All Statuses'),
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        items: [
                          DropdownMenuItem<TransactionStatus?>(
                            value: null,
                            child: Text(
                              languageService.getText('جميع الحالات', 'All Statuses'),
                              style: const TextStyle(color: AppTheme.textPrimary),
                            ),
                          ),
                          DropdownMenuItem<TransactionStatus>(
                            value: TransactionStatus.success,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.secondaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  languageService.getText('نجحت', 'Success'),
                                  style: const TextStyle(color: AppTheme.textPrimary),
                                ),
                              ],
                            ),
                          ),
                          DropdownMenuItem<TransactionStatus>(
                            value: TransactionStatus.rejected,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.errorColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  languageService.getText('مرفوضة', 'Rejected'),
                                  style: const TextStyle(color: AppTheme.textPrimary),
                                ),
                              ],
                            ),
                          ),
                          DropdownMenuItem<TransactionStatus>(
                            value: TransactionStatus.pending,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.warningColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  languageService.getText('معلقة', 'Pending'),
                                  style: const TextStyle(color: AppTheme.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value;
                          });
                          _filterTransactions();
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Date Range Picker
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showDateRangePickerDialog(context, languageService),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 20, color: AppTheme.textSecondary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _dateRange != null
                                      ? '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'
                                      : languageService.getText('اختر التاريخ', 'Select Date Range'),
                                  style: TextStyle(
                                    color: _dateRange != null ? AppTheme.textPrimary : AppTheme.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Transactions List
              if (_filteredTransactions.isEmpty)
                Container(
                  decoration: AppTheme.cardDecoration,
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox, size: 64, color: AppTheme.textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        languageService.getText('لا توجد نتائج', 'No results found'),
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._filteredTransactions.asMap().entries.map<Widget>((entry) {
                  final index = entry.key;
                  final transaction = entry.value;
                  final terminal = DataService.instance
                      .getTerminalById(transaction.terminalId);
                  final statusText = languageService.locale.languageCode == 'ar'
                      ? _getStatusAr(transaction.status)
                      : _getStatusEn(transaction.status);
                  final customerName = languageService.locale.languageCode == 'ar'
                      ? transaction.customerName
                      : transaction.customerNameEn;

                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 200 + (index * 30)),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 15 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: AppTheme.cardDecoration,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            // Handle tap
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          transaction.code,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${transaction.date} ${transaction.time}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(transaction.status).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(
                                        color: _getStatusColor(transaction.status),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.store, size: 16, color: AppTheme.textSecondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      terminal != null
                                          ? (languageService.locale.languageCode == 'ar'
                                              ? terminal.name
                                              : terminal.nameEn)
                                          : transaction.terminalId,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.person, size: 16, color: AppTheme.textSecondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      customerName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${NumberFormat('#,###.00', 'en_US').format(transaction.amount)} د.ل',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  );
                }),
              // Statistics Card - Only show when status is selected
              if (_selectedStatus != null) ...[
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final stats = _getSelectedStatusStatistics();
                    final statusColor = _getStatusColorForCard(_selectedStatus!);
                    final statusIcon = _getStatusIconForCard(_selectedStatus!);
                    final statusLabel = _getStatusLabel(_selectedStatus!, languageService);
                    
                    return Container(
                      decoration: AppTheme.cardDecoration,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              statusLabel,
                              NumberFormat('#,###', 'en_US').format(stats['count']),
                              statusColor,
                              statusIcon,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 50,
                            color: AppTheme.borderColor,
                          ),
                          Expanded(
                            child: _buildStatItem(
                              languageService.getText('الإجمالي', 'Total'),
                              '${NumberFormat('#,###.00', 'en_US').format(stats['total'])} د.ل',
                              AppTheme.primaryColor,
                              Icons.account_balance_wallet,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusAr(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.success:
        return 'نجحت';
      case TransactionStatus.rejected:
        return 'مرفوضة';
      case TransactionStatus.pending:
        return 'معلقة';
    }
  }

  String _getStatusEn(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.success:
        return 'Success';
      case TransactionStatus.rejected:
        return 'Rejected';
      case TransactionStatus.pending:
        return 'Pending';
    }
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.success:
        return AppTheme.secondaryColor;
      case TransactionStatus.rejected:
        return AppTheme.errorColor;
      case TransactionStatus.pending:
        return AppTheme.warningColor;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd', 'en_US').format(date);
  }

  Future<void> _showDateRangePickerDialog(BuildContext context, LanguageService languageService) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryColor,
            ),
            cardColor: Colors.white,
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.white,
            ),
            scaffoldBackgroundColor: Colors.white,
          ),
          child: Directionality(
            textDirection: languageService.isRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            child: child!,
          ),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
      _filterTransactions();
    }
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
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
