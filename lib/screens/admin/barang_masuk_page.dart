import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/package_service.dart';
import '../../services/report_service.dart';
import '../../services/order_service.dart';
import '../../widgets/custom_notification.dart';
import '../../services/notification_service.dart';

class BarangMasukPage extends StatefulWidget {
  const BarangMasukPage({super.key});

  @override
  State<BarangMasukPage> createState() => _BarangMasukPageState();
}

class _BarangMasukPageState extends State<BarangMasukPage> {
  final PackageService _packageService = PackageService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  final ReportService _reportService = ReportService();
  String selectedFilter = "All"; // Untuk filter tabel UI
  String selectedDateFilter = "Semua Waktu"; // Untuk filter tanggal
  final FocusNode _searchFocusNode = FocusNode();

  bool get isMobile => MediaQuery.of(context).size.width < 800;

  // 🔥 DIALOG PILIH LAPORAN
  void _handleCetakLaporan() {
    String selFilter = "Mingguan";
    String selFormat = "PDF";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Cetak Laporan Barang Masuk", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Pilih Rentang Waktu:", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              _filterOptionReport(setDialogState, "Mingguan", selFilter, (val) => selFilter = val),
              _filterOptionReport(setDialogState, "Bulanan", selFilter, (val) => selFilter = val),
              _filterOptionReport(setDialogState, "Semua", selFilter, (val) => selFilter = val),
              
              const SizedBox(height: 20),
              const Text("Pilih Format File:", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _formatOptionReport(setDialogState, "PDF", Icons.picture_as_pdf, Colors.red, selFormat, (val) => selFormat = val),
                  const SizedBox(width: 10),
                  _formatOptionReport(setDialogState, "Excel", Icons.table_chart, Colors.green, selFormat, (val) => selFormat = val),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF427AB5), foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _reportService.generateReport(
                    type: "Barang Masuk",
                    filter: selFilter,
                    format: selFormat,
                  );
                } catch (e) {
                  if (mounted) {
                    CustomNotification.showError(context, "Gagal cetak: $e");
                  }
                }
              },
              child: const Text("Cetak Sekarang"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterOptionReport(Function setS, String val, String current, Function(String) onSelect) {
    bool active = val == current;
    return RadioListTile(
      value: val,
      groupValue: current,
      title: Text(val, style: const TextStyle(fontSize: 14)),
      onChanged: (v) => setS(() => onSelect(v.toString())),
      contentPadding: EdgeInsets.zero,
      dense: true,
      activeColor: const Color(0xFF427AB5),
    );
  }

  Widget _formatOptionReport(Function setS, String val, IconData icon, Color color, String current, Function(String) onSelect) {
    bool active = val == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => setS(() => onSelect(val)),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? color : Colors.grey.shade200, width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 5),
              Text(val, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  // ================= POPUP INPUT =================
  void showFormMasuk({Map<String, dynamic>? editItem}) {
    String? selectedUserUid = editItem?["userId"];
    String? selectedUserName = editItem?["nama"];
    String? selectedUserIdCode = editItem?["userIdCode"];
    TextEditingController? userFieldCtrl;

    final resi = TextEditingController(text: editItem?["resi"] ?? "");
    final berat = TextEditingController(text: editItem?["berat"]?.toString() ?? "");
    
    // Parse dimensi if editing
    String pStr = "";
    String lStr = "";
    String tStr = "";
    if (editItem != null && editItem["dimensi"] != null) {
      List<String> dims = editItem["dimensi"].toString().split("x");
      if (dims.length == 3) {
        pStr = dims[0];
        lStr = dims[1];
        tStr = dims[2];
      }
    }
    
    final panjang = TextEditingController(text: pStr);
    final lebar = TextEditingController(text: lStr);
    final tinggi = TextEditingController(text: tStr);
    final keterangan = TextEditingController(text: editItem?["keterangan"] ?? "");

    String kategori = editItem?["kategori"] ?? "-";
    DateTime? tanggal = DateTime.now();
    List<String> base64Images = editItem != null ? List<String>.from(editItem["images"] ?? []) : [];
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          void cekKategori() {
            double p = double.tryParse(panjang.text) ?? 0;
            double l = double.tryParse(lebar.text) ?? 0;
            double t = double.tryParse(tinggi.text) ?? 0;
            double volume = p * l * t;

            if (volume <= 0) {
              kategori = "-";
            } else if (volume <= 1000) {
              kategori = "Kecil";
            } else if (volume <= 8000) {
              kategori = "Sedang";
            } else {
              kategori = "Besar";
            }

            setStateDialog(() {});
          }

          Future<void> pickImage() async {
            if (base64Images.length >= 3) {
              CustomNotification.showWarning(context, "Maksimal 3 foto");
              return;
            }

            try {
              final ImagePicker picker = ImagePicker();
              final XFile? image = await picker.pickImage(
                source: ImageSource.camera,
                imageQuality: 30,
                maxWidth: 600,
                maxHeight: 600,
              );

              if (image != null) {
                final bytes = await image.readAsBytes();
                String base64 = base64Encode(bytes);
                setStateDialog(() {
                  base64Images.add(base64);
                });
              }
            } catch (e) {
              debugPrint("Error picking image: $e");
            }
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: min(550, MediaQuery.of(context).size.width * 0.95),
              padding: const EdgeInsets.all(25),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Input Barang Masuk", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                    const SizedBox(height: 25),

                    const Text("ID User (Cari SP-XXXXX) *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Autocomplete<Map<String, dynamic>>(
                      initialValue: TextEditingValue(text: editItem != null ? "${editItem['userIdCode'] ?? ''} - ${editItem['nama'] ?? ''}" : ""),
                      displayStringForOption: (option) => "${option['userIdCode'] ?? ''} - ${option['name'] ?? ''}",
                      optionsBuilder: (textEditingValue) async {
                        if (textEditingValue.text.isEmpty) return const Iterable<Map<String, dynamic>>.empty();
                        return await _packageService.searchUsers(textEditingValue.text);
                      },
                      onSelected: (selection) {
                        selectedUserUid = selection['uid'];
                        selectedUserName = selection['name'];
                        selectedUserIdCode = selection['userIdCode'];
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        userFieldCtrl = controller;
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText: "Ketik Nama atau SP-...",
                            prefixIcon: const Icon(Icons.person_search_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: resi,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              labelText: "No Resi *",
                              prefixIcon: const Icon(Icons.qr_code_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton.filled(
                          onPressed: () async {
                            final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen()));
                            if (result != null) {
                              // 🔥 LOGIKA AUTO-FILL
                              // Jika hasil scan mengandung ID User (SP-XXXXX)
                              if (result.contains("SP-") && userFieldCtrl != null) {
                                // Cari bagian SP- nya
                                RegExp reg = RegExp(r"SP-[A-Z0-9]+");
                                var match = reg.firstMatch(result);
                                if (match != null) {
                                  String idCode = match.group(0)!;
                                  userFieldCtrl!.text = idCode;
                                  
                                  // Update Resi dengan sisa teksnya (jika ada) atau tetap resi
                                  resi.text = result.replaceAll(idCode, "").trim();
                                  if (resi.text.isEmpty) resi.text = result;

                                  // Auto search user
                                  var users = await _packageService.searchUsers(idCode);
                                  if (users.isNotEmpty) {
                                    selectedUserUid = users[0]['uid'];
                                    selectedUserName = users[0]['name'];
                                    selectedUserIdCode = users[0]['userIdCode'];
                                  }
                                } else {
                                  resi.text = result;
                                }
                              } else {
                                resi.text = result;
                              }
                            }
                          },
                          style: IconButton.styleFrom(backgroundColor: const Color(0xFF427AB5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),
                    TextField(
                      controller: berat,
                      onChanged: (v) => setStateDialog(() {}),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      decoration: InputDecoration(
                        labelText: "Berat (gram) *",
                        prefixIcon: const Icon(Icons.monitor_weight_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF427AB5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: const Color(0xFF427AB5).withOpacity(0.3)),
                          ),
                          child: Text("Kategori: $kategori", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF427AB5))),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),
                    const Text("Dimensi Paket (cm) *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: panjang, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))], onChanged: (v) { cekKategori(); setStateDialog(() {}); }, decoration: const InputDecoration(labelText: "P *", border: OutlineInputBorder()))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: lebar, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))], onChanged: (v) { cekKategori(); setStateDialog(() {}); }, decoration: const InputDecoration(labelText: "L *", border: OutlineInputBorder()))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: tinggi, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))], onChanged: (v) { cekKategori(); setStateDialog(() {}); }, decoration: const InputDecoration(labelText: "T *", border: OutlineInputBorder()))),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Text("Foto Paket (Maksimal 3 Foto)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ...base64Images.asMap().entries.map((entry) {
                          int idx = entry.key;
                          String img = entry.value;
                          return Stack(
                            children: [
                              Container(margin: const EdgeInsets.only(right: 10), width: 70, height: 70, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), image: DecorationImage(image: MemoryImage(base64Decode(img)), fit: BoxFit.cover))),
                              Positioned(top: 0, right: 10, child: GestureDetector(onTap: () => setStateDialog(() => base64Images.removeAt(idx)), child: Container(decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16)))),
                            ],
                          );
                        }),
                        if (base64Images.length < 3)
                          GestureDetector(onTap: () => pickImage(), child: Container(width: 70, height: 70, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10), color: Colors.grey.shade50), child: const Icon(Icons.add_a_photo_outlined, color: Colors.grey))),
                      ],
                    ),

                    const SizedBox(height: 20),
                    TextField(controller: keterangan, maxLines: 2, decoration: InputDecoration(labelText: "Keterangan", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),

                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF427AB5), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                            onPressed: isSaving ? null : () async {
                              setStateDialog(() => isSaving = true);
                              try {
                                if (selectedUserUid == null && userFieldCtrl != null && userFieldCtrl!.text.isNotEmpty) {
                                  var res = await _packageService.searchUsers(userFieldCtrl!.text);
                                  if (res.isNotEmpty) {
                                    selectedUserUid = res[0]['uid'];
                                    selectedUserName = res[0]['name'];
                                    selectedUserIdCode = res[0]['userIdCode'];
                                  }
                                }

                                if (selectedUserUid == null || resi.text.isEmpty || berat.text.isEmpty || panjang.text.isEmpty || lebar.text.isEmpty || tinggi.text.isEmpty || kategori == "-") {
                                  List<String> missingFields = [];
                                  if (selectedUserUid == null && (userFieldCtrl == null || userFieldCtrl!.text.isEmpty)) missingFields.add("ID User");
                                  if (resi.text.isEmpty) missingFields.add("No Resi");
                                  if (berat.text.isEmpty) missingFields.add("Berat");
                                  if (panjang.text.isEmpty) missingFields.add("Panjang (P)");
                                  if (lebar.text.isEmpty) missingFields.add("Lebar (L)");
                                  if (tinggi.text.isEmpty) missingFields.add("Tinggi (T)");

                                  setStateDialog(() => isSaving = false);
                                  showDialog(
                                    context: context, 
                                    builder: (ctx) => AlertDialog(
                                      title: const Text("Validasi Gagal"), 
                                      content: Text("Harap lengkapi kolom wajib berikut:\n\n- ${missingFields.join('\n- ')}"), 
                                      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))]
                                    )
                                  );
                                  return;
                                }

                                final data = {
                                  "nama": selectedUserName,
                                  "userIdCode": selectedUserIdCode,
                                  "resi": resi.text,
                                  "berat": double.tryParse(berat.text) ?? 0,
                                  "dimensi": "${panjang.text}x${lebar.text}x${tinggi.text}",
                                  "kategori": kategori,
                                  "tanggal": tanggal?.toString().split(" ")[0],
                                  "keterangan": keterangan.text,
                                  "images": base64Images,
                                  "userId": selectedUserUid,
                                  "biaya": OrderService.hitungBiayaJNE(
                                    beratGram: double.tryParse(berat.text) ?? 0,
                                    p: double.tryParse(panjang.text) ?? 0,
                                    l: double.tryParse(lebar.text) ?? 0,
                                    t: double.tryParse(tinggi.text) ?? 0,
                                  ),
                                };

                                  if (editItem != null) {
                                    // Set approval status to pending so user can approve, but KEEP rejectionReason
                                    data["userApprovalStatus"] = "pending";
                                  data["isUpdatedByAdmin"] = true;
                                  await _packageService.updateIncomingPackage(editItem["id"], selectedUserUid, resi.text, data);
                                  
                                  // Notify user that package was updated
                                  if (selectedUserUid != null) {
                                    await NotificationService.notifyPackageUpdated(selectedUserUid!, resi.text, selectedUserName ?? "Barang");
                                  }
                                } else {
                                  data["createdAt"] = FieldValue.serverTimestamp();
                                  await _packageService.addIncomingPackage(selectedUserUid!, data);
                                  await _packageService.saveToAdminList(data);
                                }
                                  
                                  if (mounted) {
                                    Navigator.pop(context); // Close the form dialog
                                    CustomNotification.showSuccess(context, editItem != null ? "Barang berhasil diperbarui!" : "Barang berhasil disimpan!");
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    CustomNotification.showError(context, "Error: $e");
                                    setStateDialog(() => isSaving = false);
                                  }
                                }
                              },
                              child: isSaving 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(editItem != null ? "Update Data" : "Simpan Data", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  // ================= POPUP EDIT / VIEW =================
  void showFormEdit(Map<String, dynamic> item) {
    List<String> base64Images = List<String>.from(item["images"] ?? []);
    List<String> requestedBase64Images = List<String>.from(item["requestedImages"] ?? []);
    XFile? selectedVideo;
    String? existingVideoUrl = item["requestedVideoUrl"];
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          Future<void> pickImage(List<String> targetList) async {
            if (targetList.length >= 3) return;
            try {
              final picker = ImagePicker();
              final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 30, maxWidth: 600, maxHeight: 600);
              if (img != null) {
                final bytes = await img.readAsBytes();
                setStateDialog(() => targetList.add(base64Encode(bytes)));
              }
            } catch (e) { debugPrint(e.toString()); }
          }

          Future<void> pickVideo() async {
            try {
              final picker = ImagePicker();
              final vid = await picker.pickVideo(source: ImageSource.gallery);
              if (vid != null) {
                setStateDialog(() => selectedVideo = vid);
              }
            } catch (e) { debugPrint(e.toString()); }
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 550, padding: const EdgeInsets.all(25),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Detail & Edit Paket", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 15),
                    
                    if (item["rejectionReason"] != null && item["userApprovalStatus"] != "approved")
                      Container(
                        padding: const EdgeInsets.all(15), 
                        margin: const EdgeInsets.only(bottom: 20), 
                        decoration: BoxDecoration(
                          color: Colors.red.shade50, 
                          borderRadius: BorderRadius.circular(15), 
                          border: Border.all(color: Colors.red.shade200)
                        ), 
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, 
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.warning_amber_rounded, color: Colors.red), 
                                SizedBox(width: 8), 
                                Text("Ditolak oleh User:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))
                              ]
                            ), 
                            const SizedBox(height: 8), 
                            Text(item["rejectionReason"] ?? "Tidak ada alasan", style: const TextStyle(color: Colors.red)),
                            if (item["userApprovalStatus"] == "rejected") ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context); // Close showFormEdit
                                    showFormMasuk(editItem: item); // Open showFormMasuk with prefilled data
                                  },
                                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                                  label: const Text("Setujui & Edit Data", style: TextStyle(fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade600,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              )
                            ] else ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text("Sudah Diupdate, Menunggu Konfirmasi User", style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                              )
                            ]
                          ]
                        )
                      ),

                    if (item["catatanUser"] != null)
                      Container(
                        padding: const EdgeInsets.all(15), 
                        margin: const EdgeInsets.only(bottom: 20), 
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50, 
                          borderRadius: BorderRadius.circular(15), 
                          border: Border.all(color: Colors.indigo.shade200)
                        ), 
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, 
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.note_alt_outlined, color: Color(0xFF4F46E5)), 
                                SizedBox(width: 8), 
                                Text("Catatan dari User:", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)))
                              ]
                            ), 
                            const SizedBox(height: 8), 
                            Text(item["catatanUser"], style: const TextStyle(color: Color(0xFF3730A3)))
                          ]
                        )
                      ),
                    Text("No Resi: ${item["resi"]}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    const Text("Foto Paket Awal (Maksimal 3 Foto)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ...base64Images.asMap().entries.map((entry) {
                          int idx = entry.key;
                          return Stack(children: [Container(margin: const EdgeInsets.only(right: 10), width: 70, height: 70, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), image: DecorationImage(image: MemoryImage(base64Decode(entry.value)), fit: BoxFit.cover))), Positioned(top: 0, right: 10, child: GestureDetector(onTap: () => setStateDialog(() => base64Images.removeAt(idx)), child: Container(decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16))))]);
                        }),
                        if (base64Images.length < 3) GestureDetector(onTap: () => pickImage(base64Images), child: Container(width: 70, height: 70, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10), color: Colors.grey.shade50), child: const Icon(Icons.add_a_photo_outlined, color: Colors.grey))),
                      ],
                    ),

                    if (item["catatanUser"] != null) ...[
                      const SizedBox(height: 25),
                      const Text("Foto Permintaan User (Maksimal 3 Foto)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF427AB5))),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ...requestedBase64Images.asMap().entries.map((entry) {
                            int idx = entry.key;
                            return Stack(children: [Container(margin: const EdgeInsets.only(right: 10), width: 70, height: 70, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), image: DecorationImage(image: MemoryImage(base64Decode(entry.value)), fit: BoxFit.cover))), Positioned(top: 0, right: 10, child: GestureDetector(onTap: () => setStateDialog(() => requestedBase64Images.removeAt(idx)), child: Container(decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16))))]);
                          }),
                          if (requestedBase64Images.length < 3) GestureDetector(onTap: () => pickImage(requestedBase64Images), child: Container(width: 70, height: 70, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10), color: Colors.grey.shade50), child: const Icon(Icons.add_a_photo_outlined, color: Color(0xFF427AB5)))),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text("Video Permintaan User (Opsional, Maks 1)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF427AB5))),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (existingVideoUrl != null && selectedVideo == null)
                            Stack(
                              children: [
                                Container(
                                  width: 100, height: 70, decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)),
                                  child: const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 30)),
                                ),
                                Positioned(top: 0, right: 0, child: GestureDetector(onTap: () => setStateDialog(() => existingVideoUrl = null), child: Container(decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16))))
                              ]
                            )
                          else if (selectedVideo != null)
                            Stack(
                              children: [
                                Container(
                                  width: 100, height: 70, decoration: BoxDecoration(color: Colors.indigo.shade100, borderRadius: BorderRadius.circular(10)),
                                  child: const Center(child: Icon(Icons.video_file, color: Colors.indigo, size: 30)),
                                ),
                                Positioned(top: 0, right: 0, child: GestureDetector(onTap: () => setStateDialog(() => selectedVideo = null), child: Container(decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16))))
                              ]
                            )
                          else
                            GestureDetector(onTap: pickVideo, child: Container(width: 100, height: 70, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10), color: Colors.grey.shade50), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.video_library, color: Color(0xFF427AB5)), SizedBox(height: 4), Text("Pilih Video", style: TextStyle(fontSize: 10, color: Colors.grey))]))),
                        ],
                      ),
                    ],
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                            onPressed: () async {
                              try {
                                await _packageService.deletePackageByAdmin(item["id"] ?? "", item["resi"] ?? "", item["userId"]);
                                if (mounted) {
                                  CustomNotification.showSuccess(context, "Paket berhasil dihapus!");
                                  Navigator.pop(context);
                                }
                              } catch(e) {
                                if (mounted) CustomNotification.showError(context, "Gagal menghapus: $e");
                              }
                            },
                            child: const Text("Hapus", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF427AB5), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                            onPressed: isSaving ? null : () async {
                              setStateDialog(() => isSaving = true);
                              try {
                                String? finalVideoUrl = existingVideoUrl;
                                if (selectedVideo != null) {
                                  finalVideoUrl = await _packageService.uploadVideoToStorage(selectedVideo!);
                                }

                                await _packageService.updatePackageImages(
                                  item["resi"], 
                                  item["userId"], 
                                  base64Images,
                                  requestedImages: requestedBase64Images,
                                  requestedVideoUrl: finalVideoUrl,
                                  isFulfillingRequest: item["catatanUser"] != null
                                );
                                
                                if (mounted) {
                                  CustomNotification.showSuccess(context, "Berhasil update data!");
                                  Navigator.pop(context);
                                }
                              } catch(e) { 
                                if (mounted) {
                                  CustomNotification.showError(context, "Error: $e");
                                  setStateDialog(() => isSaving = false);
                                }
                              }
                            },
                            child: isSaving 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("Update Foto"),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 15 : 25, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row/Column
          isMobile 
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Manajemen Barang", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 4),
                  const Text("Kelola semua paket masuk dari pengguna", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _handleCetakLaporan,
                          icon: const Icon(Icons.print_rounded, size: 16),
                          label: const Text("Laporan", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF427AB5), 
                            side: BorderSide(color: const Color(0xFF427AB5).withOpacity(0.5)), 
                            padding: const EdgeInsets.symmetric(vertical: 12), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: const Color(0xFF427AB5).withOpacity(0.05),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => showFormMasuk(),
                          icon: const Icon(Icons.add_box_rounded, size: 16),
                          label: const Text("Masuk", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF427AB5), 
                            foregroundColor: Colors.white, 
                            padding: const EdgeInsets.symmetric(vertical: 12), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Manajemen Barang", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                        SizedBox(height: 4),
                        Text("Kelola semua paket masuk dari pengguna", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _handleCetakLaporan,
                        icon: const Icon(Icons.print_rounded, size: 18),
                        label: const Text("Cetak Laporan", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF427AB5), 
                          side: BorderSide(color: const Color(0xFF427AB5).withOpacity(0.5)), 
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15), 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: const Color(0xFF427AB5).withOpacity(0.05),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => showFormMasuk(),
                        icon: const Icon(Icons.add_box_rounded, size: 18),
                        label: const Text("Barang Masuk", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF427AB5), 
                          foregroundColor: Colors.white, 
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          const SizedBox(height: 15),
          
          // SEARCH BAR (Neat & Aligned)
          Wrap(
            spacing: 15,
            runSpacing: 15,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                width: isMobile ? double.infinity : 300,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: (v) => setState(() {}),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Cari Resi atau Nama...",
                    hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF427AB5), size: 18),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedDateFilter,
                    dropdownColor: Colors.white,
                    icon: Icon(Icons.calendar_today, size: 16, color: Colors.blue.shade700),
                    style: TextStyle(fontSize: 13, color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedDateFilter = newValue;
                        });
                      }
                    },
                    items: <String>['Semua Waktu', 'Hari Ini', '3 Hari Terakhir', 'Seminggu Terakhir']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(value),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterTab("All"),
                _filterTab("Request"),
                _filterTab("Ditolak"),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("packages_admin").orderBy("createdAt", descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData) return const Center(child: Text("Data tidak tersedia"));
                
                var query = _searchController.text.toLowerCase();
                final docs = snapshot.data!.docs;
                
                // 🔥 LOGIKA SORTING: Catatan User Duluan
                List<QueryDocumentSnapshot> sortedDocs = List.from(docs);
                sortedDocs.sort((a, b) {
                  var da = a.data() as Map<String, dynamic>;
                  var db = b.data() as Map<String, dynamic>;
                  bool aHasNote = da["catatanUser"] != null;
                  bool bHasNote = db["catatanUser"] != null;
                  
                  if (aHasNote && !bHasNote) return -1;
                  if (!aHasNote && bHasNote) return 1;
                  
                  // Jika sama-sama punya atau tidak punya, urutkan tanggal terbaru
                  var ta = da["createdAt"] as Timestamp?;
                  var tb = db["createdAt"] as Timestamp?;
                  if (ta == null) return 1;
                  if (tb == null) return -1;
                  return tb.compareTo(ta);
                });

                var filteredDocs = sortedDocs.where((doc) {
                  var item = doc.data() as Map<String, dynamic>;
                  String resi = (item["resi"] ?? "").toString().toLowerCase();
                  String nama = (item["nama"] ?? "").toString().toLowerCase();
                  bool matchesQuery = resi.contains(query) || nama.contains(query);
                  
                  bool matchesFilter = true;
                  if (selectedFilter == "Request") {
                    matchesFilter = item["catatanUser"] != null && item["catatanUser"].toString().isNotEmpty;
                  } else if (selectedFilter == "Ditolak") {
                    matchesFilter = item["rejectionReason"] != null && item["userApprovalStatus"] != "approved";
                  }
                  
                  bool matchesDate = true;
                  if (selectedDateFilter != "Semua Waktu" && item["createdAt"] != null) {
                    DateTime createdAt = (item["createdAt"] as Timestamp).toDate();
                    DateTime now = DateTime.now();
                    DateTime today = DateTime(now.year, now.month, now.day);
                    DateTime docDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
                    
                    if (selectedDateFilter == "Hari Ini") {
                      matchesDate = docDate.isAtSameMomentAs(today);
                    } else if (selectedDateFilter == "3 Hari Terakhir") {
                      matchesDate = docDate.isAfter(today.subtract(const Duration(days: 3)));
                    } else if (selectedDateFilter == "Seminggu Terakhir") {
                      matchesDate = docDate.isAfter(today.subtract(const Duration(days: 7)));
                    }
                  }

                  return matchesQuery && matchesFilter && matchesDate;
                }).toList();

                if (filteredDocs.isEmpty) return const Center(child: Text("Data tidak ditemukan"));

                return GridView.builder(
                  padding: const EdgeInsets.all(5),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: isMobile ? MediaQuery.of(context).size.width : 260,
                    mainAxisExtent: isMobile ? 200 : 160,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var doc = filteredDocs[index];
                    var item = doc.data() as Map<String, dynamic>;
                    item["id"] = doc.id;
                    bool hasNote = item["catatanUser"] != null;
                    bool isRejected = item["rejectionReason"] != null && item["userApprovalStatus"] != "approved";
                    bool isWaitingUser = item["userApprovalStatus"] == "pending" && item["isUpdatedByAdmin"] == true && isRejected;
                    Color katColor = _getKategoriColor(item["kategori"]);

                    return InkWell(
                      onTap: () => showFormEdit(item),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: isRejected ? Colors.red.withOpacity(0.15) : hasNote ? Colors.indigo.withOpacity(0.15) : const Color(0xFF427AB5).withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(
                            color: isRejected ? Colors.red.withOpacity(0.6) : hasNote ? Colors.indigo.withOpacity(0.6) : const Color(0xFF427AB5).withOpacity(0.2), 
                            width: (hasNote || isRejected) ? 2 : 1.2
                          ),
                        ),
                        child: Column(
                          children: [
                            // CARD HEADER (BLUE or RED if request)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isRejected 
                                    ? [const Color(0xFFEF4444), const Color(0xFFB91C1C)]
                                    : hasNote 
                                      ? [const Color(0xFF6366F1), const Color(0xFF4F46E5)] // Indigo/Violet modern
                                      : [const Color(0xFF427AB5), const Color(0xFF2C5282)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item["resi"] ?? "-",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isRejected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))
                                        ],
                                      ),
                                      child: Text(
                                        isWaitingUser ? "MENUNGGU USER" : "DITOLAK USER", 
                                        style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                                      ),
                                    )
                                  else if (hasNote)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFD700), // Gold/Yellow vibrant
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.star_rounded, size: 12, color: Color(0xFF92400E)),
                                          SizedBox(width: 4),
                                          Text(
                                            "REQUEST", 
                                            style: TextStyle(color: Color(0xFF92400E), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            
                            // CARD BODY
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey.shade400),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            item["keterangan"] ?? item["nama"] ?? "-",
                                            style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12, fontWeight: FontWeight.w700),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "ID: ${item["userIdCode"] ?? "-"}",
                                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          item["tanggal"] ?? "-",
                                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10), // Reduced from Spacer
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("BERAT", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 1)),
                                            Text(
                                              "${item["berat"] ?? 0} g",
                                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF427AB5)),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: katColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: katColor.withOpacity(0.2)),
                                          ),
                                          child: Text(
                                            (item["kategori"] ?? "-").toUpperCase(),
                                            style: TextStyle(color: katColor, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Color _getKategoriColor(String? kategori) {
    if (kategori == "Kecil") return Colors.red.shade700;
    if (kategori == "Sedang") return Colors.orange.shade800;
    if (kategori == "Besar") return Colors.green.shade700;
    return Colors.grey.shade700;
  }

  Widget _filterTab(String title) {
    bool active = selectedFilter == title;
    Color tabColor = const Color(0xFF427AB5);
    if (title == "Request") tabColor = const Color(0xFF4F46E5);
    if (title == "Ditolak") tabColor = Colors.red.shade600;

    return GestureDetector(
      onTap: () => setState(() => selectedFilter = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active ? tabColor : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: active ? tabColor : Colors.grey.shade200),
          boxShadow: active ? [BoxShadow(color: tabColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Text(
          title,
          style: TextStyle(
            color: active ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController controller = MobileScannerController(
    facing: CameraFacing.front, // Agar 'pantulan' seperti cermin di laptop
    formats: [BarcodeFormat.all], // Deteksi semua jenis barcode
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool isStarted = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Scan Barcode (Mode Kamera)"),
        backgroundColor: const Color(0xFF427AB5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded),
            onPressed: () => controller.switchCamera(),
            tooltip: "Ganti Kamera",
          ),
        ],
      ),
      body: Stack(
        children: [
          // PRATINJAU KAMERA ASLI
          SizedBox.expand(
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    CustomNotification.showSuccess(context, "Barcode Terdeteksi!");
                    Navigator.pop(context, barcode.rawValue);
                    break;
                  }
                }
              },
            ),
          ),
          
          // LAYAR AWAL SEBELUM START
          if (!isStarted)
            Container(
              color: const Color(0xFF1A1A1A),
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_front_rounded, color: Colors.white54, size: 100),
                  const SizedBox(height: 25),
                  const Text(
                    "Buka Pantulan Kamera",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 50),
                    child: Text(
                      "Klik tombol di bawah untuk melihat diri Anda dan mulai scan barcode.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await controller.start();
                        setState(() => isStarted = true);
                      } catch (e) {
                        CustomNotification.showError(context, "Izin kamera ditolak: $e");
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF427AB5),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 10,
                    ),
                    icon: const Icon(Icons.play_circle_fill_rounded),
                    label: const Text("NYALAKAN KAMERA SEKARANG", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ],
              ),
            ),
          
          // OVERLAY SCANNER PREMIUM
          if (isStarted)
            IgnorePointer(
              child: Stack(
                children: [
                  // Dim background except the hole
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.5),
                      BlendMode.srcOut,
                    ),
                    child: Stack(
                      children: [
                        Container(color: Colors.black),
                        Center(
                          child: Container(
                            width: 300,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Border and Text
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 300,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF427AB5), width: 4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "Dekatkan Barcode ke Kotak Biru",
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
