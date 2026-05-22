import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';
import 'invoice_page.dart';

class RiwayatPage extends StatelessWidget {
  const RiwayatPage({super.key});

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
          return data["status"] == "Selesai";
        }).toList();

        if (orders.isEmpty) {
          return const Center(child: Text("Belum ada riwayat pesanan"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            var doc = orders[index];
            var o = doc.data() as Map<String, dynamic>;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InvoicePage(
                      paket: o["paket"],
                      tipe: o["tipe"],
                      total: (o["total"] ?? 0).toInt(),
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 📦 ICON
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF4FF),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.inventory, size: 35),
                    ),
                    const SizedBox(width: 20),
                    // 📄 INFO
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o["nama"] ?? "No Name",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Sistem: ${o["resi"] ?? "No Resi"}",
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          if (o["resiPengiriman"] != null && o["resiPengiriman"].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "Kurir: ${o["resiPengiriman"]}",
                                style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // 📊 STATUS
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          o["status"] ?? "",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Rp${o["total"]}",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
