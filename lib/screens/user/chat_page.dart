import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      body: Column(
        children: [
          // 🔵 HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.blue, width: 2)),
            ),
            child: Row(
              children: [
                // 🔙 BACK
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),

                const CircleAvatar(radius: 18),

                const SizedBox(width: 10),

                const Text(
                  "Satu Paket",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // 💬 CHAT BODY
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: const [
                chatBubble("Halo kak, paket saya sudah sampai?", false),
                SizedBox(height: 15),
                chatBubble("Sudah ya kak, silakan dicek 🙏", true),
                SizedBox(height: 15),
                chatBubble("Baik, terima kasih!", false),
              ],
            ),
          ),

          // ✏️ INPUT
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Ketik pesan...",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 🔹 CHAT BUBBLE
class chatBubble extends StatelessWidget {
  final String text;
  final bool isMe;

  const chatBubble(this.text, this.isMe, {super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue.shade100 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(text),
      ),
    );
  }
}
