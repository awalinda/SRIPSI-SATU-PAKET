import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class AddressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? uid = AuthService().currentUser?.uid;


  Future<void> addAddress(Map<String, dynamic> addressData) async {
    if (uid == null) return;
    try {
      await _firestore
          .collection('user')
          .doc(uid)
          .collection('addresses')
          .add({
        ...addressData,
        "createdAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error adding address: $e");
      rethrow;
    }
  }

  // 🔥 Update Alamat
  Future<void> updateAddress(String addressId, Map<String, dynamic> addressData) async {
    if (uid == null) return;
    try {
      await _firestore
          .collection('user')
          .doc(uid)
          .collection('addresses')
          .doc(addressId)
          .update(addressData);
    } catch (e) {
      print("Error updating address: $e");
      rethrow;
    }
  }

  // 🔥 Get Alamat Stream
  Stream<QuerySnapshot> getAddresses() {
    return _firestore
        .collection('user')
        .doc(uid)
        .collection('addresses')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 🔥 Hapus Alamat
  Future<void> deleteAddress(String addressId) async {
    if (uid == null) return;
    try {
      await _firestore
          .collection('user')
          .doc(uid)
          .collection('addresses')
          .doc(addressId)
          .delete();
    } catch (e) {
      print("Error deleting address: $e");
      rethrow;
    }
  }

  // 🔥 Set Alamat Utama (Optional for future)
  Future<void> setDefaultAddress(String addressId) async {
    // Logic to set isDefault = true and others to false
  }
}
