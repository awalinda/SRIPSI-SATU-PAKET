import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/package_service.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'konsolidasi_page.dart';
import 'detail_paket_page.dart';

class PaketPage extends StatefulWidget {
  const PaketPage({super.key});

  @override
  State<PaketPage> createState() => _PaketPageState();
}

class _PaketPageState extends State<PaketPage> {
  final PackageService _packageService = PackageService();
  final Set<String> _selectedPackageIds = {};

  @override
  void initState() {
    super.initState();
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return "-";
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is String) {
      dateTime = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      return "-";
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return "Baru saja";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes} mnt yang lalu";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} jam yang lalu";
    } else if (difference.inDays < 7) {
      return "${difference.inDays} hari yang lalu";
    } else {
      return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? uid = AuthService().currentUser?.uid;

    if (uid == null) {
      return const Center(child: Text("Silakan login terlebih dahulu"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _packageService.getPackagesStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final paketDocs = snapshot.data?.docs ?? [];

        double totalBerat = 0;
        for (var doc in paketDocs) {
          if (_selectedPackageIds.contains(doc.id)) {
            totalBerat += (doc.data() as Map<String, dynamic>)["berat"] ?? 0;
          }
        }

        int selectedCount = _selectedPackageIds.length;

        // Estimasi Perhitungan Biaya
        // Rata-rata ongkir e-commerce Jkt - Lampung Kabupaten = Rp 42.000 / paket
        int estimasiEcommerceNormal = selectedCount * 42000;
        
        // Estimasi Satupaket (Biaya Konsolidasi + Asumsi Rp13k/kg)
        int beratBulat = (totalBerat / 1000).ceil();
        if (beratBulat < 1) beratBulat = 1;
        int estimasiSatupaket = (selectedCount * 2000) + (beratBulat * 13000);
        
        int hematBiaya = estimasiEcommerceNormal - estimasiSatupaket;
        if (hematBiaya < 0) hematBiaya = 0;

        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.transparent,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(35),
              topRight: Radius.circular(35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 HEADER SECTION
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 30, 25, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Paket Saya",
                          style: TextStyle(
                            fontSize: 28, 
                            fontWeight: FontWeight.w900, 
                            color: Color(0xFF1A1A1A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF427AB5).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "${paketDocs.length} Paket",
                                style: const TextStyle(
                                  color: Color(0xFF427AB5),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Siap dikonsolidasi",
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF427AB5), size: 24),
                    ),
                  ],
                ),
              ),

              // 🔹 LIST PAKET
              Expanded(
                child: paketDocs.isEmpty
                    ? const Center(child: Text("Belum ada paket", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                        physics: const BouncingScrollPhysics(),
                        itemCount: paketDocs.length,
                        itemBuilder: (context, index) {
                          var doc = paketDocs[index];
                          var paket = doc.data() as Map<String, dynamic>;
                          String docId = doc.id;
                          bool isChecked = _selectedPackageIds.contains(docId);

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: isChecked ? const Color(0xFF427AB5).withOpacity(0.05) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isChecked ? const Color(0xFF427AB5) : Colors.grey.shade200,
                                width: 1.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetailPaketPage(paket: {...paket, "id": docId}),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // 1. Checkbox (Hanya bagian ini yang toggle selection)
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (isChecked) {
                                              _selectedPackageIds.remove(docId);
                                            } else {
                                              _selectedPackageIds.add(docId);
                                            }
                                          });
                                        },
                                        behavior: HitTestBehavior.opaque,
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 12),
                                          child: isChecked
                                            ? const Icon(Icons.check_circle, color: Color(0xFF427AB5), size: 22)
                                            : Icon(Icons.circle_outlined, color: Colors.grey.shade300, size: 22),
                                        ),
                                      ),
                                      
                                      // 2. Photo
                                      Container(
                                        width: 55,
                                        height: 55,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          color: Colors.grey.shade100,
                                        ),
                                        child: (paket["images"] != null && (paket["images"] as List).isNotEmpty)
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(10),
                                                child: Image.memory(
                                                  base64Decode((paket["images"] as List).first),
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : Icon(
                                                Icons.inventory_2_outlined,
                                                size: 24,
                                                color: Colors.grey.shade300,
                                              ),
                                      ),
                                      
                                      const SizedBox(width: 12),
    
                                      // 3. Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              (paket["keterangan"] != null && paket["keterangan"].toString().isNotEmpty)
                                                  ? paket["keterangan"]
                                                  : "Paket ${paket['resi'] ?? ''}",
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800, 
                                                fontSize: 13,
                                                color: Color(0xFF2D3436),
                                                height: 1.2,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.qr_code_rounded, size: 12, color: Colors.grey.shade400),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    paket["resi"] ?? "",
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade400),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    _formatDateTime(paket["createdAt"]),
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.grey.shade200),
                                              ),
                                              child: Text(
                                                (paket["berat"] ?? 0) < 1000
                                                    ? "${paket["berat"]}g"
                                                    : "${((paket["berat"] ?? 0) / 1000).toStringAsFixed(1)}kg",
                                                style: TextStyle(
                                                  color: isChecked ? const Color(0xFF427AB5) : Colors.grey.shade700,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
    
                                      const SizedBox(width: 10),
    
                                      // 4. Detail Arrow
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // 🔹 FLOATING SUMMARY PANEL
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 5, 15, 15),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E3C72).withOpacity(0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      )
                    ],
                    border: Border.all(color: const Color(0xFF1E3C72).withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF427AB5).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF427AB5), size: 18),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "$selectedCount Item (${totalBerat < 1000 ? '${totalBerat.toStringAsFixed(0)} g' : '${(totalBerat / 1000).toStringAsFixed(1)} kg'})",
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  selectedCount > 0 ? "Est. Rp${estimasiSatupaket.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}" : "Rp0",
                                  style: const TextStyle(
                                    color: Color(0xFF1E3C72),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                if (selectedCount > 0 && hematBiaya > 0)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent.shade400.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.greenAccent.shade400, width: 0.5),
                                    ),
                                    child: Text(
                                      "Hemat Rp${hematBiaya.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}",
                                      style: TextStyle(color: Colors.greenAccent.shade400, fontSize: 10, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: selectedCount > 0
                            ? () {
                                var selected = paketDocs
                                    .where((doc) => _selectedPackageIds.contains(doc.id))
                                    .map((doc) => {...(doc.data() as Map<String, dynamic>), "id": doc.id})
                                    .toList();

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => KonsolidasiPage(
                                      selectedPaket: selected,
                                      totalBerat: totalBerat,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF427AB5),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFF427AB5).withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Lanjutkan",
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                            const SizedBox(width: 6),
                             Icon(Icons.arrow_forward_rounded, size: 16, color: selectedCount > 0 ? Colors.white : Colors.white.withOpacity(0.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

