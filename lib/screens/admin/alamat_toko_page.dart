import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../../services/warehouse_service.dart';
import '../../widgets/custom_notification.dart';

class AlamatTokoPage extends StatefulWidget {
  const AlamatTokoPage({super.key});

  @override
  State<AlamatTokoPage> createState() => _AlamatTokoPageState();
}

class _AlamatTokoPageState extends State<AlamatTokoPage> {
  final WarehouseService _warehouseService = WarehouseService();

  // ================= POPUP FORM =================
  void showForm({Map<String, dynamic>? data, String? docId}) {
    final namaGudang = TextEditingController(text: data?["namaGudang"] ?? "");
    final penerima = TextEditingController(text: data?["penerima"] ?? "");
    final telp = TextEditingController(text: data?["telp"] ?? "");
    final provinsi = TextEditingController(text: data?["provinsi"] ?? "");
    final kota = TextEditingController(text: data?["kota"] ?? "");
    final kecamatan = TextEditingController(text: data?["kecamatan"] ?? "");
    final kodePos = TextEditingController(text: data?["kodePos"] ?? "");
    final detail = TextEditingController(text: data?["detail"] ?? "");

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: min(550, MediaQuery.of(context).size.width * 0.9),
            padding: const EdgeInsets.all(25),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data == null ? "Tambah Gudang Baru" : "Update Detail Gudang",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Pastikan data yang dimasukkan sudah benar",
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                          ),
                        ],
                      ),
                      _actionBtn(Icons.close_rounded, Colors.grey.shade400, () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 25),

                  Row(
                    children: [
                      Expanded(child: _input(namaGudang, "Nama Gudang", Icons.warehouse_rounded)),
                      const SizedBox(width: 15),
                      Expanded(child: _input(penerima, "Penerima / CP", Icons.person_outline_rounded)),
                    ],
                  ),
                  _input(telp, "Nomor Telepon WhatsApp", Icons.phone_android_rounded, keyboard: TextInputType.phone),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Row(
                      children: [
                        Text("Informasi Lokasi", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF427AB5))),
                        SizedBox(width: 10),
                        Expanded(child: Divider(thickness: 1, color: Color(0xFFF1F5F9))),
                      ],
                    ),
                  ),
                  
                  Row(
                    children: [
                      Expanded(child: _input(provinsi, "Provinsi", Icons.map_outlined)),
                      const SizedBox(width: 15),
                      Expanded(child: _input(kota, "Kota / Kabupaten", Icons.location_city_rounded)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: _input(kecamatan, "Kecamatan", Icons.explore_outlined)),
                      const SizedBox(width: 15),
                      Expanded(child: _input(kodePos, "Kode Pos", Icons.mark_as_unread_rounded, keyboard: TextInputType.number)),
                    ],
                  ),
                  _input(detail, "Alamat Lengkap (Jl, No, RT/RW)", Icons.note_alt_outlined, maxLines: 3),

                  const SizedBox(height: 25),

                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Batalkan", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF427AB5),
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: const Color(0xFF427AB5).withOpacity(0.3),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            final newData = {
                              "namaGudang": namaGudang.text,
                              "penerima": penerima.text,
                              "telp": telp.text,
                              "provinsi": provinsi.text,
                              "kota": kota.text,
                              "kecamatan": kecamatan.text,
                              "kodePos": kodePos.text,
                              "detail": detail.text,
                            };

                            if (data == null) {
                              await _warehouseService.addWarehouse(newData);
                            } else {
                              await _warehouseService.updateWarehouse(docId!, newData);
                            }

                            if (!mounted) return;
                            Navigator.pop(context);
                            CustomNotification.showSuccess(context, "Data gudang berhasil disimpan!");
                          },
                          child: const Text("Simpan Perubahan", style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _input(TextEditingController controller, String label, IconData icon, {TextInputType keyboard = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboard,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), 
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), 
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), 
                borderSide: const BorderSide(color: Color(0xFF427AB5), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 15 : (MediaQuery.of(context).size.width > 900 ? 40 : 15),
        vertical: 25,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🏆 HEADER SECTION
          isMobile 
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Alamat Gudang",
                    style: TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.w900, 
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF427AB5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Pusat distribusi barang Anda",
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => showForm(),
                      icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                      label: const Text("Tambah Alamat", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Alamat Gudang",
                          style: TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.w900, 
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFF427AB5),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Pusat distribusi barang Anda",
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => showForm(),
                    icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                    label: const Text("Tambah Alamat", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF427AB5),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(0xFF427AB5).withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),

          const SizedBox(height: 25),

          // 📦 GRID DATA
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _warehouseService.getWarehouseStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF427AB5)));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off_rounded, size: 50, color: Colors.grey.shade200),
                        const SizedBox(height: 15),
                        Text(
                          "Belum Ada Alamat",
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: isMobile ? MediaQuery.of(context).size.width : 400,
                    crossAxisSpacing: isMobile ? 12 : 20,
                    mainAxisSpacing: isMobile ? 12 : 20,
                    mainAxisExtent: isMobile ? 240 : 190,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final item = doc.data() as Map<String, dynamic>;

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade100, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF427AB5).withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item["namaGudang"]?.toUpperCase() ?? "GUDANG",
                                  style: const TextStyle(
                                    color: Color(0xFF427AB5), 
                                    fontWeight: FontWeight.w900, 
                                    fontSize: 9,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  _actionBtn(Icons.edit_outlined, Colors.grey.shade400, () => showForm(data: item, docId: doc.id)),
                                  const SizedBox(width: 6),
                                  _actionBtn(Icons.delete_outline_rounded, Colors.red.shade300, () => _warehouseService.deleteWarehouse(doc.id)),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item["penerima"] ?? "-",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.phone_rounded, size: 12, color: Colors.grey.shade400),
                              const SizedBox(width: 5),
                              Text(
                                item["telp"] ?? "-",
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF427AB5)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "${item["detail"]}, ${item["kecamatan"]}, ${item["kota"]}, ${item["provinsi"]} ${item["kodePos"]}",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey.shade600, 
                                      fontSize: 11, 
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
