import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/package_service.dart';
import '../../services/layanan_service.dart';
import '../../widgets/custom_notification.dart';

class DetailPaketPage extends StatefulWidget {
  final Map<String, dynamic> paket;

  const DetailPaketPage({super.key, required this.paket});

  @override
  State<DetailPaketPage> createState() => _DetailPaketPageState();
}

class _DetailPaketPageState extends State<DetailPaketPage> {
  List<String> selectedNotes = [];
  bool _isSubmitting = false;

  // Opsi catatan + biaya tambahan dinamis
  List<Map<String, dynamic>> _noteOptions = [];
  bool _isLoadingOptions = true;

  @override
  void initState() {
    super.initState();
    _fetchNoteOptions();
  }

  Future<void> _fetchNoteOptions() async {
    try {
      final snapshot = await LayananService().getLayananStream().first;
      if (mounted) {
        setState(() {
          final dataDoc = snapshot.data() as Map<String, dynamic>?;
          final List<dynamic> items = dataDoc?['items'] ?? [];
          
          _noteOptions = items.map((data) {
            return {
              "label": data['label'] ?? "Layanan",
              "biaya": data['biaya'] ?? 0,
            };
          }).toList();
          _isLoadingOptions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingOptions = false);
      }
    }
  }

  int get _selectedBiaya {
    int total = 0;
    for (var opt in _noteOptions) {
      if (selectedNotes.contains(opt["label"])) {
        total += opt["biaya"] as int;
      }
    }
    return total;
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "-";
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is String) {
      dt = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      dt = DateTime.now();
    }
    List<String> months = ["Januari", "Februari", "Maret", "April", "Mei", "Juni", "Juli", "Agustus", "September", "Oktober", "November", "Desember"];
    return "${dt.day} ${months[dt.month - 1]} ${dt.year}";
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final String docId = widget.paket["id"] ?? "";

    if (uid == null || docId.isEmpty) {
      return _buildContent(widget.paket);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('user').doc(uid).collection('packages').doc(docId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildContent(widget.paket);
        }
        var data = snapshot.data!.data() as Map<String, dynamic>;
        data["id"] = docId;
        return _buildContent(data);
      },
    );
  }

  void _showRejectDialog(BuildContext context, Map<String, dynamic> paketData) {
    TextEditingController reasonController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Alasan Penolakan", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Silakan beritahu admin mengapa paket ini ditolak (misal: bukan pesanan saya, resi salah, dll).", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    onChanged: (val) => setStateDialog((){}),
                    decoration: InputDecoration(
                      hintText: "Tulis alasan Anda...",
                      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF427AB5))),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text("Batal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: (isSubmitting || reasonController.text.trim().isEmpty) ? null : () async {
                    setStateDialog(() => isSubmitting = true);
                    try {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid != null) {
                        await PackageService().updateUserApprovalStatus(
                          uid, 
                          paketData["id"] ?? "", 
                          paketData["resi"] ?? "", 
                          "rejected",
                          reason: reasonController.text.trim()
                        );
                        if (context.mounted) {
                          CustomNotification.showSuccess(context, "Paket berhasil ditolak.");
                          Navigator.pop(context);
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        CustomNotification.showError(context, "Error: $e");
                        setStateDialog(() => isSubmitting = false);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: isSubmitting 
                    ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Kirim Penolakan", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Widget _buildContent(Map<String, dynamic> paketData) {
    String userApprovalStatus = paketData["userApprovalStatus"] ?? "pending";
    bool isApproved = userApprovalStatus == "approved";
    bool isRejected = userApprovalStatus == "rejected";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Detail Paket", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18)
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 TOP IMAGE & MAIN INFO
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.grey.shade50, Colors.grey.shade100],
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: (paketData["images"] != null && (paketData["images"] as List).isNotEmpty)
                              ? (paketData["images"][0].toString().startsWith('http')
                                  ? Image.network(paketData["images"][0], fit: BoxFit.cover)
                                  : Image.memory(base64Decode(paketData["images"][0]), fit: BoxFit.cover))
                              : const Icon(Icons.inventory_2_outlined, size: 30, color: Color(0xFF427AB5)),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF427AB5).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  paketData["resi"] ?? "NO RESI",
                                  style: const TextStyle(
                                    color: Color(0xFF427AB5),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                               const SizedBox(height: 4),
                              Text(
                                paketData["keterangan"] ?? paketData["nama"] ?? "Nama Paket",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                               const SizedBox(height: 5),
                              Text(
                                "Tiba pada: ${_formatDate(paketData["createdAt"])}",
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  // Berat Chip
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.monitor_weight_outlined, size: 12, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text(
                                          (paketData["berat"] ?? 0) < 1000 
                                              ? "${paketData["berat"]} g" 
                                              : "${((paketData["berat"] ?? 0) / 1000).toStringAsFixed(1)} kg",
                                          style: TextStyle(
                                            color: Colors.grey.shade800,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Status Chip
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.green.shade100),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle_outline_rounded, size: 12, color: Colors.green),
                                        const SizedBox(width: 4),
                                        const Text(
                                          "Di Gudang",
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 🔹 PHOTO PREVIEW (Initial Photos)
              const Text(
                "Foto Paket (Awal)",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              _buildImageGrid(paketData["images"] ?? []),

              // 🔹 PHOTO PREVIEW (Requested Photos)
              if (paketData["requestedImages"] != null && (paketData["requestedImages"] as List).isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  "Foto Hasil Permintaan",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF427AB5)),
                ),
                const SizedBox(height: 6),
                _buildImageGrid(paketData["requestedImages"]),
              ],

              const SizedBox(height: 12),

              // 🔹 APPROVAL OR NOTE SELECTION
              if (userApprovalStatus == "pending") ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Apakah ini benar paket Anda?", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              _showRejectDialog(context, paketData);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700, 
                              side: BorderSide(color: Colors.red.shade300, width: 1.2),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text("Tolak", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () async {
                              final uid = FirebaseAuth.instance.currentUser?.uid;
                              if (uid != null) {
                                await PackageService().updateUserApprovalStatus(uid, paketData["id"] ?? "", paketData["resi"] ?? "", "approved");
                                if (mounted) CustomNotification.showSuccess(context, "Paket dikonfirmasi!");
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF427AB5), 
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 0,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text("Terima", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else if (isRejected) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cancel_rounded, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(child: Text("Anda telah menolak paket ini. Menunggu admin untuk memperbarui data.", style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                ),
              ] else if (isApproved) ...[
                const Text(
                  "Permintaan Foto Tambahan",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  "Biaya tambahan ditagih saat checkout.",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: _isLoadingOptions 
                      ? const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
                      : _noteOptions.isEmpty 
                          ? const Padding(padding: EdgeInsets.all(20), child: Text("Belum ada layanan tersedia.", style: TextStyle(color: Colors.grey)))
                          : Column(
                              children: _noteOptions.asMap().entries.map((entry) {
                                int idx = entry.key;
                                var opt = entry.value;
                                return Column(
                                  children: [
                                    _buildRadioItem(opt),
                                    if (idx < _noteOptions.length - 1)
                                      const Divider(height: 1, indent: 20, endIndent: 20),
                                  ],
                                );
                              }).toList(),
                            ),
                ),
  
                // TOMBOL SUBMIT
                if (selectedNotes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF427AB5).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF427AB5).withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFF427AB5), size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Biaya tambahan foto: Rp${_selectedBiaya.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} akan ditambahkan saat checkout.",
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),

                // 🔥 SUBMIT BUTTON
                 Align(
                   alignment: Alignment.centerRight,
                   child: ElevatedButton(
                     style: ElevatedButton.styleFrom(
                       backgroundColor: const Color(0xFF1A1A1A),
                       foregroundColor: Colors.white,
                       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 25),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                       elevation: 0,
                     ),
                     onPressed: selectedNotes.isEmpty || _isSubmitting || paketData["catatanUser"] != null
                         ? null
                         : () async {
                             setState(() => _isSubmitting = true);
                             try {
                               final uid = FirebaseAuth.instance.currentUser?.uid;
                               if (uid != null) {
                                 String combinedNotes = selectedNotes.join(" & ");
                                 await PackageService().sendPackageNote(
                                   uid,
                                   paketData["id"] ?? "",
                                   paketData["resi"] ?? "",
                                   combinedNotes,
                                 );
                                 // Simpan biaya tambahan foto ke paket
                                 await FirebaseFirestore.instance
                                     .collection('user')
                                     .doc(uid)
                                     .collection('packages')
                                     .doc(paketData["id"])
                                     .update({"biayaTambahanFoto": _selectedBiaya, "labelFoto": combinedNotes});
                                 if (mounted) {
                                   CustomNotification.showSuccess(context, "Permintaan terkirim!");
                                 }
                               }
                             } catch (e) {
                               if (mounted) {
                                 CustomNotification.showError(context, "Error: $e");
                               }
                             } finally {
                               if (mounted) setState(() => _isSubmitting = false);
                             }
                           },
                     child: _isSubmitting
                         ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                         : Text(
                             paketData["catatanUser"] != null ? "Diproses Admin" : "Kirim Permintaan",
                             style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                           ),
                   ),
                 ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
      ],
    );
  }

  Widget _buildRadioItem(Map<String, dynamic> option) {
    final String text = option["label"] as String;
    final int biaya = option["biaya"] as int;
    bool isSelected = selectedNotes.contains(text);
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedNotes.remove(text);
          } else {
            selectedNotes.add(text);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.grey.shade600,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "+ Rp${biaya.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}",
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF427AB5) : Colors.grey.shade400,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? const Color(0xFF427AB5) : Colors.grey.shade300,
                  width: isSelected ? 0 : 2,
                ),
                color: isSelected ? const Color(0xFF427AB5) : Colors.transparent,
              ),
              child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
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
                  "Terkirim!",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  "Catatan Anda telah terkirim ke admin.",
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

  Widget _buildImageGrid(List<dynamic> images) {
    if (images.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Icon(Icons.image_not_supported_outlined, color: Colors.grey.shade400, size: 24),
            const SizedBox(width: 10),
            Text("Belum ada foto", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: images.map((img) {
          return GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  child: InteractiveViewer(
                    child: Image.memory(base64Decode(img), fit: BoxFit.contain),
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 15),
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
                image: DecorationImage(
                  image: MemoryImage(base64Decode(img)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
