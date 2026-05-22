import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) return const Center(child: Text("Silakan login"));

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(25, 30, 25, 20),
            child: Text(
              "Notifikasi",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E3C72),
                letterSpacing: -0.5,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('user')
                  .doc(user.uid)
                  .collection('notifications')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none_rounded, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        Text("Belum ada notifikasi", style: TextStyle(color: Colors.grey.shade400)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isRead = data['isRead'] ?? false;
                    final ts = data['timestamp'] as Timestamp?;
                    final time = ts != null ? DateFormat('dd MMM, HH:mm').format(ts.toDate()) : "";

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isRead ? Colors.transparent : const Color(0xFF427AB5).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isRead ? Colors.grey.shade100 : const Color(0xFF427AB5).withOpacity(0.1)),
                      ),
                      child: ListTile(
                        onTap: () {
                          docs[index].reference.update({'isRead': true});
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _getIconColor(data['type']).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_getIcon(data['type']), color: _getIconColor(data['type']), size: 20),
                        ),
                        title: Text(
                          data['title'] ?? "Notifikasi",
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.w900,
                            color: const Color(0xFF1E3C72),
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              data['body'] ?? "",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(time, style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
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
      ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'package': return Icons.inventory_2_rounded;
      case 'order': return Icons.shopping_cart_rounded;
      case 'shipping': return Icons.local_shipping_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _getIconColor(String? type) {
    switch (type) {
      case 'package': return const Color(0xFF427AB5);
      case 'order': return Colors.orange;
      case 'shipping': return Colors.green;
      default: return Colors.blueGrey;
    }
  }
}
