import 'package:flutter/material.dart';
import '../screens/auth/auth_wrapper.dart';
import '../screens/auth/login_page.dart';
import '../screens/auth/register_page.dart';
import '../screens/admin/dashboard_admin.dart';
import '../screens/user/dashboard_user.dart';
import '../screens/landing_page.dart';
import '../screens/auth/role_guard.dart';

class AppRoutes {
  // 🔥 ROUTE NAME (BIAR GA TYPO)
  static const String splash = '/';
  static const String login = '/login';
  static const String adminDashboard = '/admin';
  static const String userDashboard = '/user';
  static const String landing = '/landing';
  static const String register = '/register';

  // 🔥 ROUTES MAP
  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const AuthWrapper(),
    login: (context) => LoginPage(),
    adminDashboard: (context) => const RoleGuard(requiredRole: 'admin', child: DashboardAdmin()),
    userDashboard: (context) => const RoleGuard(requiredRole: 'user', child: DashboardUser()),
    landing: (context) => const LandingPage(),
    register: (context) => const RegisterPage(),
  };
}
