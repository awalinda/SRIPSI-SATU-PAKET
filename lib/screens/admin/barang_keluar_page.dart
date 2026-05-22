import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/order_service.dart';
import '../../services/report_service.dart';
import 'dart:convert';
import '../../widgets/custom_notification.dart';

class BarangKeluarPage extends StatefulWidget {
  const BarangKeluarPage({super.key});

  @override
  State<BarangKeluarPage> createState() => _BarangKeluarPageState();
}

class _BarangKeluarPageState extends State<BarangKeluarPage> {
  final ReportService _reportService = ReportService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final FocusNode _searchFocusNode = FocusNode();

  bool get isMobile => MediaQuery.of(context).size.width < 800;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // 🔥 DIALOG PILIH LAPORAN
  void _showReportDialog() {
    String selectedFilter = "Mingguan";
    String selectedFormat = "PDF";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Cetak Laporan Barang Keluar", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Pilih Rentang Waktu:", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              _filterOptionReport(setDialogState, "Mingguan", selectedFilter, (val) => selectedFilter = val),
              _filterOptionReport(setDialogState, "Bulanan", selectedFilter, (val) => selectedFilter = val),
              _filterOptionReport(setDialogState, "Semua", selectedFilter, (val) => selectedFilter = val),
              
              const SizedBox(height: 20),
              const Text("Pilih Format File:", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _formatOptionReport(setDialogState, "PDF", Icons.picture_as_pdf, Colors.red, selectedFormat, (val) => selectedFormat = val),
                  const SizedBox(width: 10),
                  _formatOptionReport(setDialogState, "Excel", Icons.table_chart, Colors.green, selectedFormat, (val) => selectedFormat = val),
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
                    type: "Barang Keluar",
                    filter: selectedFilter,
                    format: selectedFormat,
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔥 HEADER
          // Header Row/Column
          isMobile 
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Barang Keluar", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 4),
                  const Text("Daftar paket yang telah dikirim ke pelanggan", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showReportDialog,
                      icon: const Icon(Icons.print_rounded, size: 16),
                      label: const Text("Cetak Laporan", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF427AB5),
                        side: BorderSide(color: const Color(0xFF427AB5).withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: const Color(0xFF427AB5).withOpacity(0.05),
                      ),
                    ),
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
                        Text("Barang Keluar", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                        SizedBox(height: 4),
                        Text("Daftar paket yang telah dikirim ke pelanggan", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _showReportDialog,
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text("Cetak Laporan", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF427AB5),
                      side: BorderSide(color: const Color(0xFF427AB5).withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: const Color(0xFF427AB5).withOpacity(0.05),
                    ),
                  ),
                ],
              ),
          
          const SizedBox(height: 15),

          // 🔥 SEARCH BAR (Neat & Minimalist)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: isMobile ? double.infinity : 300,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))
                ],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
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
          ),

          const SizedBox(height: 15),

          // 🔥 CONTENT (GRID BOXES)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: OrderService.getPengirimanStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text("Terjadi kesalahan."));
                }

                final allDocs = snapshot.data?.docs ?? [];
                
                final docs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  String resi = (data["resi"] ?? "").toString().toLowerCase();
                  String resiAsal = (data["resiAsal"] ?? "").toString().toLowerCase();
                  String user = (data["user"] ?? "").toString().toLowerCase();
                  String uidCode = (data["userIdCode"] ?? "").toString().toLowerCase();
                  
                  return resi.contains(_searchQuery) || 
                         resiAsal.contains(_searchQuery) || 
                         user.contains(_searchQuery) || 
                         uidCode.contains(_searchQuery);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Data tidak ditemukan atau belum ada barang keluar",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: isMobile ? MediaQuery.of(context).size.width : 350,
                    mainAxisExtent: isMobile ? 120 : 110,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final item = docs[i].data() as Map<String, dynamic>;
                    
                    return InkWell(
                      onTap: () => _showDetailDialog(item),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: const Color(0xFF427AB5).withOpacity(0.1), width: 1),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ROW 1: TANGGAL & PAYMENT
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item["tanggal"] ?? "-",
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (item["pembayaran"] == "COD" ? Colors.blue : Colors.purple).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item["pembayaran"] ?? "TF",
                                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: (item["pembayaran"] == "COD" ? Colors.blue : Colors.purple)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // ROW 2: RESI & HARGA
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item["resi"] ?? "-",
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1E293B)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    "Rp${item["totalBiaya"]}",
                                    style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF10B981), fontSize: 15),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // ROW 3: USER INFO
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item["user"] ?? "-",
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF64748B)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  _UserIdCodeWidget(userId: item["userId"], initialIdCode: item["userIdCode"]),
                                ],
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

  void _showDetailDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF427AB5).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF427AB5)),
            ),
            const SizedBox(width: 15),
            Expanded(child: Text("Detail Pengiriman - ${item["resi"]}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B)))),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
          ],
        ),
        content: SizedBox(
          width: 700,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // USER INFO
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF427AB5).withOpacity(0.08), const Color(0xFF427AB5).withOpacity(0.02)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF427AB5).withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFF427AB5), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item["user"] ?? "-", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B))),
                          _UserIdCodeWidget(userId: item["userId"], initialIdCode: item["userIdCode"], isLarge: true),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                const Text("Daftar Paket & Foto:", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 15)),
                const SizedBox(height: 15),
                ...List.generate((item["items"] as List? ?? []).length, (index) {
                  final p = (item["items"] as List)[index];
                  return _PackageItemWidget(packageData: p);
                }),
                const Divider(height: 40),
                _rowDetail("Resi Asal (Gabungan)", item["resiAsal"] ?? "-"),
                _rowDetail("Nomor Resi Baru", item["resi"] ?? "-"),
                _rowDetail("Tanggal Dikirim", item["tanggal"] ?? "-"),
                _rowDetail("Metode Pembayaran", item["pembayaran"] ?? "Transfer"),
                _rowDetail("Total Berat Aktual", "${item["totalBerat"]} g"),
                const SizedBox(height: 15),
                const Text("Alamat Pengiriman:", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.blueGrey)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
                  child: _UserAddressWidget(userId: item["userId"], initialAddress: item["alamat"]),
                ),
                const SizedBox(height: 25),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.withOpacity(0.2))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Biaya Pengiriman:", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B))),
                      Text("Rp${item["totalBiaya"]}", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.green.shade700, fontSize: 20)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15, bottom: 15),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF427AB5),
                foregroundColor: Colors.white,
                minimumSize: const Size(120, 45),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(context), 
              child: const Text("Selesai", style: TextStyle(fontWeight: FontWeight.bold))
            ),
          ),
        ],
      ),
    );
  }


  Widget _rowDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

