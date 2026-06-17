import 'package:satupaket/services/order_service.dart';
import 'package:satupaket/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../widgets/custom_notification.dart';

class KonfirmasiPage extends StatefulWidget {
  const KonfirmasiPage({super.key});

  @override
  State<KonfirmasiPage> createState() => _KonfirmasiPageState();
}

class _KonfirmasiPageState extends State<KonfirmasiPage> {
  final Set<String> selectedOrders = {};
  bool _isLoading = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String selectedDateFilter = "Semua Waktu";
  String selectedStatusFilter = "Semua Status";

  bool get isMobile => MediaQuery.of(context).size.width < 800;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // 🔥 DIALOG INPUT RESI BARU
  Future<void> showResiDialog(DocumentSnapshot doc) async {
    final TextEditingController resiController = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Input Nomor Resi Baru", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Silakan masukkan nomor resi pengiriman untuk user ini."),
            const SizedBox(height: 15),
            TextField(
              controller: resiController,
              decoration: InputDecoration(
                hintText: "Contoh: JNE123456789",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF427AB5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (resiController.text.isNotEmpty) {
                Navigator.pop(context);
                prosesPengirimanSingle(doc, resiController.text);
              }
            },
            child: const Text("Simpan & Kirim", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 🔥 DIALOG DETAIL PESANAN LENGKAP
  void _showOrderDetail(Map<String, dynamic> item, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.receipt_long_rounded, color: Color(0xFF427AB5)),
            const SizedBox(width: 12),
            const Text("Detail Pesanan User", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B))),
            const Spacer(),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
          ],
        ),
        content: SizedBox(
          width: 750,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // INFO USER
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
                        child: const Icon(Icons.person, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item["nama"] ?? "-", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B))),
                          _UserIdCodeWidget(userId: item["userId"], initialIdCode: item["userIdCode"], isLarge: true),
                        ],
                      ),
                      const Spacer(),
                      _buildStatusBadge(item["status"] ?? "Menunggu Konfirmasi"),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Bukti Pembayaran:", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B))),
                          const SizedBox(height: 12),
                          item["pembayaran"] == "COD"
                              ? Container(
                                  height: 250,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.blue.withOpacity(0.2), width: 2, style: BorderStyle.solid),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.payments_rounded, color: Colors.blue.shade700, size: 60),
                                      const SizedBox(height: 15),
                                      const Text("CASH ON DELIVERY (COD)", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blue, fontSize: 16)),
                                      const Text("Pembayaran saat barang sampai", style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                                    ],
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: _buildProofImage(item),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 25),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Ringkasan Pesanan:", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B))),
                          const SizedBox(height: 12),
                          _summaryRow("Metode Pembayaran", item["pembayaran"] ?? "Transfer"),
                          _summaryRow("Tipe Pengiriman", "${item["tipe"]} - ${item["pengiriman"]}"),
                          const Divider(height: 30),
                          _summaryRow("Total Tagihan", "Rp${item["total"] ?? 0}", isBold: true, color: Colors.green.shade700),
                          const SizedBox(height: 25),
                          const Text("Alamat Tujuan:", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.blueGrey)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                            child: _UserAddressWidget(userId: item["userId"], initialAddress: item["alamatTujuan"]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                const Text("Daftar Paket & Foto (Gudang):", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B))),
                const SizedBox(height: 15),
                ...List.generate((item["paket"] is List ? (item["paket"] as List).length : 0), (index) {
                  final p = (item["paket"] as List)[index];
                  return _PackageItemWidget(packageData: p);
                }),
              ],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                if (item["status"] == "Menunggu Konfirmasi") ...[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => tolakPesanan(docId).then((_) => Navigator.pop(context)),
                      child: const Text("Tolak Pesanan", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF427AB5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => accPesanan(docId).then((_) => Navigator.pop(context)),
                      child: const Text("Setujui (ACC)", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ] else if (item["status"] == "Diproses")
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.local_shipping_rounded, size: 18),
                      onPressed: () {
                        Navigator.pop(context);
                        FirebaseFirestore.instance.collection('orders').doc(docId).get().then((d) {
                          showResiDialog(d);
                        });
                      },
                      label: const Text("Kirim Barang (Input Resi)", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofImage(Map<String, dynamic> item) {
    try {
      if (item["buktiPembayaran"] != null && item["buktiPembayaran"].toString().isNotEmpty) {
        return Image.memory(base64Decode(item["buktiPembayaran"]), height: 350, width: double.infinity, fit: BoxFit.contain);
      } else if (item["buktiPembayaranUrl"] != null) {
        return Image.network(item["buktiPembayaranUrl"], height: 350, width: double.infinity, fit: BoxFit.contain);
      }
    } catch (e) {
      return Container(height: 200, color: Colors.grey.shade100, child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey)));
    }
    return Container(
      height: 250,
      width: double.infinity,
      color: Colors.grey.shade50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.no_photography_outlined, color: Colors.grey, size: 40),
          SizedBox(height: 10),
          Text("Belum upload bukti", style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String val, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.w500)),
          Text(val, style: TextStyle(fontWeight: isBold ? FontWeight.w900 : FontWeight.bold, fontSize: isBold ? 15 : 13, color: color ?? const Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == "Menunggu Konfirmasi") color = Colors.blue;
    if (status == "Diproses") color = Colors.orange;
    if (status == "Ditolak") color = Colors.red;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Future<void> prosesPengirimanSingle(DocumentSnapshot doc, String resiBaru) async {
    setState(() => _isLoading = true);
    try {
      final item = doc.data() as Map<String, dynamic>;
      
      // Ambil alamat dari order
      dynamic rawAlamat = item["alamatTujuan"] ?? item["alamat"] ?? "-";
      String finalAlamat = "-";

      if (rawAlamat is Map) {
        finalAlamat = "${rawAlamat['namaLengkap'] ?? ''}, ${rawAlamat['telepon'] ?? ''}\n${rawAlamat['detail'] ?? ''}, ${rawAlamat['desa'] ?? ''}, ${rawAlamat['kecamatan'] ?? ''}, ${rawAlamat['kabupaten'] ?? ''}, ${rawAlamat['provinsi'] ?? ''} ${rawAlamat['kodePos'] ?? ''}";
      } else if (rawAlamat is String) {
        finalAlamat = rawAlamat;
      }

      if (finalAlamat == "-" || finalAlamat.isEmpty) {
        final userDoc = await FirebaseFirestore.instance.collection('user').doc(item["userId"]).get();
        if (userDoc.exists) {
          final addrSnapshot = await userDoc.reference.collection('addresses').orderBy('createdAt', descending: true).limit(1).get();
          if (addrSnapshot.docs.isNotEmpty) {
            final a = addrSnapshot.docs.first.data();
            finalAlamat = "${a['namaLengkap']}, ${a['telepon']}\n${a['detail']}, ${a['desa']}, ${a['kecamatan']}, ${a['kabupaten']}, ${a['provinsi']} ${a['kodePos']}";
          }
        }
      }

      double totalBeratAktual = 0;
      double totalVolumeKg = 0;
      
      List paketList = item["paket"] ?? [];
      for (var p in paketList) {
        double b = (p["berat"] ?? 0).toDouble();
        totalBeratAktual += b;
        String dimensiStr = p["dimensi"] ?? "0x0x0";
        List<String> d = dimensiStr.split("x");
        if (d.length == 3) {
          double pVal = double.tryParse(d[0]) ?? 0;
          double lVal = double.tryParse(d[1]) ?? 0;
          double tVal = double.tryParse(d[2]) ?? 0;
          totalVolumeKg += (pVal * lVal * tVal) / 4000;
        }
      }

      double beratAktualKg = totalBeratAktual / 1000;
      double beratFinal = beratAktualKg > totalVolumeKg ? beratAktualKg : totalVolumeKg;
      int beratBulat = (beratFinal + 0.7).floor();
      if (beratBulat < 1) beratBulat = 1;

      double totalBiayaFinal = beratBulat * 13000; 

      Map<String, dynamic> dataPengiriman = {
        "resi": resiBaru,
        "resiAsal": item["resi"] ?? "-",
        "user": item["nama"] ?? "User",
        "userId": item["userId"] ?? "",
        "userIdCode": item["userIdCode"] ?? "-",
        "alamat": finalAlamat, // Simpan alamat lengkap
        "tanggal": DateTime.now().toString().split(" ")[0],
        "items": paketList,
        "totalBerat": totalBeratAktual,
        "beratTagihan": beratBulat,
        "totalBiaya": totalBiayaFinal,
        "pembayaran": item["pembayaran"] ?? "Transfer",
        "totalAsli": item["total"] ?? 0,
        "status": "Dikirim",
      };

      await OrderService.buatPengiriman(dataPengiriman);
      await OrderService.updateOrderStatusAndResi(doc.id, "Dikirim", resiBaru);
      
      if (item.containsKey("userId")) {
        await NotificationService.notifyOrderShipped(item["userId"], resiBaru);
      }

      if (mounted) {
        CustomNotification.showSuccess(context, "Berhasil! Barang dikirim & pindah ke Barang Keluar.");
      }
    } catch (e) {
      if (mounted) CustomNotification.showError(context, "Gagal: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> accPesanan(String orderId) async {
    try {
      await OrderService.updateOrderStatus(orderId, "Diproses");
      if (mounted) {
        CustomNotification.showSuccess(context, "Pesanan di-ACC.");
      }
    } catch (e) {
      if (mounted) CustomNotification.showError(context, "Gagal: $e");
    }
  }

  Future<void> tolakPesanan(String orderId) async {
    try {
      await OrderService.updateOrderStatus(orderId, "Ditolak");
      if (mounted) {
        CustomNotification.showInfo(context, "Pesanan ditolak.");
      }
    } catch (e) {
      if (mounted) CustomNotification.showError(context, "Gagal: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile 
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Konfirmasi Pesanan", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                  const SizedBox(height: 5),
                  const Text("Kelola persetujuan dan pengiriman paket user", style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Konfirmasi Pesanan", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                      SizedBox(height: 5),
                      Text("Kelola persetujuan dan pengiriman paket user", style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
                    ],
                  ),
                  if (_isLoading) const CircularProgressIndicator(),
                ],
              ),
          const SizedBox(height: 20),
          // 🔥 SEARCH BAR & FILTERS (Neat & Minimalist)
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
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "Cari Nama atau Resi...",
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
                        child: Padding(padding: const EdgeInsets.only(right: 8.0), child: Text(value)),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedStatusFilter,
                    dropdownColor: Colors.white,
                    icon: Icon(Icons.filter_list_rounded, size: 16, color: Colors.green.shade700),
                    style: TextStyle(fontSize: 13, color: Colors.green.shade900, fontWeight: FontWeight.bold),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedStatusFilter = newValue;
                        });
                      }
                    },
                    items: <String>['Semua Status', 'Menunggu Konfirmasi', 'Diproses']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Padding(padding: const EdgeInsets.only(right: 8.0), child: Text(value)),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          StreamBuilder<QuerySnapshot>(
            stream: OrderService.getAllOrdersStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Expanded(child: Center(child: CircularProgressIndicator()));
              if (snapshot.hasError) return const Expanded(child: Center(child: Text("Terjadi kesalahan data.")));

              final allDocs = (snapshot.data?.docs ?? []).where((doc) {
                final s = (doc.data() as Map<String, dynamic>)["status"];
                return s != "Dikirim" && s != "Disetujui";
              }).toList();

              // 🔥 FILTER SEARCH
              final docs = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                String nama = (data["nama"] ?? "").toString().toLowerCase();
                String uid = (data["userIdCode"] ?? "").toString().toLowerCase();
                String tgl = (data["tanggal"] ?? "").toString().toLowerCase();
                String status = (data["status"] ?? "Menunggu Konfirmasi");
                
                // Jika tanggal null, coba ambil dari createdAt
                if (data["createdAt"] != null && tgl == "") {
                  if (data["createdAt"] is Timestamp) {
                    tgl = (data["createdAt"] as Timestamp).toDate().toString().split(" ")[0];
                  } else {
                    tgl = data["createdAt"].toString().split(" ")[0];
                  }
                }
                
                bool matchesQuery = nama.contains(_searchQuery) || uid.contains(_searchQuery) || tgl.contains(_searchQuery);
                
                bool matchesStatus = true;
                if (selectedStatusFilter != "Semua Status") {
                  matchesStatus = (status == selectedStatusFilter);
                }
                
                bool matchesDate = true;
                if (selectedDateFilter != "Semua Waktu" && data["createdAt"] != null) {
                  DateTime createdAt = (data["createdAt"] as Timestamp).toDate();
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

                return matchesQuery && matchesStatus && matchesDate;
              }).toList();

              // Urutkan: Menunggu Konfirmasi dulu, baru Diproses
              docs.sort((a, b) {
                final sA = (a.data() as Map<String, dynamic>)["status"] ?? "Menunggu Konfirmasi";
                final sB = (b.data() as Map<String, dynamic>)["status"] ?? "Menunggu Konfirmasi";
                int rank(String s) {
                  if (s == "Menunggu Konfirmasi") return 0;
                  if (s == "Diproses") return 1;
                  return 2;
                }
                return rank(sA).compareTo(rank(sB));
              });

              if (docs.isEmpty) {
                return const Expanded(child: Center(child: Text("Belum ada pesanan masuk", style: TextStyle(color: Colors.grey, fontSize: 16))));
              }

                return Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: isMobile ? MediaQuery.of(context).size.width : 320,
                      mainAxisExtent: isMobile ? 120 : 140,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final doc = docs[i];
                      final item = doc.data() as Map<String, dynamic>;
                      return _BentoOrderCard(
                        item: item,
                        onTap: () => _showOrderDetail(item, doc.id),
                      );
                    },
                  ),
                );
              },
            ),
          ],
      ),
    );
  }
}

