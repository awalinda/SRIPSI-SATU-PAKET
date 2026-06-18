import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class OrderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔥 Simpan ke Firestore
  static Future<void> tambahOrder(Map<String, dynamic> order) async {
    try {
      await _firestore.collection('orders').add({
        ...order,
        "createdAt": FieldValue.serverTimestamp(),
      });
      
      // 🔥 TRIGGER NOTIFICATION
      await NotificationService.notifyCheckout(
        order["userId"], 
        order["resi"] ?? "Order", 
        "Rp${order["total"]}"
      );
    } catch (e) {
      print("Error adding order: $e");
      rethrow;
    }
  }

  // 🔥 Get Stream Orders (Optional for tracking)
  static Stream<QuerySnapshot> getOrdersStream(String uid) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .snapshots();
  }

  static Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        "status": status,
        "isUpdatedByAdmin": true,
      });

      if (status == "Selesai") {
        // Sync ke pengiriman
        final doc = await _firestore.collection('orders').doc(orderId).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          String resiOrder = data["resi"] ?? "";
          if (resiOrder.isNotEmpty) {
             final pengirimanQuery = await _firestore.collection('pengiriman').where('resiAsal', isEqualTo: resiOrder).get();
             for (var p in pengirimanQuery.docs) {
               await p.reference.update({"status": "Selesai"});
             }
          }
        }
      }

      // 🔥 TRIGGER NOTIFICATION
      if (status == "Disetujui") {
        final doc = await _firestore.collection('orders').doc(orderId).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          await NotificationService.notifyOrderConfirmed(data["userId"], data["resi"] ?? "Order");
        }
      }
    } catch (e) {
      print("Error updating order: $e");
      rethrow;
    }
  }

  // 🔥 Update Status And Resi
  static Future<void> updateOrderStatusAndResi(String orderId, String status, String resiPengiriman) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        "status": status,
        "resiPengiriman": resiPengiriman,
        "isUpdatedByAdmin": true,
        "dikirimAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error updating order and resi: $e");
      rethrow;
    }
  }

  // 🔥 Get All Orders Stream (Untuk Admin - Konfirmasi Pesanan)
  static Stream<QuerySnapshot> getAllOrdersStream() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 🔥 Buat Pengiriman (Barang Keluar)
  static Future<void> buatPengiriman(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('pengiriman').add({
        ...data,
        "createdAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error creating pengiriman: $e");
      rethrow;
    }
  }

  // 🔥 Auto Selesai Setelah 3 Hari
  static Future<void> checkAndAutoUpdateSelesai() async {
    try {
      final now = DateTime.now();
      final orders = await _firestore.collection('orders').where('status', isEqualTo: 'Dikirim').get();
      for (var doc in orders.docs) {
        final data = doc.data();
        DateTime dateToCheck = now;
        if (data.containsKey('dikirimAt') && data['dikirimAt'] != null) {
          dateToCheck = (data['dikirimAt'] as Timestamp).toDate();
        } else if (data['createdAt'] != null) {
          dateToCheck = (data['createdAt'] as Timestamp).toDate();
        }

        if (now.difference(dateToCheck).inDays >= 3) {
           await updateOrderStatus(doc.id, "Selesai");
        }
      }
    } catch (e) {
      print("Auto-update failed: $e");
    }
  }

  // 🔥 Get All Pengiriman Stream (Untuk Admin - Barang Keluar)
  static Stream<QuerySnapshot> getPengirimanStream() {
    return _firestore
        .collection('pengiriman')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 🔥 Logika Perhitungan Biaya JNE
  static double hitungBiayaJNE({
    required double beratGram,
    required double p,
    required double l,
    required double t,
    double tarifPerKg = 13000, // Tarif minimal per kg diubah ke 13.000
  }) {
    // 1. Berat Aktual (KG)
    double beratAktualKg = beratGram / 1000;
    
    // 2. Berat Volume (KG) - Menggunakan pembagi 6000 (Standar)
    double beratVolumeKg = (p * l * t) / 4000;
    
    // 3. Ambil yang terbesar
    double beratFinal = beratAktualKg > beratVolumeKg ? beratAktualKg : beratVolumeKg;
    
    // 4. Pembulatan JNE:
    // 0.1 - 1.29 kg = 1 kg
    // 1.3 - 2.29 kg = 2 kg
    // Rumus: floor(berat + 0.7)
    int beratBulat = (beratFinal + 0.7).floor();
    if (beratBulat < 1) beratBulat = 1; // Minimal 1 kg
    
    return beratBulat * tarifPerKg;
  }

  // 🔥 Submit Ulasan
  static Future<void> submitReview(String orderId, double rating, String reviewText, {String? reviewImageBase64}) async {
    try {
      Map<String, dynamic> updateData = {
        "rating": rating,
        "reviewText": reviewText,
        "reviewDate": FieldValue.serverTimestamp(),
      };
      if (reviewImageBase64 != null) {
        updateData["reviewImageBase64"] = reviewImageBase64;
      }

      await _firestore.collection('orders').doc(orderId).update(updateData);

      // Sync ke pengiriman agar admin bisa melihat
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        String resiOrder = data["resi"] ?? "";
        if (resiOrder.isNotEmpty) {
           final pengirimanQuery = await _firestore.collection('pengiriman').where('resiAsal', isEqualTo: resiOrder).get();
           for (var p in pengirimanQuery.docs) {
             await p.reference.update(updateData);
           }
        }
      }
    } catch (e) {
      print("Error submitting review: $e");
      rethrow;
    }
  }
}
