import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import '../../utils/responsive.dart';
import '../../widgets/desktop/merchant_dashboard_desktop.dart';
import '../../widgets/mobile/merchant_dashboard_mobile.dart';

class MerchantTransactionsScreen extends StatefulWidget {
  const MerchantTransactionsScreen({super.key});

  @override
  State<MerchantTransactionsScreen> createState() => _MerchantTransactionsScreenState();
}

class _MerchantTransactionsScreenState extends State<MerchantTransactionsScreen> {
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
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.1, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  )),
                  child: child,
                ),
              );
            },
            child: isMobile
                ? const MerchantDashboardMobile(key: ValueKey('mobile'))
                : const MerchantDashboardDesktop(key: ValueKey('desktop')),
          ),
        );
      },
    );
  }
}

