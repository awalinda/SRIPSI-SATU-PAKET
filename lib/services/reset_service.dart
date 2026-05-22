import 'package:cloud_firestore/cloud_firestore.dart';

class ResetService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> clearAllData() async {
    // List of top-level collections to clear entirely
    final collections = [
      'orders',
      'packages_admin',
      'pengiriman',
      'chatRooms',
      'reports',
      'biaya_history',
    ];

    for (var collectionName in collections) {
      await _deleteCollection(collectionName);
    }

    // Special handling for users: Clear subcollections but keep user docs if they are active users?
    // Or just delete all users except admin.
    // For now, let's clear the subcollections for all users.
    final usersSnapshot = await _firestore.collection('user').get();
    for (var userDoc in usersSnapshot.docs) {
      // Clear subcollections
      await _deleteSubcollection(userDoc.reference, 'packages');
      await _deleteSubcollection(userDoc.reference, 'notifications');
      
      // Optionally delete the user if they are not admin
      final data = userDoc.data();
      if (data['role'] != 'admin') {
        await userDoc.reference.delete();
      }
    }

    print("DEBUG: All activity data has been cleared.");
  }

  static Future<void> _deleteCollection(String path) async {
    final snapshot = await _firestore.collection(path).get();
    for (var doc in snapshot.docs) {
      // Check for subcollections (like chatRooms/messages)
      if (path == 'chatRooms') {
        await _deleteSubcollection(doc.reference, 'messages');
      }
      await doc.reference.delete();
    }
  }

  static Future<void> _deleteSubcollection(DocumentReference parent, String subName) async {
    final snapshot = await parent.collection(subName).get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
