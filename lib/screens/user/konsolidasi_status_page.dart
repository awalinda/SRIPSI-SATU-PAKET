import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_notification.dart';
import 'invoice_page.dart';

class KonsolidasiStatusPage extends StatefulWidget {
  const KonsolidasiStatusPage({super.key});

  @override
  State<KonsolidasiStatusPage> createState() => _KonsolidasiStatusPageState();
}

class _KonsolidasiStatusPageState extends State<KonsolidasiStatusPage> {
  void _showReviewDialog(BuildContext context, String orderId) {
    double rating = 0.0;
    TextEditingController reviewController = TextEditingController();
    bool isSubmitting = false;
    String? base64Image;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              Future<void> pickImage() async {
                try {
                  final picker = ImagePicker();
                  final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 800, maxHeight: 800);
                  if (img != null) {
                    final bytes = await img.readAsBytes();
                    setStateDialog(() => base64Image = base64Encode(bytes));
                  }
                } catch (e) {
                  debugPrint("Error picking image: $e");
                }
              }

              return Container(
                width: 450,
                padding: const EdgeInsets.all(25),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Beri Ulasan",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Bagaimana pengalaman Anda dengan layanan kami?",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () {
                              setStateDialog(() {
                                rating = index + 1.0;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              child: Icon(
                                index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                                color: Colors.amber,
                                size: 40,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: reviewController,
                        decoration: InputDecoration(
                          hintText: "Tulis komentar Anda (opsional)...",
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: Color(0xFF427AB5)),
                          ),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.grey.shade300, width: 1.5),
                          ),
                          child: base64Image != null
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(13),
                                      child: Image.memory(
                                        base64Decode(base64Image!),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () => setStateDialog(() => base64Image = null),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.6),
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(6),
                                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                                        ),
                                      ),
                                    )
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_rounded, color: Colors.grey.shade400, size: 35),
                                    const SizedBox(height: 10),
                                    Text("Tambah Foto (Opsional)", style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: isSubmitting ? null : () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: const Text("Batal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (rating == 0.0) {
                                      CustomNotification.showError(context, "Silakan pilih bintang terlebih dahulu!");
                                      return;
                                    }
                                    setStateDialog(() => isSubmitting = true);
                                    try {
                                      await OrderService.submitReview(orderId, rating, reviewController.text, reviewImageBase64: base64Image);
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
                              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: isSubmitting
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text("Kirim Ulasan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          ),
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
          return data["status"] != "Selesai" || data["rating"] == null;
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
                          color: (o["status"] == "Selesai")
                            ? Colors.green.withOpacity(0.1)
                            : (o["status"] == "Diproses") 
                              ? Colors.orange.withOpacity(0.1) 
                              : (o["status"] == "Dikirim") 
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (o["status"] == "Selesai")
                                ? Icons.check_circle_outline
                                : (o["status"] == "Diproses") 
                                  ? Icons.access_time_rounded 
                                  : (o["status"] == "Dikirim")
                                    ? Icons.local_shipping_rounded
                                    : Icons.info_outline_rounded,
                              size: 14,
                              color: (o["status"] == "Selesai")
                                ? Colors.green
                                : (o["status"] == "Diproses") 
                                  ? Colors.orange 
                                  : (o["status"] == "Dikirim")
                                    ? Colors.blue
                                    : Colors.blue,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              o["status"] ?? "",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                color: (o["status"] == "Selesai")
                                  ? Colors.green
                                  : (o["status"] == "Diproses") 
                                    ? Colors.orange 
                                    : (o["status"] == "Dikirim")
                                      ? Colors.blue
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
                                    paket: o["paket"] is List ? List<dynamic>.from(o["paket"]) : [],
                                    tipe: o["tipe"]?.toString() ?? "-",
                                    total: (o["total"] ?? 0).toInt(),
                                    rating: (o["rating"] as num?)?.toDouble(),
                                    reviewText: o["reviewText"]?.toString(),
                                    reviewImageBase64: o["reviewImageBase64"]?.toString(),
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
                          // ✅ SELESAI / BERI ULASAN
                          if (o["status"] == "Selesai" && o["rating"] == null)
                            ElevatedButton(
                              onPressed: () => _showReviewDialog(context, orderId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade50,
                                foregroundColor: Colors.orange.shade800,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.orange.shade200)),
                              ),
                              child: const Text("Beri Ulasan", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                            )
                          else
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
                                        // Update status ke Firestore tanpa await agar tidak terblokir
                                        OrderService.updateOrderStatus(orderId, "Selesai");
                                        // Langsung munculkan pop-up ulasan secara sinkron (seketika)
                                        _showReviewDialog(context, orderId);
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
