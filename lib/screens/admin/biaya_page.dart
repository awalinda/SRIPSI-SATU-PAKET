import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../services/biaya_service.dart';
import '../../widgets/custom_notification.dart';

class BiayaPage extends StatefulWidget {
  const BiayaPage({super.key});

  @override
  State<BiayaPage> createState() => _BiayaPageState();
}

class _BiayaPageState extends State<BiayaPage> {
  final BiayaService _biayaService = BiayaService();
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingQRIS = false;

  bool get isMobile => MediaQuery.of(context).size.width < 800;

  Future<void> _uploadQRIS(Map<String, dynamic>? currentData) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isUploadingQRIS = true);

      // 🔥 Upload ke Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child('settings/qris_${DateTime.now().millisecondsSinceEpoch}.png');
      
      final bytes = await image.readAsBytes();
      await storageRef.putData(bytes, SettableMetadata(contentType: 'image/png'));
      final downloadUrl = await storageRef.getDownloadURL();

      // 🔥 Update Firestore
      await _biayaService.updatePaymentMethod({
        ...(currentData ?? {}),
        "qrisUrl": downloadUrl,
      });

      if (!mounted) return;
      CustomNotification.showSuccess(context, "QRIS berhasil diperbarui!");
    } catch (e) {
      if (!mounted) return;
      CustomNotification.showError(context, "Gagal upload QRIS: $e");
    } finally {
      setState(() => _isUploadingQRIS = false);
    }
  }

  // ================= POPUP FORM EDIT HARGA =================
  void showEditBiaya(Map<String, dynamic>? currentData) {
    final hargaPerKg = TextEditingController(text: currentData?["hargaPerKg"]?.toString() ?? "");
    final bubbleWrap = TextEditingController(text: currentData?["bubbleWrap"]?.toString() ?? "");
    final kardus = TextEditingController(text: currentData?["kardus"]?.toString() ?? "");
    final kayu = TextEditingController(text: currentData?["kayu"]?.toString() ?? "");
    final reguler = TextEditingController(text: currentData?["shippingReguler"]?.toString() ?? "");
    final express = TextEditingController(text: currentData?["shippingExpress"]?.toString() ?? "");

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          child: Container(
            width: isMobile ? MediaQuery.of(context).size.width * 0.95 : 500,
            padding: EdgeInsets.all(isMobile ? 20 : 30),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Update Master Biaya",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 25),

                  const Text("Harga Dasar", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 10),
                  _input(hargaPerKg, "Harga Paket (Minimal 1kg)", Icons.money_rounded),

                  const Divider(height: 30),
                  const Text("Opsi Pengemasan (Opsional)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  const SizedBox(height: 10),
                  _input(bubbleWrap, "Bubble Wrap", Icons.layers_rounded),
                  _input(kardus, "Kardus", Icons.inventory_2_rounded),
                  _input(kayu, "Kayu", Icons.grid_view_rounded),

                  const Divider(height: 30),
                  const Text("Layanan Pengiriman", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 10),
                  _input(reguler, "Reguler", Icons.local_shipping_rounded),
                  _input(express, "Express", Icons.speed_rounded),

                  const SizedBox(height: 30),

                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Batal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF427AB5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          onPressed: () async {
                            // Fungsi untuk membersihkan titik/koma agar bisa diparse ke int
                            int parseMoney(String text) {
                              String cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
                              return int.tryParse(cleaned) ?? 0;
                            }

                            final data = {
                              "hargaPerKg": parseMoney(hargaPerKg.text),
                              "bubbleWrap": parseMoney(bubbleWrap.text),
                              "kardus": parseMoney(kardus.text),
                              "kayu": parseMoney(kayu.text),
                              "shippingReguler": parseMoney(reguler.text),
                              "shippingExpress": parseMoney(express.text),
                            };

                            await _biayaService.updateMasterBiaya(data);
                            if (!mounted) return;
                            Navigator.pop(context);
                            CustomNotification.showSuccess(context, "Master biaya berhasil diupdate!");
                          },
                          child: const Text("Update Harga", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _input(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: Colors.grey),
          prefixText: "Rp ",
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🏆 HEADER SECTION
          isMobile 
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Manajemen Biaya",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  Text("Atur seluruh tarif layanan dan pengiriman", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _biayaService.getMasterBiayaStream().first.then((snap) {
                          if (snap.exists) {
                            showEditBiaya(snap.data() as Map<String, dynamic>);
                          } else {
                            showEditBiaya(null);
                          }
                        });
                      },
                      icon: const Icon(Icons.edit_note_rounded, size: 20),
                      label: const Text("Update Semua Biaya", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF427AB5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Manajemen Biaya",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 4),
                      Text("Atur seluruh tarif layanan dan pengiriman", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Fetch current data to pass to dialog
                      _biayaService.getMasterBiayaStream().first.then((snap) {
                        if (snap.exists) {
                          showEditBiaya(snap.data() as Map<String, dynamic>);
                        } else {
                          showEditBiaya(null);
                        }
                      });
                    },
                    icon: const Icon(Icons.edit_note_rounded, size: 20),
                    label: const Text("Update Semua Biaya", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF427AB5),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),

          const SizedBox(height: 25),

          // 🔥 REAL-TIME MASTER BIAYA
          StreamBuilder<DocumentSnapshot>(
            stream: _biayaService.getMasterBiayaStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || !snapshot.data!.exists) return _buildEmptyState();

              final data = snapshot.data!.data() as Map<String, dynamic>;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🕒 UPDATED INFO
                  if (data["updatedAt"] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF427AB5).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF427AB5).withOpacity(0.1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.update_rounded, size: 14, color: Color(0xFF427AB5)),
                            const SizedBox(width: 8),
                            Text(
                              "Terakhir diperbarui: ${(data["updatedAt"] as Timestamp).toDate().toString().split(".")[0]}",
                              style: const TextStyle(color: Color(0xFF427AB5), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 📊 RESPONSIVE PRICE & RULES DISPLAY
                  StreamBuilder<DocumentSnapshot>(
                    stream: _biayaService.getPaymentMethodStream(),
                    builder: (context, paySnapshot) {
                      final payData = paySnapshot.data?.data() as Map<String, dynamic>?;
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          bool isMobile = constraints.maxWidth < 900;
                          return isMobile 
                            ? Column(
                                children: [
                                  _buildPriceTable(data),
                                  const SizedBox(height: 20),
                                  _buildPaymentCard(payData),
                                  const SizedBox(height: 20),
                                  _buildCalculationRules(),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: _buildPriceTable(data),
                                  ),
                                  const SizedBox(width: 25),
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      children: [
                                        _buildPaymentCard(payData),
                                        const SizedBox(height: 20),
                                        _buildCalculationRules(),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                        }
                      );
                    }
                  ),

                  const SizedBox(height: 50),
                  _buildHistorySection(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.settings_suggest_rounded, size: 80, color: Colors.blueGrey),
          const SizedBox(height: 20),
          const Text("Master Biaya belum diset", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: () => showEditBiaya(null), child: const Text("Set Harga Sekarang")),
        ],
      ),
    );
  }



  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.history_rounded, color: Colors.grey),
            SizedBox(width: 10),
            Text("Riwayat Perubahan Harga", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 20),
        StreamBuilder<QuerySnapshot>(
          stream: _biayaService.getBiayaHistoryStream(),
          builder: (context, historySnapshot) {
            if (!historySnapshot.hasData || historySnapshot.data!.docs.isEmpty) {
              return const Text("Belum ada riwayat perubahan.", style: TextStyle(color: Colors.grey));
            }
            final historyDocs = historySnapshot.data!.docs;
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: historyDocs.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final hData = historyDocs[index].data() as Map<String, dynamic>;
                  final date = (hData["archivedAt"] as Timestamp?)?.toDate() ?? DateTime.now();
                  final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);
                  return ExpansionTile(
                    leading: const Icon(Icons.history_toggle_off_rounded, color: Colors.blueGrey),
                    title: Text("Berlaku hingga $formattedDate", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Table(
                          children: [
                            _tableRow("Harga Paket", "Rp ${hData["hargaPerKg"]}"),
                            _tableRow("Reguler", "Rp ${hData["shippingReguler"]}"),
                          ],
                        ),
                      )
                    ],
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic>? payData) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Pembayaran", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
              _actionBtn(Icons.edit_rounded, const Color(0xFF427AB5), () => showEditPayment(payData)),
            ],
          ),
          const SizedBox(height: 15),
          _infoItem("Bank", payData?["bankName"] ?? "-", Icons.account_balance_rounded),
          _infoItem("No. Rek", payData?["accountNumber"] ?? "-", Icons.credit_card_rounded),
          _infoItem("Nama", payData?["accountHolder"] ?? "-", Icons.person_pin_rounded),
          const SizedBox(height: 15),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("QRIS Code", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              if (payData?["qrisUrl"] != null)
                _actionBtn(Icons.qr_code_scanner_rounded, const Color(0xFF427AB5), () {
                  _showFullQRIS(payData!["qrisUrl"]);
                }),
            ],
          ),
          const SizedBox(height: 10),
          if (payData?["qrisUrl"] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                payData!["qrisUrl"],
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                ),
              ),
            )
          else
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_2_rounded, color: Colors.grey, size: 24),
                  SizedBox(height: 4),
                  Text("Belum ada QRIS", style: TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceTable(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Daftar Tarif Aktif", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
            },
            children: [
              _tableRow("Layanan Utama", "Harga", isHeader: true),
              _tableRow("Paket per KG (Antar)", "Rp ${data["hargaPerKg"]}"),
              _tableRow("Paket per Item (Ambil)", "Rp ${data["hargaPerPaket"] ?? data["hargaPerKg"] ?? 0}"),
              _tableRow("Kirim Reguler", "Rp ${data["shippingReguler"]}"),
              _tableRow("Kirim Express", "Rp ${data["shippingExpress"]}"),

              const TableRow(children: [SizedBox(height: 20), SizedBox()]),
              _tableRow("Opsi Tambahan", "Harga", isHeader: true),
              _tableRow("Bubble Wrap", "Rp ${data["bubbleWrap"]}"),
              _tableRow("Kardus", "Rp ${data["kardus"]}"),
              _tableRow("Kayu", "Rp ${data["kayu"]}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  // ================= POPUP EDIT PEMBAYARAN =================
  void showEditPayment(Map<String, dynamic>? currentData) {
    final bankName = TextEditingController(text: currentData?["bankName"] ?? "");
    final accountNumber = TextEditingController(text: currentData?["accountNumber"] ?? "");
    final accountHolder = TextEditingController(text: currentData?["accountHolder"] ?? "");

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Update Rekening Pembayaran",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 25),

                _inputGeneral(bankName, "Nama Bank (Contoh: BCA / BRI)", Icons.account_balance_rounded),
                _inputGeneral(accountNumber, "Nomor Rekening", Icons.credit_card_rounded, keyboard: TextInputType.number),
                _inputGeneral(accountHolder, "Atas Nama Pemilik", Icons.person_pin_rounded),

                const SizedBox(height: 10),
                const Text("QRIS Code", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 10),
                
                InkWell(
                  onTap: _isUploadingQRIS ? null : () => _uploadQRIS(currentData),
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                    ),
                    child: _isUploadingQRIS 
                      ? const Center(child: CircularProgressIndicator())
                      : currentData?["qrisUrl"] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(currentData!["qrisUrl"], fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload_outlined, color: Color(0xFF427AB5), size: 30),
                              SizedBox(height: 8),
                              Text("Klik untuk Upload QRIS", style: TextStyle(fontSize: 12, color: Color(0xFF427AB5), fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 25),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Batal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF427AB5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: () async {
                          await _biayaService.updatePaymentMethod({
                            "bankName": bankName.text,
                            "accountNumber": accountNumber.text,
                            "accountHolder": accountHolder.text,
                          });
                          if (!mounted) return;
                          Navigator.pop(context);
                          CustomNotification.showSuccess(context, "Rekening berhasil diperbarui!");
                        },
                        child: const Text("Simpan Rekening", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _inputGeneral(TextEditingController controller, String label, IconData icon, {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  void _showFullQRIS(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF427AB5)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TableRow _tableRow(String label, String value, {bool isHeader = false}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Text(
            label, 
            style: TextStyle(
              fontWeight: isHeader ? FontWeight.w900 : FontWeight.w500, 
              fontSize: isHeader ? 14 : 13,
              color: isHeader ? const Color(0xFF1A1A1A) : Colors.grey.shade700,
            )
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Text(
            value, 
            style: TextStyle(
              fontWeight: FontWeight.w900, 
              fontSize: 14,
              color: isHeader ? const Color(0xFF1A1A1A) : const Color(0xFF427AB5)
            )
          ),
        ),
      ],
    );
  }

  Widget _buildCalculationRules() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF427AB5).withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF427AB5).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFF427AB5)),
              const SizedBox(width: 10),
              const Flexible(
                child: Text(
                  "Aturan Kalkulasi", 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF427AB5)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            "• Berat < 1.0 kg dihitung 1.0 kg\n• Berat > 1.0 kg dihitung pembulatan ke atas\n• Total = (Berat × Harga) + Tambahan",
            softWrap: true,
            style: TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF427AB5)),
          ),
        ],
      ),
    );
  }
}
