import 'package:cloud_firestore/cloud_firestore.dart';

class WarehouseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔥 Tambah Alamat Gudang (Admin)
  Future<void> addWarehouse(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('warehouse_addresses').add({
        ...data,
        "createdAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error adding warehouse: $e");
      rethrow;
    }
  }

  // 🔥 Update Alamat Gudang
  Future<void> updateWarehouse(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('warehouse_addresses').doc(id).update(data);
    } catch (e) {
      print("Error updating warehouse: $e");
      rethrow;
    }
  }

  // 🔥 Get Warehouse Stream
  Stream<QuerySnapshot> getWarehouseStream() {
    return _firestore.collection('warehouse_addresses').snapshots();
  }

  // 🔥 Hapus Alamat Gudang
  Future<void> deleteWarehouse(String id) async {
    try {
      await _firestore.collection('warehouse_addresses').doc(id).delete();
    } catch (e) {
      print("Error deleting warehouse: $e");
      rethrow;
    }
  }
}
