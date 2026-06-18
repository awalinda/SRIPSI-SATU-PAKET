import 'package:cloud_firestore/cloud_firestore.dart';

class LayananService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _docId = 'layanan_tambahan'; // Disimpan dalam collection 'settings' agar tidak terkena permission-denied rules

  // Mendapatkan stream daftar layanan
  Stream<DocumentSnapshot> getLayananStream() {
    return _firestore.collection('settings').doc(_docId).snapshots();
  }

  // Tambah layanan baru
  Future<void> addLayanan(Map<String, dynamic> data) async {
    final doc = await _firestore.collection('settings').doc(_docId).get();
    List<dynamic> layanan = [];
    if (doc.exists && doc.data()!.containsKey('items')) {
      layanan = List.from(doc.data()!['items']);
    }
    
    // Gunakan timestamp sebagai ID
    data['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    layanan.add(data);
    
    await _firestore.collection('settings').doc(_docId).set({
      'items': layanan,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Edit layanan
  Future<void> updateLayanan(String id, Map<String, dynamic> data) async {
    final doc = await _firestore.collection('settings').doc(_docId).get();
    if (!doc.exists) return;
    
    List<dynamic> layanan = List.from(doc.data()!['items'] ?? []);
    int index = layanan.indexWhere((item) => item['id'] == id);
    if (index != -1) {
      data['id'] = id; // keep id
      layanan[index] = data;
      await _firestore.collection('settings').doc(_docId).update({
        'items': layanan,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Hapus layanan
  Future<void> deleteLayanan(String id) async {
    final doc = await _firestore.collection('settings').doc(_docId).get();
    if (!doc.exists) return;
    
    List<dynamic> layanan = List.from(doc.data()!['items'] ?? []);
    layanan.removeWhere((item) => item['id'] == id);
    
    await _firestore.collection('settings').doc(_docId).update({
      'items': layanan,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Seed data awal jika kosong (Dipanggil saat halaman manajemen layanan admin dibuka)
  Future<void> seedLayananAwal() async {
    try {
      final doc = await _firestore.collection('settings').doc(_docId).get();
      if (!doc.exists || (doc.data() != null && (doc.data()!['items'] == null || (doc.data()!['items'] as List).isEmpty))) {
        await _firestore.collection('settings').doc(_docId).set({
          'items': [
            {
              "id": DateTime.now().millisecondsSinceEpoch.toString() + "1",
              "label": "Minta foto lebih detail (kanan, kiri, depan, belakang)",
              "biaya": 2000,
            },
            {
              "id": DateTime.now().millisecondsSinceEpoch.toString() + "2",
              "label": "Unboxing paket",
              "biaya": 3000,
            }
          ],
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("Gagal seed layanan awal: $e");
    }
  }
}
