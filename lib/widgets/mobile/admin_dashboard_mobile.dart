import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/merchant.dart';
import '../../utils/web_utils.dart';
import '../../providers/auth_provider.dart';
import '../../services/data_service.dart';
import '../../services/language_service.dart';
import '../../services/csv_service.dart';

class AdminDashboardMobile extends StatefulWidget {
  const AdminDashboardMobile({super.key});

  @override
  State<AdminDashboardMobile> createState() => _AdminDashboardMobileState();
}

class _AdminDashboardMobileState extends State<AdminDashboardMobile> {
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
        appBar: AppBar(
          title: Text(languageService.getText('لوحة التحكم', 'Dashboard')),
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _exportToCsv,
            ),
            PopupMenuButton<String>(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'settings',
                  child: Text(languageService.getText('الإعدادات', 'Settings')),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Text(languageService.getText('تسجيل الخروج', 'Logout')),
                ),
              ],
              onSelected: (value) {
                if (value == 'logout') {
                  authProvider.logout();
                } else if (value == 'settings') {
                  _showSettingsDialog(context);
                }
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    languageService.getText('التجار', 'Merchants'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: languageService.getText(
                        'البحث عن تاجر...',
                        'Search merchant...',
                      ),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: _searchMerchants,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _filteredMerchants.isEmpty
                  ? Center(
                      child: Text(
                        languageService.getText(
                          'لا توجد نتائج',
                          'No results found',
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredMerchants.length,
                      itemBuilder: (context, index) {
                        final merchant = _filteredMerchants[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(merchant.code),
                            ),
                            title: Text(
                              languageService.locale.languageCode == 'ar'
                                  ? merchant.name
                                  : merchant.nameEn,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(merchant.phone),
                                Text(merchant.email),
                                Text(
                                  '${languageService.getText("عدد الماكينات", "Terminals")}: ${merchant.terminals.length}',
                                ),
                              ],
                            ),
                            trailing: Text(
                              merchant.code,
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.bold,
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

