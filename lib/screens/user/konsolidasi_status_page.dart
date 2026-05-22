import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';
import 'invoice_page.dart';

class KonsolidasiStatusPage extends StatefulWidget {
  const KonsolidasiStatusPage({super.key});

  @override
  State<KonsolidasiStatusPage> createState() => _KonsolidasiStatusPageState();
}

class _KonsolidasiStatusPageState extends State<KonsolidasiStatusPage> {
  @override
  Widget build(BuildContext context) {
    final String? uid = AuthService().currentUser?.uid;

    if (uid == null) {
      return const Center(child: Text("Silakan login terlebih dahulu"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: OrderService.getOrdersStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final allOrders = snapshot.data?.docs ?? [];
        
        // 🔥 Sort Client-side untuk menghindari Index error
        List<QueryDocumentSnapshot> sortedOrders = List.from(allOrders);
        sortedOrders.sort((a, b) {
          var da = a.data() as Map<String, dynamic>;
          var db = b.data() as Map<String, dynamic>;
          var ta = da["createdAt"] as Timestamp?;
          var tb = db["createdAt"] as Timestamp?;
          if (ta == null) return 1;
          if (tb == null) return -1;
          return tb.compareTo(ta);
        });

        final orders = sortedOrders.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data["status"] != "Selesai";
        }).toList();

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade200),
                const SizedBox(height: 16),
                Text(
                  "Belum ada pesanan aktif",
                  style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          physics: const BouncingScrollPhysics(),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            var doc = orders[index];
            var o = doc.data() as Map<String, dynamic>;
            String orderId = doc.id;
            bool isProcessing = o["status"] == "Diproses";
            bool isWaiting = o["status"] == "Menunggu Konfirmasi";
            bool isShipped = o["status"] == "Dikirim";
            bool hasResi = o["resiPengiriman"] != null && o["resiPengiriman"].toString().isNotEmpty;
            
            // 🔥 Tombol SELESAI aktif jika status sudah DIKIRIM dan ada RESI
            bool canComplete = isShipped && hasResi;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF427AB5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF427AB5), size: 24),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o["nama"] ?? "No Name",
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1A1A1A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Sistem: ${o["resi"] ?? "No Resi"}",
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                            if (o["resiPengiriman"] != null && o["resiPengiriman"].toString().isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: Text(
                                  "Kurir: ${o["resiPengiriman"]}",
                                  style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (o["status"] == "Diproses") 
                            ? Colors.orange.withOpacity(0.1) 
                            : (o["status"] == "Dikirim") 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (o["status"] == "Diproses") 
                                ? Icons.access_time_rounded 
                                : (o["status"] == "Dikirim")
                                  ? Icons.local_shipping_rounded
                                  : Icons.info_outline_rounded,
                              size: 14,
                              color: (o["status"] == "Diproses") 
                                ? Colors.orange 
                                : (o["status"] == "Dikirim")
                                  ? Colors.green
                                  : Colors.blue,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              o["status"] ?? "",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                color: (o["status"] == "Diproses") 
                                  ? Colors.orange 
                                  : (o["status"] == "Dikirim")
                                    ? Colors.green
                                    : Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Divider(height: 1, color: Color(0xFFF0F0F0)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Total Biaya", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(
                            "Rp${o["total"].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}",
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF427AB5)),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // 🔍 DETAIL
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => InvoicePage(
                                    paket: List<Map<String, dynamic>>.from(o["paket"] ?? []),
                                    tipe: o["tipe"] ?? "-",
                                    total: o["total"] ?? 0,
                                  ),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey.shade600,
                              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            child: const Text("Detail"),
                          ),
                          const SizedBox(width: 8),
                          // ✅ SELESAI
                          ElevatedButton(
                            onPressed: !canComplete
                                ? null
                                : () async {
                                    bool confirm = await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("Konfirmasi Selesai"),
                                        content: const Text("Apakah Anda sudah menerima paket ini? Status akan diubah menjadi Selesai."),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Belum")),
                                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Ya, Sudah")),
                                        ],
                                      ),
                                    ) ?? false;

                                    if (confirm) {
                                      await OrderService.updateOrderStatus(orderId, "Selesai");
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF427AB5),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade100,
                              disabledForegroundColor: Colors.grey.shade400,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              "Selesai",
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