// 🔥 WIDGET KARTU BENTO UNTUK PESANAN (RE-DESIGNED)
class _BentoOrderCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const _BentoOrderCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    String status = item["status"] ?? "Menunggu Konfirmasi";
    
    // Indigo Palette for "Incoming/Pending"
    const Color primaryIndigo = Color(0xFF4F46E5);
    Color statusColor = Colors.grey;
    if (status == "Menunggu Konfirmasi") statusColor = Colors.blue;
    if (status == "Diproses") statusColor = Colors.orange;
    if (status == "Ditolak") statusColor = Colors.red;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (status == "Menunggu Konfirmasi" ? Colors.blue : (status == "Diproses" ? Colors.orange : Colors.red)).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item["nama"] ?? "-",
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(status),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.qr_code_rounded, size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 5),
                        Text(
                          item["resi"] ?? "-",
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Text(
                      item["tanggal"] ?? (item["createdAt"] != null ? (item["createdAt"] is Timestamp ? (item["createdAt"] as Timestamp).toDate().toString().split(" ")[0] : item["createdAt"].toString().split(" ")[0]) : "-"),
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _miniPreview(item),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("TOTAL", style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 0.5)),
                        Text(
                          "Rp${item["total"] ?? 0}",
                          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF10B981), fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == "Menunggu Konfirmasi") color = Colors.blue;
    if (status == "Diproses") color = Colors.orange;
    if (status == "Ditolak") color = Colors.red;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 8, letterSpacing: 0.5),
      ),
    );
  }

  Widget _miniPreview(Map<String, dynamic> item) {
    List paket = item["paket"] as List? ?? [];
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
          child: const Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF4F46E5)),
        ),
        const SizedBox(width: 8),
        Text("${paket.length} Pkt", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
      ],
    );
  }
}

