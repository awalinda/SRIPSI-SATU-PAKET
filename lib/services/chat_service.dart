import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  static final _firestore = FirebaseFirestore.instance;

  /// Mendapatkan atau membuat chatRoom antara user dan admin
  /// chatRoomId = "chat_{userId}" agar 1 user = 1 room dengan admin
  static String getChatRoomId(String userId) => "chat_$userId";

  /// Kirim pesan
  static Future<void> kirimPesan({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required String senderRole, // "admin" atau "user"
    required String text,
  }) async {
    // Simpan pesan ke sub-koleksi "messages"
    await _firestore
        .collection("chatRooms")
        .doc(chatRoomId)
        .collection("messages")
        .add({
      "senderId": senderId,
      "senderName": senderName,
      "senderRole": senderRole,
      "text": text,
      "timestamp": FieldValue.serverTimestamp(),
    });

    // Update metadata chatRoom (untuk list chat)
    final updateData = {
      "lastMessage": text,
      "lastTimestamp": FieldValue.serverTimestamp(),
      "lastSenderRole": senderRole,
      "userId": chatRoomId.replaceFirst("chat_", ""),
      "userName": senderRole == "user" ? senderName : null,
    };

    // Increment unread untuk Admin jika pengirim adalah USER
    if (senderRole == "user") {
      updateData["unreadCountAdmin"] = FieldValue.increment(1);
    }

    await _firestore.collection("chatRooms").doc(chatRoomId).set(updateData, SetOptions(merge: true));
  }

  /// Tandai pesan sudah dibaca oleh admin
  static Future<void> markAsReadAdmin(String chatRoomId) async {
    await _firestore.collection("chatRooms").doc(chatRoomId).update({
      "unreadCountAdmin": 0,
    });
  }

  /// Stream semua pesan dalam 1 chatRoom (untuk detail chat)
  static Stream<QuerySnapshot> getMessagesStream(String chatRoomId) {
    return _firestore
        .collection("chatRooms")
        .doc(chatRoomId)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  /// Stream semua chatRoom (untuk Admin melihat daftar semua user)
  static Stream<QuerySnapshot> getAllChatRoomsStream() {
    return _firestore
        .collection("chatRooms")
        .orderBy("lastTimestamp", descending: true)
        .snapshots();
  }

  /// Hapus satu chat room (seluruh percakapan)
  static Future<void> deleteChatRoom(String chatRoomId) async {
    // 1. Hapus semua pesan di subcollection
    final messages = await _firestore
        .collection("chatRooms")
        .doc(chatRoomId)
        .collection("messages")
        .get();
    
    for (var doc in messages.docs) {
      await doc.reference.delete();
    }

    // 2. Hapus dokumen chat room itu sendiri
    await _firestore.collection("chatRooms").doc(chatRoomId).delete();
  }

  /// Hapus satu pesan spesifik
  static Future<void> deleteMessage(String chatRoomId, String messageId) async {
    await _firestore
        .collection("chatRooms")
        .doc(chatRoomId)
        .collection("messages")
        .doc(messageId)
        .delete();
  }
}
