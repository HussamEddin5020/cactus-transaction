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

class MerchantDashboardDesktop extends StatefulWidget {
  const MerchantDashboardDesktop({super.key});

  @override
  State<MerchantDashboardDesktop> createState() => _MerchantDashboardDesktopState();
}

class _MerchantDashboardDesktopState extends State<MerchantDashboardDesktop> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
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

      // Filter by terminal
      if (_selectedTerminalId != null && _selectedTerminalId!.isNotEmpty) {
        transactions = transactions
            .where((t) => t.terminalId == _selectedTerminalId)
            .toList();
      }

      // Filter by search
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
    _scrollController.dispose();
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
                    isSelected: false,
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildNavItem(
                    icon: Icons.receipt_long,
                    title: languageService.getText('التحويلات', 'Transactions'),
                    isSelected: true,
                    onTap: () {},
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
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.05, 0.0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOut,
                          )),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      key: ValueKey(_filteredTransactions.length),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    // Header and Filters Container
                    Container(
                      decoration: AppTheme.cardDecoration,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    languageService.getText('التحويلات', 'Transactions'),
                                    style: const TextStyle(
                                      fontSize: 24,
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
                              ElevatedButton.icon(
                                onPressed: _exportToCsv,
                                icon: const Icon(Icons.download, size: 18),
                                label: Text(languageService.getText('تصدير CSV', 'Export CSV')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Filters
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
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
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: Container(
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
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: Container(
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
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: Material(
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
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      child: Row(
                                        children: [
                                          Icon(Icons.calendar_today, size: 18, color: AppTheme.textSecondary),
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
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Transactions table
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _filteredTransactions.isEmpty
                            ? SizedBox(
                                height: 400,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(40),
                                    decoration: AppTheme.cardDecoration,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.inbox, size: 64, color: AppTheme.textSecondary),
                                        const SizedBox(height: 16),
                                        Text(
                                          languageService.getText(
                                            'لا توجد نتائج',
                                            'No results found',
                                          ),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme.borderColor,
                                    width: 1,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Table Header
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF9FAFB).withOpacity(0.3),
                                        border: Border(
                                          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
                                        ),
                                      ),
                                      child: Table(
                                        columnWidths: const {
                                          0: FlexColumnWidth(1.2),
                                          1: FlexColumnWidth(1.0),
                                          2: FlexColumnWidth(1.0),
                                          3: FlexColumnWidth(1.8),
                                          4: FlexColumnWidth(1.2),
                                          5: FlexColumnWidth(0.8),
                                          6: FlexColumnWidth(1.5),
                                        },
                                        children: [
                                          TableRow(
                                            children: [
                                              _buildHeaderCell(languageService.getText('كود العملية', 'Transaction Code')),
                                              _buildHeaderCell(languageService.getText('التاريخ', 'Date')),
                                              _buildHeaderCell(languageService.getText('الوقت', 'Time')),
                                              _buildHeaderCell(languageService.getText('الماكينة', 'Terminal')),
                                              _buildHeaderCell(languageService.getText('المبلغ', 'Amount')),
                                              _buildHeaderCell(languageService.getText('الحالة', 'Status')),
                                              _buildHeaderCell(languageService.getText('العميل', 'Customer')),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Table Body - Fixed height for 10 rows
                                    SizedBox(
                                      height: 10 * 64.0, // 64px per row (16px padding top + 16px padding bottom + 32px content)
                                      child: Scrollbar(
                                        controller: _scrollController,
                                        child: ListView.separated(
                                          controller: _scrollController,
                                          padding: EdgeInsets.zero,
                                          itemCount: _filteredTransactions.length,
                                          separatorBuilder: (context, index) => Container(
                                            height: 1,
                                            margin: const EdgeInsets.symmetric(horizontal: 24),
                                            color: AppTheme.borderColor,
                                          ),
                                        itemBuilder: (context, index) {
                                          final transaction = _filteredTransactions[index];
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
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () {
                                                  // Handle row tap
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                                  decoration: const BoxDecoration(
                                                    color: Colors.white,
                                                  ),
                                                  child: Table(
                                                    columnWidths: const {
                                                      0: FlexColumnWidth(1.2),
                                                      1: FlexColumnWidth(1.0),
                                                      2: FlexColumnWidth(1.0),
                                                      3: FlexColumnWidth(1.8),
                                                      4: FlexColumnWidth(1.2),
                                                      5: FlexColumnWidth(1.0),
                                                      6: FlexColumnWidth(1.5),
                                                    },
                                                    children: [
                                                      TableRow(
                                                        children: [
                                                          _buildDataCell(transaction.code),
                                                          _buildDataCell(transaction.date),
                                                          _buildDataCell(transaction.time),
                                                          _buildDataCell(
                                                            terminal != null
                                                                ? (languageService.locale.languageCode == 'ar'
                                                                    ? terminal.name
                                                                    : terminal.nameEn)
                                                                : transaction.terminalId,
                                                          ),
                                                          _buildAmountCell(
                                                            transaction.amount,
                                                            transaction.status,
                                                          ),
                                                          _buildStatusCell(statusText, transaction.status),
                                                          _buildDataCell(customerName),
                                                        ],
                                                  ),
                                                ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        // Statistics Card - Only show when status is selected
                        if (_selectedStatus != null) ...[
                          const SizedBox(height: 24),
                          Builder(
                            builder: (context) {
                              final stats = _getSelectedStatusStatistics();
                              final statusColor = _getStatusColorForCard(_selectedStatus!);
                              final statusIcon = _getStatusIconForCard(_selectedStatus!);
                              final statusLabel = _getStatusLabel(_selectedStatus!, languageService);
                              
                              return Container(
                                decoration: AppTheme.cardDecoration,
                                padding: const EdgeInsets.all(24),
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
                                      height: 60,
                                      color: AppTheme.borderColor,
                                    ),
                                    Expanded(
                                      child: _buildStatItem(
                                        languageService.getText('إجمالي المبلغ', 'Total Amount'),
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDataCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          text,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildAmountCell(double amount, TransactionStatus status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          '${NumberFormat('#,###.00', 'en_US').format(amount)} د.ل',
          style: TextStyle(
            color: status == TransactionStatus.success
                ? AppTheme.secondaryColor
                : status == TransactionStatus.rejected
                    ? AppTheme.errorColor
                    : AppTheme.warningColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCell(String statusText, TransactionStatus status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          constraints: const BoxConstraints(minWidth: 70, maxWidth: 100),
          decoration: BoxDecoration(
            color: _getStatusColor(status),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Icon(icon, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

