import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';
import 'invoice_page.dart';

import '../../widgets/custom_notification.dart';

class RiwayatPage extends StatelessWidget {
  const RiwayatPage({super.key});

  void _showReviewDialog(BuildContext context, String orderId) {
    double rating = 5.0;
    TextEditingController reviewController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Beri Ulasan", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Bagaimana pengalaman Anda dengan layanan kami?"),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            rating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: reviewController,
                    decoration: InputDecoration(
                      hintText: "Tulis komentar Anda (opsional)...",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text("Batal", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setStateDialog(() => isSubmitting = true);
                          try {
                            await OrderService.submitReview(orderId, rating, reviewController.text);
                            if (context.mounted) {
                              Navigator.pop(context);
                              CustomNotification.showSuccess(context, "Terima kasih atas ulasan Anda!");
                            }
                          } catch (e) {
                            if (context.mounted) {
                              CustomNotification.showError(context, "Gagal mengirim ulasan");
                              setStateDialog(() => isSubmitting = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF427AB5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Kirim", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

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
                        const SizedBox(height: 8),
                        if (o["rating"] == null)
                          ElevatedButton(
                            onPressed: () => _showReviewDialog(context, doc.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade50,
                              foregroundColor: Colors.orange.shade800,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.orange.shade200)),
                            ),
                            child: const Text("Beri Ulasan", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        else
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < (o["rating"] as num).toInt() ? Icons.star_rounded : Icons.star_border_rounded,
                                color: Colors.amber,
                                size: 16,
                              );
                            }),
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
