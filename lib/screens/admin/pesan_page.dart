import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/chat_service.dart';
import '../../widgets/custom_notification.dart';
import '../../services/auth_service.dart';

class PesanPage extends StatefulWidget {
  const PesanPage({super.key});

  @override
  State<PesanPage> createState() => _PesanPageState();
}

class _PesanPageState extends State<PesanPage> {
  String? selectedChatRoomId;
  String? selectedUserName;
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool get isMobile => MediaQuery.of(context).size.width < 800;

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 900),
        child: Padding(
          padding: EdgeInsets.fromLTRB(isMobile ? 5 : 20, 10, isMobile ? 5 : 20, isMobile ? 5 : 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isMobile ? 0 : 15),
            ),
            child: selectedChatRoomId == null
                ? _buildChatList()
                : _buildChatDetail(),
          ),
        ),
      ),
    );
  }

  // ================= LIST CHAT (ADMIN SEES ALL USERS) =================
  Widget _buildChatList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            "Pesan",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: ChatService.getAllChatRoomsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final rooms = snapshot.data?.docs ?? [];

              if (rooms.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 10),
                      Text("Belum ada percakapan", style: TextStyle(color: Colors.grey.shade400)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: rooms.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.grey.shade200,
                  indent: 70,
                ),
                  itemBuilder: (context, index) {
                    final data = rooms[index].data() as Map<String, dynamic>;
                    final roomId = rooms[index].id;
                    final userName = data["userName"] ?? "User";
                    final lastMsg = data["lastMessage"] ?? "";
                    final ts = data["lastTimestamp"] as Timestamp?;
                    final unreadCount = data["unreadCountAdmin"] ?? 0;
                    final timeStr = ts != null
                        ? DateFormat('HH:mm').format(ts.toDate())
                        : "";

                    return InkWell(
                      hoverColor: Colors.grey.withOpacity(0.05),
                      onTap: () {
                        // Mark as Read when opened
                        ChatService.markAsReadAdmin(roomId);
                        setState(() {
                          selectedChatRoomId = roomId;
                          selectedUserName = userName;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _UserAvatar(userId: data["userId"], radius: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text(
                                    lastMsg,
                                    style: TextStyle(
                                      color: unreadCount > 0 ? Colors.black : Colors.grey.shade600, 
                                      fontSize: 13,
                                      fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    fontSize: 11, 
                                    color: unreadCount > 0 ? const Color(0xFF427AB5) : Colors.grey.shade500,
                                    fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal
                                  ),
                                ),
                                const SizedBox(height: 5),
                                if (unreadCount > 0)
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      "$unreadCount",
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            // 🔥 DELETE BUTTON
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              onPressed: () => _confirmDeleteChat(roomId, userName),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
              );
            },
          ),
        ),
      ],
    );
  }

  // ================= DETAIL CHAT =================
  Widget _buildChatDetail() {
    final adminUid = AuthService().currentUser?.uid ?? "";

    return Column(
      children: [
        // HEADER
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black12)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    selectedChatRoomId = null;
                    selectedUserName = null;
                  });
                },
                icon: const Icon(Icons.arrow_back),
              ),
              _UserAvatar(userId: selectedChatRoomId?.split("_").firstWhere((id) => id != AuthService().currentUser?.uid, orElse: () => ""), radius: 20),
              const SizedBox(width: 10),
              Text(
                selectedUserName ?? "User",
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
            ],
          ),
        ),

        // MESSAGES
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: ChatService.getMessagesStream(selectedChatRoomId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = snapshot.data?.docs ?? [];

              if (messages.isEmpty) {
                return Center(
                  child: Text("Belum ada pesan", style: TextStyle(color: Colors.grey.shade400)),
                );
              }

              _scrollToBottom();

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index].data() as Map<String, dynamic>;
                  final isMe = msg["senderRole"] == "admin";
                  final ts = msg["timestamp"] as Timestamp?;
                  final timeStr = ts != null
                      ? DateFormat('HH:mm').format(ts.toDate())
                      : "";

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        Container(
                          constraints: const BoxConstraints(maxWidth: 350),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe
                                ? const Color(0xFF427AB5).withOpacity(0.3)
                                : const Color(0xffE5E7EB),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(msg["text"] ?? ""),
                              const SizedBox(height: 4),
                              Text(timeStr, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),

        // INPUT
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.black12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xffF1F3F6),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    controller: _msgController,
                    decoration: const InputDecoration(
                      hintText: "Ketik pesan...",
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(adminUid),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _sendMessage(adminUid),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF427AB5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  void _sendMessage(String adminUid) async {
    final text = _msgController.text.trim();
    if (text.isEmpty || selectedChatRoomId == null) return;

    _msgController.clear();

    await ChatService.kirimPesan(
      chatRoomId: selectedChatRoomId!,
      senderId: adminUid,
      senderName: "Admin",
      senderRole: "admin",
      text: text,
    );
  }

  void _confirmDeleteChat(String roomId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text("Hapus Pesan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "Apakah Anda yakin ingin menghapus seluruh percakapan dengan $userName? Tindakan ini tidak dapat dibatalkan.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await ChatService.deleteChatRoom(roomId);
              CustomNotification.showInfo(context, "Percakapan dengan $userName telah dihapus");
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }
}

// 🔥 WIDGET AVATAR USER DENGAN FETCH FIREBASE
class _UserAvatar extends StatelessWidget {
  final String? userId;
  final double radius;
  const _UserAvatar({this.userId, required this.radius});

  @override
  Widget build(BuildContext context) {
    if (userId == null || userId!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF427AB5),
        child: Icon(Icons.person, color: Colors.white, size: radius),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('user').doc(userId).get(),
      builder: (context, snapshot) {
        String? profileUrl;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          profileUrl = data?["profileUrl"];
        }

        return CircleAvatar(
          radius: radius,
          backgroundColor: const Color(0xFF427AB5).withOpacity(0.1),
          backgroundImage: (profileUrl != null && profileUrl.isNotEmpty)
              ? NetworkImage(profileUrl)
              : null,
          child: (profileUrl == null || profileUrl.isEmpty)
              ? Icon(Icons.person, color: const Color(0xFF427AB5), size: radius)
              : null,
        );
      },
    );
  }
}
