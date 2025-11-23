import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/merchant.dart';
import '../../providers/auth_provider.dart';
import '../../services/data_service.dart';
import '../../services/language_service.dart';
import '../../services/csv_service.dart';
import '../../utils/web_utils.dart';
import '../../utils/app_theme.dart';

class AdminDashboardDesktop extends StatefulWidget {
  const AdminDashboardDesktop({super.key});

  @override
  State<AdminDashboardDesktop> createState() => _AdminDashboardDesktopState();
}

class _AdminDashboardDesktopState extends State<AdminDashboardDesktop> {
  final _searchController = TextEditingController();
  List<Merchant> _filteredMerchants = [];
  List<Merchant> _allMerchants = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMerchants();
    });
  }

  void _loadMerchants() {
    setState(() {
      _allMerchants = DataService.instance.merchants;
      _filteredMerchants = _allMerchants;
    });
  }

  void _searchMerchants(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMerchants = _allMerchants;
      } else {
        _filteredMerchants = DataService.instance.searchMerchants(query);
      }
    });
  }

  void _exportToCsv() {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final csv = CsvService.exportMerchantsToCsv(_filteredMerchants, languageService);
    downloadCsv(csv, 'merchants_${DateTime.now().millisecondsSinceEpoch}.csv');
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
    final isRTL = languageService.isRTL;

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
                    authProvider.currentUser?.username[0].toUpperCase() ?? 'A',
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
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.people, color: AppTheme.primaryColor),
                        const SizedBox(width: 12),
                        Text(
                          languageService.getText('التجار', 'Merchants'),
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
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
                    key: ValueKey(_filteredMerchants.length),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // Header
                    Container(
                      decoration: AppTheme.cardDecoration,
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                languageService.getText('التجار', 'Merchants'),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                languageService.getText(
                                  'عرض جميع التجار',
                                  'View all merchants',
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
                    ),
                    const SizedBox(height: 24),
                    // Search bar
                    Container(
                      decoration: AppTheme.cardDecoration,
                      padding: const EdgeInsets.all(20),
                      child: TextField(
                        controller: _searchController,
                        decoration: AppTheme.inputDecoration(
                          hintText: languageService.getText(
                            'البحث عن تاجر...',
                            'Search merchant...',
                          ),
                          prefixIcon: Icons.search,
                        ),
                        onChanged: _searchMerchants,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Merchants list
                    Expanded(
                      child: _filteredMerchants.isEmpty
                          ? Center(
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
                            )
                          : ListView.builder(
                              itemCount: _filteredMerchants.length,
                              itemBuilder: (context, index) {
                                final merchant = _filteredMerchants[index];
                                return TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: Duration(milliseconds: 300 + (index * 50)),
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
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: AppTheme.cardDecoration,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          // Navigate to merchant details
                                        },
                                        borderRadius: BorderRadius.circular(16),
                                        child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    leading: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          merchant.code,
                                          style: const TextStyle(
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      languageService.locale.languageCode == 'ar'
                                          ? merchant.name
                                          : merchant.nameEn,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            merchant.phone,
                                            style: const TextStyle(color: AppTheme.textSecondary),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            merchant.email,
                                            style: const TextStyle(color: AppTheme.textSecondary),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.secondaryColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${languageService.getText("عدد الماكينات", "Terminals")}: ${merchant.terminals.length}',
                                              style: const TextStyle(
                                                color: AppTheme.secondaryColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        merchant.code,
                                        style: const TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
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
          title: Text(langService.getText('الإعدادات', 'Settings')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(langService.getText('اللغة', 'Language')),
                trailing: DropdownButton<Locale>(
                  value: langService.locale,
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

