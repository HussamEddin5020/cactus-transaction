import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import '../../utils/responsive.dart';
import '../../widgets/desktop/admin_dashboard_desktop.dart';
import '../../widgets/mobile/admin_dashboard_mobile.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late Future<void> _loadDataFuture;

  @override
  void initState() {
    super.initState();
    _loadDataFuture = DataService.instance.loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    return FutureBuilder<void>(
      future: _loadDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        return Scaffold(
          body: isMobile
              ? const AdminDashboardMobile()
              : const AdminDashboardDesktop(),
        );
      },
    );
  }
}

