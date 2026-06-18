import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

class RoleGuard extends StatelessWidget {
  final String requiredRole;
  final Widget child;

  const RoleGuard({
    super.key,
    required this.requiredRole,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF427AB5))),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          // Belum login, arahkan ke root route
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF427AB5))),
          );
        }

        return FutureBuilder<String?>(
          future: AuthService().getUserRole(snapshot.data!.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: Color(0xFF427AB5))),
              );
            }

            final userRole = roleSnapshot.data ?? 'user';

            if (userRole == requiredRole) {
              // Role sesuai, tampilkan halaman yang diminta
              return child;
            } else {
              // Role TIDAK sesuai, lemparkan ke dashboard yang benar
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (userRole == 'admin') {
                  Navigator.pushReplacementNamed(context, '/admin');
                } else {
                  Navigator.pushReplacementNamed(context, '/user');
                }
              });
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: Color(0xFF427AB5))),
              );
            }
          },
        );
      },
    );
  }
}
