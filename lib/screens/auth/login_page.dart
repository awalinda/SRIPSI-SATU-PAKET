import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';
import '../../widgets/custom_notification.dart';
import '../../widgets/google_logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // Inline error messages
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  bool _validate() {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+');
    String? emailErr;
    String? passErr;

    if (username.text.trim().isEmpty) {
      emailErr = "Email tidak boleh kosong";
    } else if (!emailRegex.hasMatch(username.text.trim())) {
      emailErr = "Format email tidak valid";
    }

    if (password.text.isEmpty) {
      passErr = "Kata sandi tidak boleh kosong";
    }

    setState(() {
      _emailError = emailErr;
      _passwordError = passErr;
    });

    return emailErr == null && passErr == null;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // 🔥 BACKGROUND GRADIENT
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF427AB5),
                    Color(0xFF3F7CAC),
                    Color(0xFFBDEBFF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // 🔥 BACKGROUND IMAGE
            Positioned(
              bottom: 0,
              left: 0,
              child: Opacity(
                opacity: 0.1,
                child: Image.asset(
                  "lib/assets/images/logistics.png",
                  width: isDesktop ? 400 : 250,
                ),
              ),
            ),

            // 🔥 CONTENT
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: isDesktop ? 20 : 10,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: isDesktop ? 950 : 380,
                      padding: EdgeInsets.all(isDesktop ? 30 : 15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Flex(
                        direction: isDesktop ? Axis.horizontal : Axis.vertical,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ================= LEFT =================
                          if (isDesktop)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: _buildLeftContent(),
                              ),
                            )
                          else
                            _buildLeftContent(isMobile: true),

                          // ================= RIGHT =================
                          Container(
                            width: isDesktop ? 350 : double.infinity,
                            padding: EdgeInsets.all(isDesktop ? 25 : 15),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                              border: Border.all(color: Colors.white30),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Masuk",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: isDesktop ? 30 : 20),

                                // Email field
                                _buildInputField(
                                  controller: username,
                                  hint: "Email",
                                  errorText: _emailError,
                                  keyboardType: TextInputType.emailAddress,
                                  onChanged: (_) =>
                                      setState(() => _emailError = null),
                                ),
                                const SizedBox(height: 8),

                                // Password field
                                _buildInputField(
                                  controller: password,
                                  hint: "Kata Sandi",
                                  isPassword: true,
                                  errorText: _passwordError,
                                  onChanged: (_) =>
                                      setState(() => _passwordError = null),
                                ),

                                // 🔥 FORGOT PASSWORD
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const ForgotPasswordPage(),
                                              ),
                                            );
                                          },
                                    child: const Text(
                                      "Lupa kata sandi?",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),

                                // 🔥 BUTTON LOGIN
                                InkWell(
                                  onTap: _isLoading
                                      ? null
                                      : () async {
                                          if (!_validate()) return;

                                          setState(() => _isLoading = true);
                                          try {
                                            final userCredential =
                                                await AuthService()
                                                    .signInWithEmail(
                                                      username.text.trim(),
                                                      password.text,
                                                    );

                                            if (userCredential != null) {
                                              final user = userCredential.user;
                                              if (user != null &&
                                                  context.mounted) {
                                                // Cek verifikasi email terbaru dari server
                                                await FirebaseAuth.instance.currentUser?.reload();
                                                final updatedUser = FirebaseAuth.instance.currentUser;
                                                
                                                String? role =
                                                    await AuthService()
                                                        .getUserRole(user.uid);

                                                if (updatedUser != null && !updatedUser.emailVerified && role != 'admin') {
                                                  if (context.mounted) {
                                                    await showDialog(
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                        title: const Row(
                                                          children: [
                                                            Icon(Icons.mark_email_unread_rounded, color: Colors.orange),
                                                            SizedBox(width: 10),
                                                            Text("Verifikasi Email"),
                                                          ],
                                                        ),
                                                        content: const Text("Akun Anda belum diverifikasi. Silakan cek email Anda (termasuk folder Spam). Jika belum menerima, Anda bisa mengirim ulang tautan verifikasi."),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () async {
                                                              try {
                                                                await updatedUser.sendEmailVerification();
                                                                if (context.mounted) {
                                                                  Navigator.pop(context);
                                                                  CustomNotification.showSuccess(context, "Email verifikasi telah dikirim ulang!");
                                                                }
                                                              } catch (e) {
                                                                if (context.mounted) {
                                                                  Navigator.pop(context);
                                                                  CustomNotification.showError(context, "Gagal mengirim ulang: Terlalu banyak percobaan, coba lagi nanti.");
                                                                }
                                                              }
                                                            },
                                                            child: const Text("Kirim Ulang", style: TextStyle(fontWeight: FontWeight.bold)),
                                                          ),
                                                          ElevatedButton(
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: const Color(0xFF427AB5),
                                                              foregroundColor: Colors.white,
                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                            ),
                                                            onPressed: () => Navigator.pop(context),
                                                            child: const Text("Mengerti"),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }
                                                  await AuthService().signOut();
                                                  setState(() => _isLoading = false);
                                                  return;
                                                }

                                                if (context.mounted) {
                                                  if (role == "admin") {
                                                    CustomNotification.showSuccess(
                                                      context,
                                                      "Selamat datang, Admin!",
                                                    );
                                                    Navigator.pushReplacementNamed(
                                                      context,
                                                      AppRoutes.adminDashboard,
                                                    );
                                                  } else {
                                                    CustomNotification.showSuccess(
                                                      context,
                                                      "Berhasil masuk!",
                                                    );
                                                    Navigator.pushReplacementNamed(
                                                      context,
                                                      AppRoutes.userDashboard,
                                                    );
                                                  }
                                                }
                                              }
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              // Tampilkan error Firebase sebagai inline error di password
                                              setState(
                                                () => _passwordError =
                                                    AuthService.getErrorMessage(
                                                      e,
                                                    ),
                                              );
                                            }
                                          } finally {
                                            if (mounted)
                                              setState(
                                                () => _isLoading = false,
                                              );
                                          }
                                        },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF427AB5),
                                          Color(0xFFBDEBFF),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    alignment: Alignment.center,
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            "Masuk",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                //  GOOGLE SIGN IN
                                InkWell(
                                  onTap: _isLoading
                                      ? null
                                      : () async {
                                          setState(() => _isLoading = true);
                                          try {
                                            final userCredential =
                                                await AuthService()
                                                    .signInWithGoogle();
                                            if (userCredential != null) {
                                              final user = userCredential.user;
                                              if (user != null &&
                                                  context.mounted) {
                                                String? role =
                                                    await AuthService()
                                                        .getUserRole(user.uid);
                                                if (context.mounted) {
                                                  if (role == "admin") {
                                                    Navigator.pushReplacementNamed(
                                                      context,
                                                      AppRoutes.adminDashboard,
                                                    );
                                                  } else {
                                                    Navigator.pushReplacementNamed(
                                                      context,
                                                      AppRoutes.userDashboard,
                                                    );
                                                  }
                                                }
                                              }
                                            } else {
                                              if (context.mounted) {
                                                CustomNotification.showError(
                                                  context,
                                                  "Proses Google dibatalkan",
                                                );
                                              }
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              CustomNotification.showError(
                                                context,
                                                AuthService.getErrorMessage(e),
                                              );
                                            }
                                          } finally {
                                            if (mounted)
                                              setState(
                                                () => _isLoading = false,
                                              );
                                          }
                                        },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CustomPaint(
                                            painter: GoogleLogoPainter(),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          "Masuk dengan Google",
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // 🔥 REGISTER
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "Belum punya akun?",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () {
                                              Navigator.push(
                                                context,
                                                PageRouteBuilder(
                                                  pageBuilder: (_, __, ___) =>
                                                      const RegisterPage(),
                                                  transitionsBuilder:
                                                      (
                                                        _,
                                                        animation,
                                                        __,
                                                        child,
                                                      ) {
                                                        return FadeTransition(
                                                          opacity: animation,
                                                          child: SlideTransition(
                                                            position:
                                                                Tween<Offset>(
                                                                  begin:
                                                                      const Offset(
                                                                        0.3,
                                                                        0,
                                                                      ),
                                                                  end: Offset
                                                                      .zero,
                                                                ).animate(
                                                                  animation,
                                                                ),
                                                            child: child,
                                                          ),
                                                        );
                                                      },
                                                ),
                                              );
                                            },
                                      child: const Text(
                                        "Daftar",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildLeftContent({bool isMobile = false}) {
    return Column(
      crossAxisAlignment: isMobile
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!isMobile) ...[
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                'lib/assets/images/logo.png',
                width: 55,
                height: 55,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
        Text(
          "Selamat Datang!",
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: isMobile ? 24 : 42,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isMobile ? 8 : 15),
        Text(
          "Kelola paket kamu dengan mudah.",
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(color: Colors.white70, fontSize: isMobile ? 12 : 14),
        ),
        if (!isMobile) ...[
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF427AB5), Color(0xFFBDEBFF)],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              "SATUPAKET",
              style: TextStyle(color: Colors.white, letterSpacing: 2),
            ),
          ),
        ] else
          const SizedBox(height: 20),
      ],
    );
  }

  // 🔥 INPUT FIELD dengan inline error
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
    String? errorText,
    ValueChanged<String>? onChanged,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: isPassword && !_isPasswordVisible,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white70),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible,
                    ),
                  )
                : null,
            filled: true,
            fillColor: errorText != null
                ? Colors.red.withOpacity(0.15)
                : Colors.white.withOpacity(0.25),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: errorText != null
                  ? const BorderSide(color: Colors.redAccent, width: 1.5)
                  : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: errorText != null
                  ? const BorderSide(color: Colors.redAccent, width: 1.5)
                  : const BorderSide(color: Colors.white54, width: 1),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 13,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    errorText,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
