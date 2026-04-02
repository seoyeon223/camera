import 'package:camera/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'core/constants/route_names.dart';
import 'screens/home/home_screen.dart';
import 'screens/detect/detect_screen.dart';
import 'screens/map/map_screen.dart';
import 'screens/report/report_screen.dart';
import 'screens/guide/guide_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/admin/admin_login_page.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/business/business_register_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Camera Safe Map',
      theme: AppTheme.lightTheme,
      initialRoute: RouteNames.home,
      routes: {
        RouteNames.home: (_) => const HomeScreen(),
        RouteNames.detect: (_) => const DetectScreen(),
        RouteNames.map: (_) => const MapScreen(),
        RouteNames.report: (_) => const ReportScreen(),
        RouteNames.guide: (_) => const GuideScreen(),
        RouteNames.history: (_) => const HistoryScreen(),
        RouteNames.adminLogin: (_) => const AdminLoginPage(),
        RouteNames.admin: (_) => const AdminScreen(),
        RouteNames.businessRegister: (_) => const BusinessRegisterScreen(),
        RouteNames.businessRegisterSuccess: (_) => const BusinessRegisterSuccessScreen(),
        RouteNames.reportCompleteScreen: (_) => const ReportCompleteScreen(),
      },
    );
  }
}