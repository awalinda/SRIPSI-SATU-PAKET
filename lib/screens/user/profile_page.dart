import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import 'terms_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = AuthService().currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Center(child: Text("Pengguna tidak ditemukan", style: TextStyle(color: Colors.white)));

    return StreamBuilder<DocumentSnapshot>(
      stream: AuthService().getUserData(user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final userIdCode = userData?['userIdCode'] ?? "SP-XXXXX";
        final phoneNumber = userData?['phoneNumber'] ?? "Tambah Nomor HP";

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 🔥 HEADER / AVATAR
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF427AB5), Color(0xFFBDEBFF)],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      backgroundImage: (userData?['profileUrl'] != null && userData!['profileUrl'].toString().isNotEmpty)
                          ? NetworkImage(userData['profileUrl'])
                          : null,
                      child: (userData?['profileUrl'] == null || userData!['profileUrl'].toString().isEmpty)
                          ? const Icon(Icons.person, size: 60, color: Color(0xFF427AB5))
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  user?.displayName ?? "Pengguna",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3C72),
                  ),
                ),
                Text(
                  user?.email ?? "email@belum_diatur.com",
                  style: const TextStyle(color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 12),
                // 🆔 USER ID BADGE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF427AB5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFF427AB5).withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_user_rounded, color: Color(0xFF427AB5), size: 14),
                      const SizedBox(width: 8),
                      Text(
                        "ID: $userIdCode",
                        style: const TextStyle(color: Color(0xFF427AB5), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // 🔥 PROFILE SECTIONS
                _buildSection(
                  title: "Informasi Akun",
                  items: [
                    _profileItem(
                      Icons.badge_outlined, 
                      "ID Pengguna", 
                      userIdCode,
                      isAction: true,
                      actionIcon: Icons.copy_rounded,
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: userIdCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: const [
                                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 10),
                                Text("ID Pengguna berhasil disalin!"),
                              ],
                            ),
                            backgroundColor: const Color(0xFF427AB5),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                    ),
                    _profileItem(
                      Icons.person_outline, 
                      "Nama Lengkap", 
                      user?.displayName ?? "Belum diatur",
                      isAction: true,
                      onTap: () => _showEditNameDialog(user?.displayName ?? ""),
                    ),
                    _profileItem(
                      Icons.email_outlined, 
                      "Email", 
                      user?.email ?? "Belum diatur",
                      isAction: true,
                      onTap: () => _showEditEmailDialog(user?.email ?? ""),
                    ),
                    _profileItem(
                      Icons.phone_outlined, 
                      "Nomor HP", 
                      phoneNumber,
                      isAction: true,
                      onTap: () => _showEditPhoneDialog(userData?['phoneNumber'] ?? ""),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSection(
                  title: "Keamanan",
                  items: [
                    _profileItem(
                      Icons.lock_outline, 
                      "Ganti Password", 
                      "", 
                      isAction: true,
                      onTap: _showChangePasswordDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSection(
                  title: "Lainnya",
                  items: [
                    _profileItem(Icons.description_outlined, "Syarat & Ketentuan", "", isAction: true, onTap: () => _showTermsModal(context)),
                    _profileItem(Icons.logout, "Keluar", "", isAction: true, color: Colors.redAccent, onTap: () => _showLogoutDialog()),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      }
    );
  }

  void _showTermsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: const TermsPage(),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent),
            SizedBox(width: 12),
            Text("Keluar", style: TextStyle(color: Color(0xFF1E3C72), fontWeight: FontWeight.w900)),
          ],
        ),
        content: const Text(
          "Apakah Anda yakin ingin keluar dari akun ini?",
          style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              AuthService().signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Ya, Keluar", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1E3C72),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF1E3C72).withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3C72).withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  void _showEditNameDialog(String currentName) {
    final TextEditingController nameEditController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Nama Lengkap", style: TextStyle(color: Color(0xFF1E3C72), fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameEditController,
          style: const TextStyle(color: Color(0xFF1E3C72)),
          decoration: InputDecoration(
            hintText: "Masukkan nama lengkap",
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: const Color(0xFF1E3C72).withOpacity(0.3))),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF427AB5))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameEditController.text.isNotEmpty && user != null) {
                await AuthService().updateDisplayName(nameEditController.text.trim());
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF427AB5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Simpan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditEmailDialog(String currentEmail) {
    final TextEditingController emailEditController = TextEditingController(text: currentEmail);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Email", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: emailEditController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Masukkan email baru",
            hintStyle: const TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF427AB5))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailEditController.text.isNotEmpty && user != null) {
                try {
                  await AuthService().updateEmail(emailEditController.text.trim());
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Link verifikasi telah dikirim ke email baru.")),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    String error = "Gagal memperbarui email";
                    if (e.toString().contains("requires-recent-login")) {
                      error = "Keamanan: Silakan keluar dan masuk kembali sebelum ganti email.";
                    }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF427AB5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Simpan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditPhoneDialog(String currentPhone) {
    final TextEditingController phoneEditController = TextEditingController(text: currentPhone);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Nomor HP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: phoneEditController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Masukkan nomor baru",
            hintStyle: const TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF427AB5))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (phoneEditController.text.isNotEmpty && user != null) {
                await AuthService().updateUserData(user!.uid, {
                  "phoneNumber": phoneEditController.text.trim(),
                });
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF427AB5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Simpan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController newPassController = TextEditingController();
    final TextEditingController confirmPassController = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Ganti Password", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPassController,
                obscureText: obscureNew,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Password Baru",
                  labelStyle: const TextStyle(color: Colors.white54),
                  suffixIcon: IconButton(
                    icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                    onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                  ),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF427AB5))),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmPassController,
                obscureText: obscureConfirm,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Konfirmasi Password",
                  labelStyle: const TextStyle(color: Colors.white54),
                  suffixIcon: IconButton(
                    icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                    onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                  ),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF427AB5))),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newPassController.text.isEmpty || confirmPassController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Isi semua bidang")));
                  return;
                }
                if (newPassController.text != confirmPassController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password tidak cocok")));
                  return;
                }

                try {
                  await AuthService().updatePassword(newPassController.text);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password berhasil diperbarui")));
                  }
                } catch (e) {
                  if (context.mounted) {
                    String error = "Gagal memperbarui password";
                    if (e.toString().contains("requires-recent-login")) {
                      error = "Keamanan: Silakan keluar dan masuk kembali sebelum ganti password.";
                    }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF427AB5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Ganti", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileItem(IconData icon, String title, String value, {
    bool isAction = false, 
    Color color = const Color(0xFF2D3436),
    VoidCallback? onTap,
    IconData? actionIcon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: color.withOpacity(0.7), fontSize: 13),
                  ),
                  if (value.isNotEmpty)
                    Text(
                      value,
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                ],
              ),
            ),
            if (isAction)
              Icon(actionIcon ?? Icons.arrow_forward_ios, color: color.withOpacity(0.5), size: 16),
          ],
        ),
      ),
    );
  }
}