// 🔥 WIDGET ALAMAT USER
class _UserAddressWidget extends StatelessWidget {
  final String? userId;
  final dynamic initialAddress;

  const _UserAddressWidget({this.userId, this.initialAddress});

  @override
  Widget build(BuildContext context) {
    if (initialAddress != null && initialAddress != "-") {
      if (initialAddress is Map) {
        final a = initialAddress as Map;
        final alamatLengkap = "${a['namaLengkap'] ?? ''}, ${a['telepon'] ?? ''}\n${a['detail'] ?? ''}, ${a['desa'] ?? ''}, ${a['kecamatan'] ?? ''}, ${a['kabupaten'] ?? ''}, ${a['provinsi'] ?? ''} ${a['kodePos'] ?? ''}";
        return Text(alamatLengkap, style: const TextStyle(fontSize: 12, color: Colors.black87));
      }
      if (initialAddress is String && initialAddress.toString().isNotEmpty) {
        return Text(initialAddress.toString(), style: const TextStyle(fontSize: 12, color: Colors.black87));
      }
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

class _UserIdCodeWidget extends StatelessWidget {
  final String? userId;
  final String? initialIdCode;
  final bool isLarge;
  const _UserIdCodeWidget({this.userId, this.initialIdCode, this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    if (initialIdCode != null && initialIdCode != "-") return Text(initialIdCode!, style: TextStyle(color: Colors.grey.shade500, fontSize: isLarge ? 12 : 10));
    if (userId == null || userId!.isEmpty) return Text("-", style: TextStyle(color: Colors.grey.shade500, fontSize: isLarge ? 12 : 10));
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('user').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          return Text(userData?['userIdCode'] ?? "-", style: TextStyle(color: Colors.grey.shade500, fontSize: isLarge ? 12 : 10));
        }
        return Text("-", style: TextStyle(color: Colors.grey.shade500, fontSize: isLarge ? 12 : 10));
      },
    );
  }
}

class _PackageItemWidget extends StatelessWidget {
  final dynamic packageData;
  const _PackageItemWidget({required this.packageData});

