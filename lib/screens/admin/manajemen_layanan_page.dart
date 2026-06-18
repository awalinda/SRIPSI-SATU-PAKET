import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/layanan_service.dart';
import '../../widgets/custom_notification.dart';

class ManajemenLayananPage extends StatefulWidget {
  const ManajemenLayananPage({super.key});

  @override
  State<ManajemenLayananPage> createState() => _ManajemenLayananPageState();
}

class _ManajemenLayananPageState extends State<ManajemenLayananPage> {
  final LayananService _layananService = LayananService();

  @override
  void initState() {
    super.initState();
    // Pastikan layanan default ditambahkan jika koleksi kosong
    _layananService.seedLayananAwal();
  }

  void _showSuccessPopup(String message) {
    showDialog(
      context: context,
      builder: (context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) Navigator.pop(context);
        });

        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
                const SizedBox(height: 20),
                const Text(
                  "Berhasil!",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFormDialog({String? docId, Map<String, dynamic>? currentData}) {
    final labelCtrl = TextEditingController(text: currentData?['label'] ?? "");
    final biayaCtrl = TextEditingController(text: currentData?['biaya']?.toString() ?? "");
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                docId == null ? "Tambah Layanan Baru" : "Edit Layanan",
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  const Text("Nama Layanan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: labelCtrl,
                    decoration: InputDecoration(
                      hintText: "Contoh: Minta foto detail",
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF427AB5))),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text("Biaya (Rp)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: biayaCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: "Contoh: 2000",
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF427AB5))),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text("Batal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF427AB5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (labelCtrl.text.trim().isEmpty || biayaCtrl.text.trim().isEmpty) {
                            CustomNotification.showError(context, "Semua field harus diisi!");
                            return;
                          }

                          setStateDialog(() => isSubmitting = true);
                          try {
                            int biaya = int.tryParse(biayaCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                            Map<String, dynamic> data = {
                              "label": labelCtrl.text.trim(),
                              "biaya": biaya,
                            };

                            if (docId == null) {
                              await _layananService.addLayanan(data);
                            } else {
                              await _layananService.updateLayanan(docId, data);
                            }
                            
                            if (mounted) {
                              Navigator.pop(context); // Tutup form dialog dulu
                              _showSuccessPopup(docId == null ? "Layanan berhasil ditambahkan!" : "Layanan berhasil diperbarui!");
                            }
                          } catch (e) {
                            if (mounted) CustomNotification.showError(context, "Gagal menyimpan: $e");
                            setStateDialog(() => isSubmitting = false);
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(height: 15, width: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Simpan", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(String docId, String label) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Hapus Layanan?", style: TextStyle(fontWeight: FontWeight.w900)),
          content: Text("Anda yakin ingin menghapus layanan '$label'? Pengguna tidak akan bisa lagi memilih layanan ini."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(context); // Tutup dialog
                try {
                  await _layananService.deleteLayanan(docId);
                  if (mounted) _showSuccessPopup("Layanan berhasil dihapus!");
                } catch (e) {
                  if (mounted) CustomNotification.showError(context, "Gagal menghapus: $e");
                }
              },
              child: const Text("Hapus", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Manajemen Layanan",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E3C72),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Atur layanan tambahan yang bisa dipilih oleh User",
                    style: TextStyle(color: Colors.blueGrey, fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showFormDialog(),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text("Tambah Layanan", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF427AB5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: StreamBuilder<DocumentSnapshot>(
              stream: _layananService.getLayananStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                final dataDoc = snapshot.data?.data() as Map<String, dynamic>?;
                final List<dynamic> docs = dataDoc?['items'] ?? [];
                
                if (docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(30),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.room_service_outlined, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 15),
                        Text("Belum ada layanan yang ditambahkan.", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final data = docs[index] as Map<String, dynamic>;
                    final docId = data['id'];
                    final String label = data['label'] ?? "Tanpa Nama";
                    final int biaya = data['biaya'] ?? 0;
                    
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(
                        "+ Rp ${biaya.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}",
                        style: const TextStyle(color: Color(0xFF427AB5), fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_note_rounded, color: Colors.orange),
                            tooltip: "Edit",
                            onPressed: () => _showFormDialog(docId: docId, currentData: data),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                            tooltip: "Hapus",
                            onPressed: () => _confirmDelete(docId, label),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
