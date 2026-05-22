import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_notification.dart';
import '../user/terms_page.dart';
import '../../widgets/google_logo.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreedToTerms = false;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Inline error messages
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;

  bool _validate() {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+');
    String? nameErr;
    String? emailErr;
    String? phoneErr;
    String? passErr;
    String? confirmErr;

    if (_nameController.text.trim().isEmpty) {
      nameErr = "Nama tidak boleh kosong";
    }

    if (_usernameController.text.trim().isEmpty) {
      emailErr = "Email tidak boleh kosong";
    } else if (!emailRegex.hasMatch(_usernameController.text.trim())) {
      emailErr = "Format email tidak valid";
    }

    if (_phoneController.text.trim().isEmpty) {
      phoneErr = "Nomor telepon tidak boleh kosong";
    }

    if (_passwordController.text.isEmpty) {
      passErr = "Kata sandi tidak boleh kosong";
    } else if (_passwordController.text.length < 6) {
      passErr = "Kata sandi minimal 6 karakter";
    }

    if (_confirmPasswordController.text.isEmpty) {
      confirmErr = "Konfirmasi sandi tidak boleh kosong";
    } else if (_passwordController.text != _confirmPasswordController.text) {
      confirmErr = "Konfirmasi kata sandi tidak cocok";
    }

    setState(() {
      _nameError = nameErr;
      _emailError = emailErr;
      _phoneError = phoneErr;
      _passwordError = passErr;
      _confirmPasswordError = confirmErr;
    });

    return nameErr == null && emailErr == null && phoneErr == null && passErr == null && confirmErr == null;
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
              child: Image.asset("lib/assets/images/logistics.png", width: isDesktop ? 400 : 250),
            ),
          ),

          // 🔥 CONTENT
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: isDesktop ? 20 : 5),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: isDesktop ? 950 : 380,
                    padding: EdgeInsets.all(isDesktop ? 30 : 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                          width: isDesktop ? 380 : double.infinity,
                          padding: EdgeInsets.all(isDesktop ? 30 : 6),
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
                              if (isDesktop) ...[
                                const Text(
                                  "Daftar",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 25),
                              ],

                              // Nama Lengkap
                              _buildInputField(
                                controller: _nameController,
                                hint: "Nama Lengkap",
                                icon: Icons.person_outline,
                                errorText: _nameError,
                                onChanged: (_) => setState(() => _nameError = null),
                              ),
                              const SizedBox(height: 2),

                              // Email
                              _buildInputField(
                                controller: _usernameController,
                                hint: "Email",
                                icon: Icons.email_outlined,
                                errorText: _emailError,
                                onChanged: (_) => setState(() => _emailError = null),
                              ),
                              const SizedBox(height: 2),

                              // Nomor HP
                              _buildInputField(
                                controller: _phoneController,
                                hint: "Nomor HP",
                                icon: Icons.phone_android_outlined,
                                keyboardType: TextInputType.phone,
                                errorText: _phoneError,
                                onChanged: (_) => setState(() => _phoneError = null),
                              ),
                              const SizedBox(height: 2),

                              // Kata Sandi
                              _buildInputField(
                                controller: _passwordController,
                                hint: "Kata Sandi",
                                icon: Icons.lock_outline,
                                isPassword: true,
                                isVisible: _isPasswordVisible,
                                onVisibilityToggle: () {
                                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                                },
                                errorText: _passwordError,
                                onChanged: (_) => setState(() => _passwordError = null),
                              ),
                              const SizedBox(height: 2),

                              // Konfirmasi Sandi
                              _buildInputField(
                                controller: _confirmPasswordController,
                                hint: "Konfirmasi Sandi",
                                icon: Icons.verified_user_outlined,
                                isPassword: true,
                                isVisible: _isConfirmPasswordVisible,
                                onVisibilityToggle: () {
                                  setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                                },
                                errorText: _confirmPasswordError,
                                onChanged: (_) => setState(() => _confirmPasswordError = null),
                              ),
                              const SizedBox(height: 2),
                              
                              // Syarat & Ketentuan
                              Row(
                                children: [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: Checkbox(
                                      value: _agreedToTerms,
                                      onChanged: _isLoading ? null : (val) {
                                        setState(() {
                                          _agreedToTerms = val ?? false;
                                        });
                                      },
                                      activeColor: Colors.blueAccent,
                                      checkColor: Colors.white,
                                      side: const BorderSide(color: Colors.white70),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _showTermsModal(context),
                                      child: RichText(
                                        text: const TextSpan(
                                          style: TextStyle(color: Colors.white70, fontSize: 11),
                                          children: [
                                            TextSpan(text: "Setuju dengan "),
                                            TextSpan(
                                              text: "Syarat & Ketentuan",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              // 🔥 BUTTON DAFTAR
                              InkWell(
                                onTap: (_agreedToTerms && !_isLoading) ? () async {
                                  if (!_validate()) return;

                                  setState(() => _isLoading = true);
                                  try {
                                    final user = await AuthService().signUpWithEmail(
                                      _usernameController.text.trim(),
                                      _passwordController.text,
                                      _nameController.text.trim(),
                                      _phoneController.text.trim(),
                                    );

                                    if (user != null) {
                                      if (context.mounted) {
                                        _nameController.clear();
                                        _usernameController.clear();
                                        _phoneController.clear();
                                        _passwordController.clear();
                                        _confirmPasswordController.clear();
                                        CustomNotification.showSuccess(context, "Registrasi Berhasil! Silakan periksa kotak masuk/spam email Anda untuk verifikasi.");
                                        Navigator.pop(context);
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      // Tampilkan error Firebase sebagai inline error di email
                                      setState(() => _emailError = AuthService.getErrorMessage(e));
                                    }
                                  } finally {
                                    if (mounted) setState(() => _isLoading = false);
                                  }
                                } : null,
                                borderRadius: BorderRadius.circular(30),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: (_agreedToTerms && !_isLoading) 
                                          ? const [Color(0xFF427AB5), Color(0xFFBDEBFF)]
                                          : [Colors.grey.withOpacity(0.5), Colors.grey.withOpacity(0.5)],
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: (_agreedToTerms && !_isLoading) ? [
                                      BoxShadow(
                                        color: const Color(0xFF427AB5).withOpacity(0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ] : [],
                                  ),
                                  alignment: Alignment.center,
                                  child: _isLoading 
                                    ? const SizedBox(
                                        height: 20, 
                                        width: 20, 
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                      )
                                    : Text(
                                        "Daftar",
                                        style: TextStyle(
                                          color: (_agreedToTerms && !_isLoading) ? Colors.blue.shade900 : Colors.white70,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                ),
                              ),
                               const SizedBox(height: 12),

                              // 🔥 GOOGLE SIGN IN
                              InkWell(
                                onTap: _isLoading ? null : () async {
                                  setState(() => _isLoading = true);
                                  try {
                                    final userCredential = await AuthService().signInWithGoogle();
                                    if (userCredential != null) {
                                      final googleUser = userCredential.user;
                                      if (googleUser != null && context.mounted) {
                                        String? role = await AuthService().getUserRole(googleUser.uid);
                                        if (context.mounted) {
                                          if (role == "admin") {
                                            Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
                                          } else {
                                            CustomNotification.showSuccess(context, "Berhasil masuk!");
                                            Navigator.pushReplacementNamed(context, AppRoutes.userDashboard);
                                          }
                                        }
                                      }
                                    } else {
                                      if (context.mounted) {
                                        CustomNotification.showError(context, "Proses Google dibatalkan");
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                       CustomNotification.showError(context, AuthService.getErrorMessage(e));
                                    }
                                  } finally {
                                    if (mounted) setState(() => _isLoading = false);
                                  }
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
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
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                        "Daftar dengan Google",
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

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Sudah punya akun?",
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                  TextButton(
                                    onPressed: _isLoading ? null : () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text(
                                      "Masuk",
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
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
          const Text(
            "Buat Akun Baru",
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            "Daftar dan nikmati kemudahan kirim paket.",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
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
              style: TextStyle(
                color: Colors.white,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ] else ...[
          const Text(
            "DAFTAR",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
        ]
      ],
    );
  }

  void _showTermsModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: Container(
          width: MediaQuery.of(context).size.width > 800 ? 600 : MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          clipBehavior: Clip.antiAlias,
          child: const TermsPage(),
        ),
      ),
    );
  }

  // 🔥 INPUT FIELD dengan inline error
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onVisibilityToggle,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: isPassword && !isVisible,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white70, fontSize: 13),
            prefixIcon: Icon(icon, color: errorText != null ? Colors.redAccent : Colors.white70, size: 18),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white70,
                      size: 18,
                    ),
                    onPressed: onVisibilityToggle,
                  )
                : null,
            filled: true,
            fillColor: errorText != null
                ? Colors.red.withOpacity(0.12)
                : Colors.white.withOpacity(0.15),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 5,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: errorText != null
                  ? const BorderSide(color: Colors.redAccent, width: 1.5)
                  : BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: errorText != null
                  ? const BorderSide(color: Colors.redAccent, width: 1.5)
                  : const BorderSide(color: Colors.white, width: 1.5),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 12),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    errorText,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