  @override
  Widget build(BuildContext context) {
    final String resi = packageData["resi"] ?? "-";
    List imgs = packageData["images"] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2, size: 16, color: Color(0xFF427AB5)),
              const SizedBox(width: 8),
              Text(resi, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              Text("${packageData["berat"] ?? 0}g | ${packageData["dimensi"] ?? "-"}cm", style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
            ],
          ),
          const SizedBox(height: 10),
          if (imgs.isNotEmpty) _buildImageRow(imgs)
          else FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('packages_admin').where('resi', isEqualTo: resi.trim()).limit(1).get(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                List fetchedImgs = data["images"] ?? [];
                if (fetchedImgs.isNotEmpty) return _buildImageRow(fetchedImgs);
              }
              return const Text("Tidak ada foto paket", style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageRow(List imgs) {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imgs.length,
        itemBuilder: (ctx, imgIdx) {
          try {
            return Container(
              margin: const EdgeInsets.only(right: 8),
              width: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: MemoryImage(base64Decode(imgs[imgIdx])), 
                  fit: BoxFit.cover
                ),
              ),
            );
          } catch (e) {
            return Container(
              margin: const EdgeInsets.only(right: 8),
              width: 70,
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.broken_image, color: Colors.grey, size: 20),
            );
          }
        },
      ),
    );
  }
}