// 🔥 WIDGET UNTUK MENAMPILKAN ID USER SECARA AKURAT
class _UserIdCodeWidget extends StatelessWidget {
  final String? userId;
  final String? initialIdCode;
  final bool isLarge;

  const _UserIdCodeWidget({this.userId, this.initialIdCode, this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    // Jika ID sudah ada dan bukan "-", langsung tampilkan
    if (initialIdCode != null && initialIdCode != "-") {
      return Text(
        initialIdCode!,
        style: TextStyle(color: Colors.grey.shade500, fontSize: isLarge ? 12 : 10),
      );
    }

    // Jika ID "-", coba ambil dari koleksi 'user'
    if (userId == null || userId!.isEmpty) {
      return Text("-", style: TextStyle(color: Colors.grey.shade500, fontSize: isLarge ? 12 : 10));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('user').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final idCode = userData?['userIdCode'] ?? "-";
          return Text(
            idCode,
            style: TextStyle(color: Colors.grey.shade500, fontSize: isLarge ? 12 : 10),
          );
        }
        return Text("-", style: TextStyle(color: Colors.grey.shade500, fontSize: isLarge ? 12 : 10));
      },
    );
  }
}

// 🔥 WIDGET UNTUK MENAMPILKAN DETAIL PAKET TERMASUK FOTO DARI BARANG MASUK
class _PackageItemWidget extends StatelessWidget {
  final dynamic packageData;

  const _PackageItemWidget({required this.packageData});

  @override
  Widget build(BuildContext context) {
    final String resi = packageData["resi"] ?? "-";
    List imgs = packageData["images"] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2, size: 18, color: Color(0xFF427AB5)),
              const SizedBox(width: 10),
              Text(resi, style: const TextStyle(fontWeight: FontWeight.w900)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Text("${packageData["berat"] ?? 0}g | ${packageData["dimensi"] ?? "-"}cm", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 🔥 JIKA FOTO TIDAK ADA, COBA AMBIL DARI BARANG MASUK (packages_admin)
          if (imgs.isNotEmpty)
            _buildImageRow(imgs)
          else
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('packages_admin')
                  .where('resi', isEqualTo: resi.trim())
                  .limit(1)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                  List fetchedImgs = data["images"] ?? [];
                  if (fetchedImgs.isNotEmpty) return _buildImageRow(fetchedImgs);
                }
                return const Text("Tidak ada foto", style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic));
              },
            ),
        ],
      ),
    );
  }

  Widget _buildImageRow(List imgs) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imgs.length,
        itemBuilder: (ctx, imgIdx) {
          try {
            return Container(
              margin: const EdgeInsets.only(right: 10),
              width: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: MemoryImage(base64Decode(imgs[imgIdx])), 
                  fit: BoxFit.cover
                ),
              ),
            );
          } catch (e) {
            return Container(
              margin: const EdgeInsets.only(right: 10),
              width: 80,
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.broken_image, color: Colors.grey, size: 20),
            );
          }
        },
      ),
    );
  }

}

// 🔥 WIDGET ALAMAT USER
class _UserAddressWidget extends StatelessWidget {
  final String? userId;
  final String? initialAddress;

  const _UserAddressWidget({this.userId, this.initialAddress});

  @override
  Widget build(BuildContext context) {
    if (initialAddress != null && initialAddress != "-" && initialAddress!.isNotEmpty) {
      return Text(initialAddress!, style: const TextStyle(fontSize: 12, color: Colors.black87));
    }

    if (userId == null || userId!.isEmpty) {
      return const Text("Alamat tidak tersedia", style: TextStyle(fontSize: 12, color: Colors.grey));
    }

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('user').doc(userId).collection('addresses').orderBy('createdAt', descending: true).limit(1).get(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final a = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          final alamatLengkap = "${a['namaLengkap']}, ${a['telepon']}\n${a['detail']}, ${a['desa']}, ${a['kecamatan']}, ${a['kabupaten']}, ${a['provinsi']} ${a['kodePos']}";
          return Text(alamatLengkap, style: const TextStyle(fontSize: 12, color: Colors.black87));
        }
        return const Text("Memuat alamat...", style: TextStyle(fontSize: 11, color: Colors.grey));
      },
    );
  }
}
