import 'package:cloud_firestore/cloud_firestore.dart';

class BiayaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔥 Update Master Biaya (With History)
  Future<void> updateMasterBiaya(Map<String, dynamic> data) async {
    try {
      // 1. Ambil data lama untuk diarsipkan
      final doc = await _firestore.collection('settings').doc('biaya').get();
      if (doc.exists) {
        final oldData = doc.data() as Map<String, dynamic>;
        await _firestore.collection('biaya_history').add({
          ...oldData,
          "archivedAt": FieldValue.serverTimestamp(),
        });
      }

      // 2. Simpan data baru
      await _firestore.collection('settings').doc('biaya').set({
        ...data,
        "updatedAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error updating biaya: $e");
      rethrow;
    }
  }

  // 🔥 Get Biaya History Stream
  Stream<QuerySnapshot> getBiayaHistoryStream() {
    return _firestore
        .collection('biaya_history')
        .orderBy('archivedAt', descending: true)
        .snapshots();
  }

  // 🔥 Update Metode Pembayaran
  Future<void> updatePaymentMethod(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('settings').doc('payment').set({
        ...data,
        "updatedAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error updating payment: $e");
      rethrow;
    }
  }

  // 🔥 Get Master Biaya Stream
  Stream<DocumentSnapshot> getMasterBiayaStream() {
    return _firestore.collection('settings').doc('biaya').snapshots();
  }

  // 🔥 Get Payment Method Stream
  Stream<DocumentSnapshot> getPaymentMethodStream() {
    return _firestore.collection('settings').doc('payment').snapshots();
  }
}
