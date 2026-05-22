import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../landing_page.dart';
import '../admin/dashboard_admin.dart';
import '../user/dashboard_user.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Sedang mengecek status login
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF427AB5)),
            ),
          );
        }

        // Jika user sudah login
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          return FutureBuilder<String?>(
            future: AuthService().getUserRole(user.uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(color: Color(0xFF427AB5)),
                  ),
                );
              }

              // Arahkan sesuai role
              if (roleSnapshot.data == 'admin') {
                return const DashboardAdmin();
              } else {
                return const DashboardUser();
              }
            },
          );
        }

        // Jika belum login, langsung ke Landing Page
        return const LandingPage();
      },
    );
  }
}
