import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔥 SEND EMAIL NOTIFICATION (Logic Placeholder)
  static Future<void> sendEmailNotification({
    required String recipientEmail,
    required String subject,
    required String body,
  }) async {
    try {
      await _firestore.collection('mail_logs').add({
        "to": recipientEmail,
        "subject": subject,
        "body": body,
        "status": "sent_queued", 
        "timestamp": FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print("--- EMAIL NOTIFICATION SENT ---");
        print("To: $recipientEmail");
        print("Subject: $subject");
        print("-------------------------------");
      }
    } catch (e) {
      print("Error sending notification: $e");
    }
  }

  // 🔥 SEND INTERNAL NOTIFICATION
  static Future<void> sendInternalNotification({
    required String uid,
    required String title,
    required String body,
    String? type,
  }) async {
    try {
      await _firestore.collection('user').doc(uid).collection('notifications').add({
        "title": title,
        "body": body,
        "type": type,
        "isRead": false,
        "timestamp": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error sending internal notification: $e");
    }
  }

  // 🔥 Notify when package arrives at warehouse
  static Future<void> notifyNewPackage(String uid, String resi, String namaBarang) async {
    final userDoc = await _firestore.collection('user').doc(uid).get();
    if (!userDoc.exists) return;
    
    final email = userDoc.get('email');
    final name = userDoc.get('name') ?? 'Pengguna';

    // 1. Email
    if (email != null) {
      await sendEmailNotification(
        recipientEmail: email,
        subject: "📦 Paket Baru Tiba di Gudang - $resi",
        body: "Halo $name,\n\nPaket Anda ($namaBarang) telah kami terima di gudang. Silakan cek menu 'Paket Saya'.",
      );
    }

    // 2. Internal
    await sendInternalNotification(
      uid: uid,
      title: "Paket Baru Diterima",
      body: "Paket $namaBarang ($resi) telah tiba di gudang kami.",
      type: "package",
    );
  }

  // 🔥 Notify when user checks out (Checkout)
  static Future<void> notifyCheckout(String uid, String orderId, String total) async {
    final userDoc = await _firestore.collection('user').doc(uid).get();
    if (!userDoc.exists) return;
    
    final email = userDoc.get('email');
    final name = userDoc.get('name') ?? 'Pengguna';

    // 1. Email
    if (email != null) {
      await sendEmailNotification(
        recipientEmail: email,
        subject: "🛒 Checkout Berhasil - $orderId",
        body: "Halo $name,\n\nCheckout Anda berhasil. Total: $total. Tunggu konfirmasi admin.",
      );
    }

    // 2. Internal
    await sendInternalNotification(
      uid: uid,
      title: "Checkout Berhasil",
      body: "Pesanan $orderId telah dibuat. Silakan tunggu konfirmasi admin.",
      type: "order",
    );
  }

  // 🔥 Notify when order is confirmed (Disetujui)
  static Future<void> notifyOrderConfirmed(String uid, String orderResi) async {
    final userDoc = await _firestore.collection('user').doc(uid).get();
    if (!userDoc.exists) return;
    
    final email = userDoc.get('email');
    final name = userDoc.get('name') ?? 'Pengguna';

    if (email != null) {
      await sendEmailNotification(
        recipientEmail: email,
        subject: "✅ Pesanan Disetujui - $orderResi",
        body: "Halo $name,\n\nPesanan konsolidasi Anda ($orderResi) telah disetujui.",
      );
    }

    await sendInternalNotification(
      uid: uid,
      title: "Pesanan Disetujui",
      body: "Pesanan $orderResi telah disetujui oleh admin.",
      type: "order",
    );
  }

  // 🔥 Notify when order is shipped (Dikirim)
  static Future<void> notifyOrderShipped(String uid, String resiBaru) async {
    final userDoc = await _firestore.collection('user').doc(uid).get();
    if (!userDoc.exists) return;
    
    final email = userDoc.get('email');
    final name = userDoc.get('name') ?? 'Pengguna';

    if (email != null) {
      await sendEmailNotification(
        recipientEmail: email,
        subject: "🚚 Pesanan Telah Dikirim! - $resiBaru",
        body: "Halo $name,\n\nPesanan Anda telah dikirim dengan resi: $resiBaru.",
      );
    }

    await sendInternalNotification(
      uid: uid,
      title: "Pesanan Dikirim",
      body: "Pesanan Anda sedang dalam perjalanan. Resi: $resiBaru.",
      type: "shipping",
    );
  }

  // 🔥 Notify when package data is updated by admin (e.g. after rejection)
  static Future<void> notifyPackageUpdated(String uid, String resi, String namaBarang) async {
    final userDoc = await _firestore.collection('user').doc(uid).get();
    if (!userDoc.exists) return;
    
    final email = userDoc.get('email');
    final name = userDoc.get('name') ?? 'Pengguna';

    // 1. Email
    if (email != null) {
      await sendEmailNotification(
        recipientEmail: email,
        subject: "🔄 Pembaruan Data Paket - $resi",
        body: "Halo $name,\n\nData paket Anda ($namaBarang) dengan resi $resi telah diperbarui oleh admin. Silakan periksa kembali dan lakukan konfirmasi (Terima/Tolak).",
      );
    }

    // 2. Internal
    await sendInternalNotification(
      uid: uid,
      title: "Pembaruan Data Paket",
      body: "Data paket $namaBarang ($resi) telah diperbarui admin. Silakan konfirmasi.",
      type: "package",
    );
  }
}
