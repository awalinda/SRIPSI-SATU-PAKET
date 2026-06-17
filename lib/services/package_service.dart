import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'notification_service.dart';

class PackageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔥 Get Packages Stream
  Stream<QuerySnapshot> getPackagesStream(String uid) {
    return _firestore
        .collection('user')
        .doc(uid)
        .collection('packages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 🔥 Delete Multiple Packages
  Future<void> deletePackages(String uid, List<String> packageIds) async {
    final WriteBatch batch = _firestore.batch();
    
    for (String id in packageIds) {
      DocumentReference ref = _firestore
          .collection('user')
          .doc(uid)
          .collection('packages')
          .doc(id);
      batch.delete(ref);
    }
    
    await batch.commit();
  }

  // 🔥 Seed Data (Untuk Demo/Tahap Awal)
  Future<void> seedInitialPackages(String uid) async {
    final packages = [
      {"nama": "Baju", "berat": 0.5, "resi": "SP-001", "date": "12 Jan 2025"},
      {"nama": "Sepatu", "berat": 0.8, "resi": "SP-002", "date": "14 Jan 2025"},
      {"nama": "Tas", "berat": 0.7, "resi": "SP-003", "date": "15 Jan 2025"},
      {"nama": "Buku", "berat": 0.4, "resi": "SP-004", "date": "16 Jan 2025"},
    ];

    final collection = _firestore.collection('user').doc(uid).collection('packages');
    final snapshot = await collection.get();
    
    if (snapshot.docs.isEmpty) {
      for (var p in packages) {
        await collection.add(p);
      }
    }
  }

  // 🔥 SEARCH USERS BY ID CODE (Admin)
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    
    String lowerQuery = query.toLowerCase();
    
    // Untuk hasil terbaik tanpa index eksternal, kita ambil data lalu filter di aplikasi
    // Limit ditingkatkan agar pencarian lebih akurat untuk basis user kecil-menengah
    final snapshot = await _firestore
        .collection('user')
        .limit(100)
        .get();

    return snapshot.docs
        .where((doc) {
          final data = doc.data();
          String name = (data['name'] ?? "").toString().toLowerCase();
          String code = (data['userIdCode'] ?? "").toString().toLowerCase();
          return name.contains(lowerQuery) || code.contains(lowerQuery);
        })
        .map((doc) => {
          "uid": doc.id,
          "name": doc.get('name'),
          "userIdCode": doc.get('userIdCode'),
        })
        .toList();
  }

  // 🔥 ADD INCOMING PACKAGE (Admin)
  Future<void> addIncomingPackage(String userUid, Map<String, dynamic> data) async {
    await _firestore
        .collection('user')
        .doc(userUid)
        .collection('packages')
        .add({
          ...data,
          "status": "Diterima", // Default status saat barang masuk
          "createdAt": FieldValue.serverTimestamp(),
          "isUpdatedByAdmin": true, // Notifikasi untuk user
        });
    
    // 🔥 TRIGGER EMAIL NOTIFICATION
    await NotificationService.notifyNewPackage(userUid, data["resi"] ?? "-", data["nama"] ?? "Barang");
  }

  // 🔥 GET ALL INCOMING PACKAGES FOR ADMIN VIEW (Optional/Demo)
  // Note: For real app, you might want a top-level 'all_packages' collection
  // but for now, we follow the user/{uid}/packages structure.
  // To show 'All' in admin, we would need to query group if supported, 
  // or a separate global collection. Let's use a global collection 'packages_admin'.
  
  Future<void> saveToAdminList(Map<String, dynamic> data) async {
    await _firestore.collection('packages_admin').add({
      ...data,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getAdminPackagesStream() {
    return _firestore.collection('packages_admin').snapshots();
  }

  // 🔥 SEND PACKAGE NOTE (User)
  Future<void> sendPackageNote(String uid, String packageId, String resi, String note) async {
    final batch = _firestore.batch();
    
    DocumentReference userPkgRef = _firestore.collection('user').doc(uid).collection('packages').doc(packageId);
    batch.update(userPkgRef, {"catatanUser": note});

    final adminPkgs = await _firestore.collection('packages_admin')
        .where('resi', isEqualTo: resi)
        .get();
    for (var doc in adminPkgs.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('userId') && data['userId'] != uid) continue;
      batch.update(doc.reference, {
        "catatanUser": note,
        "hasNewNote": true,
      });
    }

    await batch.commit();
  }

  // 🔥 UPDATE PACKAGE IMAGES (Admin)
  Future<void> updatePackageImages(String resi, String? uid, List<String> initialImages, {List<String>? requestedImages, String? requestedVideoUrl, bool isFulfillingRequest = false}) async {
    final batch = _firestore.batch();
    
    final adminPkgs = await _firestore.collection('packages_admin')
        .where('resi', isEqualTo: resi)
        .get();
    for (var doc in adminPkgs.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (uid != null && data.containsKey('userId') && data['userId'] != uid) continue;
      
      Map<String, dynamic> updateData = {
        "images": initialImages, 
      };

      if (isFulfillingRequest && (requestedImages != null || requestedVideoUrl != null)) {
        if (requestedImages != null) updateData["requestedImages"] = requestedImages;
        if (requestedVideoUrl != null) updateData["requestedVideoUrl"] = requestedVideoUrl;
        updateData["catatanUser"] = FieldValue.delete();
      }

      batch.update(doc.reference, updateData);
    }

    if (uid != null) {
      final userPkgs = await _firestore.collection('user').doc(uid).collection('packages').where('resi', isEqualTo: resi).get();
      for (var doc in userPkgs.docs) {
        Map<String, dynamic> updateData = {
          "images": initialImages, 
          "isUpdatedByAdmin": true
        };

        if (isFulfillingRequest && (requestedImages != null || requestedVideoUrl != null)) {
          if (requestedImages != null) updateData["requestedImages"] = requestedImages;
          if (requestedVideoUrl != null) updateData["requestedVideoUrl"] = requestedVideoUrl;
          updateData["catatanUser"] = FieldValue.delete();
        }

        batch.update(doc.reference, updateData);
      }
    }

    await batch.commit();
  }

  // 🔥 CLEAR UPDATE NOTIFICATION (User)
  Future<void> clearUpdateNotification(String uid, String packageId) async {
    await _firestore
        .collection('user')
        .doc(uid)
        .collection('packages')
        .doc(packageId)
        .update({"isUpdatedByAdmin": FieldValue.delete()});
  }

  // 🔥 UPLOAD VIDEO
  Future<String?> uploadVideoToStorage(XFile videoFile) async {
    try {
      String fileName = 'packages/videos/vid_${DateTime.now().millisecondsSinceEpoch}.mp4';
      Reference ref = FirebaseStorage.instance.ref().child(fileName);
      
      if (kIsWeb) {
        final bytes = await videoFile.readAsBytes();
        SettableMetadata metadata = SettableMetadata(contentType: 'video/mp4');
        UploadTask uploadTask = ref.putData(bytes, metadata);
        TaskSnapshot snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      } else {
        File file = File(videoFile.path);
        UploadTask uploadTask = ref.putFile(file);
        TaskSnapshot snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      }
    } catch (e) {
      print("Error uploading video: $e");
      return null;
    }
  }
}
