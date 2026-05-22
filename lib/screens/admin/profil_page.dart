import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/warehouse_service.dart';
import '../../services/reset_service.dart';
import '../../widgets/custom_notification.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final WarehouseService _warehouseService = WarehouseService();
  final User? user = AuthService().currentUser;

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.redAccent),
              SizedBox(width: 12),
              Text("Keluar", style: TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          content: const Text("Apakah yakin ingin keluar?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                AuthService().signOut();
                Navigator.pushReplacementNamed(context, '/');
              },
              child: const Text("Ya, Keluar", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width > 500 ? 450 : MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Ubah Kata Sandi", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Kata Sandi Baru",
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF427AB5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      if (controller.text.isNotEmpty) {
                        try {
                          await user?.updatePassword(controller.text);
                          Navigator.pop(context);
                          CustomNotification.showSuccess(context, "Kata sandi berhasil diubah!");
                        } catch (e) {
                          CustomNotification.showError(context, "Gagal ubah sandi: $e");
                        }
                      }
                    },
                    child: const Text("Simpan"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 12),
              Text("Bersihkan Data", style: TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          content: const Text("Tindakan ini akan menghapus SEMUA data transaksi, barang, dan chat. User (kecuali Admin) juga akan dihapus untuk memulai dari awal. Lanjutkan?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ResetService.clearAllData();
                  if (!mounted) return;
                  CustomNotification.showSuccess(context, "Database berhasil dibersihkan! Mulai dari awal.");
                } catch (e) {
                  CustomNotification.showError(context, "Gagal reset: $e");
                }
              },
              child: const Text("Ya, Bersihkan", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 15 : 30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(isMobile ? 20 : 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Profil Administrator",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 40),

            // 🔥 BAGIAN TENGAH (AVATAR + NAMA)
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: isMobile ? 40 : 50,
                    backgroundColor: const Color(0xFF427AB5),
                    backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                    child: user?.photoURL == null 
                      ? Icon(Icons.admin_panel_settings_rounded, size: isMobile ? 40 : 50, color: Colors.white)
                      : null,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    user?.displayName ?? "Administrator",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    user?.email ?? "-",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),


            const Text("ALAMAT TOKO", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
            StreamBuilder<QuerySnapshot>(
              stream: _warehouseService.getWarehouseStream(),
              builder: (context, snapshot) {
                String address = "Memuat alamat...";
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  var data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                  address = "${data['namaGudang']} - ${data['detail']}, ${data['kota']}";
                } else if (snapshot.hasData) {
                  address = "Alamat toko belum diatur";
                }
                return _item(Icons.storefront_rounded, "Lokasi Utama", address);
              }
            ),


            const SizedBox(height: 40),
            
            // 🔥 KELUAR
            Center(
              child: SizedBox(
                width: 200,
                child: InkWell(
                  onTap: () => _showLogoutDialog(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade100, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.logout_rounded, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text(
                          "Keluar Sesi",
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }

  Widget _item(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF427AB5).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: const Color(0xFF427AB5), size: 22),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
