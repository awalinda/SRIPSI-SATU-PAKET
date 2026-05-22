import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import 'riwayat_page.dart';
import 'privasi_page.dart';
import 'alamat_page.dart';
import 'pesan_page.dart';
import 'paket_page.dart';
import 'konsolidasi_status_page.dart';
import 'profile_page.dart';
import 'notifications_page.dart';
import '../../widgets/custom_notification.dart';

class DashboardUser extends StatefulWidget {
  final int initialIndex;
  const DashboardUser({super.key, this.initialIndex = 0});

  @override
  State<DashboardUser> createState() => _DashboardUserState();
}

class _DashboardUserState extends State<DashboardUser> {
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
  }

  void _clearAdminUpdateFlag(String type, String uid) async {
    if (type == 'packages') {
      var snapshot = await FirebaseFirestore.instance.collection('user').doc(uid).collection('packages').where('isUpdatedByAdmin', isEqualTo: true).get();
      for (var doc in snapshot.docs) {
        doc.reference.update({'isUpdatedByAdmin': FieldValue.delete()});
      }
    } else if (type == 'orders') {
      var snapshot = await FirebaseFirestore.instance.collection('orders').where('userId', isEqualTo: uid).where('isUpdatedByAdmin', isEqualTo: true).get();
      for (var doc in snapshot.docs) {
        doc.reference.update({'isUpdatedByAdmin': FieldValue.delete()});
      }
    }
  }

  final List<Widget> pages = [
    const DashboardContent(),
    const PaketPage(),
    const KonsolidasiStatusPage(),
    const RiwayatPage(),
    const AlamatPage(),
    const PesanPage(),
    const ProfilePage(),
    const NotificationsPage(),
    const PrivasiPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text("SATUPAKET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: const Color(0xFF427AB5),
              iconTheme: const IconThemeData(color: Colors.white),
              elevation: 0,
            ),
      drawer: isDesktop ? null : _buildDrawer(),
      bottomNavigationBar: isDesktop ? null : _buildBottomNav(),
      body: SafeArea(
        bottom: false, // Diganti ke false karena ada BottomNav
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFF0F4F8), // Softer off-white with blue tint to reduce glare
          ),
        child: Padding(
          padding: EdgeInsets.only(
            left: isDesktop ? 20 : 10,
            right: isDesktop ? 20 : 10,
            top: isDesktop ? 20 : 10,
            bottom: isDesktop ? 20 : 0, // No bottom padding on mobile because of BottomNav
          ),
          child: Row(
            children: [
              // ================= SIDEBAR (DESKTOP) =================
              if (isDesktop)
                Container(
                  width: 260,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E3C72).withOpacity(0.06),
                        blurRadius: 40,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 🔥 LOGO SECTION
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF427AB5).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset('lib/assets/images/logo.png', height: 22, fit: BoxFit.contain),
                            const SizedBox(width: 10),
                            const Text(
                              "SATUPAKET",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E3C72),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 50),
                      
                      // 🔥 NAVIGATION MENU
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          children: [
                            menuItem(Icons.dashboard_outlined, Icons.dashboard_rounded, "Dashboard", 0),
                            menuItem(Icons.inventory_2_outlined, Icons.inventory_2_rounded, "Paket Saya", 1),
                            menuItem(Icons.local_shipping_outlined, Icons.local_shipping_rounded, "Konsolidasi", 2),
                            menuItem(Icons.history_outlined, Icons.history_rounded, "Riwayat", 3),
                            menuItem(Icons.map_outlined, Icons.map_rounded, "Alamat", 4),
                            menuItem(Icons.forum_outlined, Icons.forum_rounded, "Pesan", 5),
                            menuItem(Icons.person_outline, Icons.person_rounded, "Profil", 6),
                            menuItem(Icons.notifications_none_rounded, Icons.notifications_rounded, "Notifikasi", 7),
                            menuItem(Icons.privacy_tip_outlined, Icons.privacy_tip_rounded, "Privasi", 8),
                          ],
                        ),
                      ),

                      // 🔥 USER PREVIEW AT BOTTOM
                      const Divider(color: Color(0xFFF0F4F8), indent: 20, endIndent: 20),
                      InkWell(
                        onTap: () {
                          setState(() {
                            selectedIndex = 6;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFF427AB5).withOpacity(0.1),
                                child: const Icon(Icons.person, color: Color(0xFF427AB5), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                      Text(
                                        AuthService().currentUser?.displayName ?? "Pengguna",
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Color(0xFF1E3C72), fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (isDesktop) const SizedBox(width: 20),

              // == MAIN ==
              Expanded(
                child: ClipRRect(
                  borderRadius: isDesktop ? BorderRadius.circular(30) : const BorderRadius.vertical(top: Radius.circular(30)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: isDesktop ? BorderRadius.circular(30) : const BorderRadius.vertical(top: Radius.circular(30)),
                      ),
                      child: pages[selectedIndex],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildBottomNav() {
    // Map selectedIndex ke index BottomNav
    int getBottomIndex() {
      if (selectedIndex == 0) return 0;
      if (selectedIndex == 1) return 1;
      if (selectedIndex == 2) return 2;
      if (selectedIndex == 5) return 3;
      if (selectedIndex == 6) return 4;
      return 0; // Default
    }

    void onNavTap(int index) {
      int targetIndex = 0;
      if (index == 0) targetIndex = 0;
      if (index == 1) targetIndex = 1;
      if (index == 2) targetIndex = 2;
      if (index == 3) targetIndex = 5;
      if (index == 4) targetIndex = 6;
      setState(() => selectedIndex = targetIndex);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: const Color(0xFF1E3C72).withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: getBottomIndex(),
          onTap: onNavTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFF427AB5),
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard_rounded), label: "Beranda"),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2_rounded), label: "Paket"),
            BottomNavigationBarItem(icon: Icon(Icons.local_shipping_outlined), activeIcon: Icon(Icons.local_shipping_rounded), label: "Kirim"),
            BottomNavigationBarItem(icon: Icon(Icons.forum_outlined), activeIcon: Icon(Icons.forum_rounded), label: "Pesan"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person_rounded), label: "Profil"),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF1E3C72),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1E3C72),
              const Color(0xFF6C63FF).withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
          child: Column(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white12))),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('lib/assets/images/logo.png', height: 40, fit: BoxFit.contain),
                    const SizedBox(height: 10),
                    const Text(
                      "SATUPAKET",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(
                    left: 10, 
                    right: 10, 
                    top: 10, 
                    bottom: MediaQuery.of(context).padding.bottom + 20
                  ),
                  children: [
                    menuItem(Icons.dashboard_outlined, Icons.dashboard_rounded, "Dashboard", 0),
                    menuItem(Icons.inventory_2_outlined, Icons.inventory_2_rounded, "Paket Saya", 1),
                    menuItem(Icons.local_shipping_outlined, Icons.local_shipping_rounded, "Konsolidasi", 2),
                    menuItem(Icons.history_outlined, Icons.history_rounded, "Riwayat", 3),
                    menuItem(Icons.map_outlined, Icons.map_rounded, "Alamat", 4),
                    menuItem(Icons.forum_outlined, Icons.forum_rounded, "Pesan", 5),
                    menuItem(Icons.person_outline, Icons.person_rounded, "Profil", 6),
                    menuItem(Icons.notifications_none_rounded, Icons.notifications_rounded, "Notifikasi", 7),
                    menuItem(Icons.privacy_tip_outlined, Icons.privacy_tip_rounded, "Privasi", 8),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget menuItem(IconData icon, IconData activeIcon, String title, int index) {
    bool isSelected = selectedIndex == index;
    final user = AuthService().currentUser;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return StreamBuilder<int>(
      stream: _getBadgeCount(index, user?.uid),
      builder: (context, snapshot) {
        int badgeCount = snapshot.data ?? 0;

        return InkWell(
          onTap: () {
            setState(() {
              selectedIndex = index;
            });
            if (user != null) {
              if (index == 1) _clearAdminUpdateFlag('packages', user.uid);
              if (index == 2) _clearAdminUpdateFlag('orders', user.uid);
              if (index == 7) _clearNotificationBadge(user.uid);
            }
            if (!isDesktop) Navigator.pop(context);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: BoxDecoration(
              color: isSelected ? (isDesktop ? const Color(0xFF427AB5).withOpacity(0.08) : Colors.white12) : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                if (isSelected && isDesktop)
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF427AB5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                SizedBox(width: (isSelected && isDesktop) ? 12 : 0),
                Icon(
                  isSelected ? activeIcon : icon, 
                  color: isDesktop 
                    ? (isSelected ? const Color(0xFF1E3C72) : const Color(0xFF94A3B8))
                    : (isSelected ? Colors.white : Colors.white70),
                  size: 22,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isDesktop
                        ? (isSelected ? const Color(0xFF1E3C72) : const Color(0xFF94A3B8))
                        : (isSelected ? Colors.white : Colors.white70),
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                    child: Text(
                      badgeCount > 9 ? "9+" : "$badgeCount",
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        );
      }
    );
  }

  Stream<int> _getBadgeCount(int index, String? uid) {
    if (uid == null) return Stream<int>.value(0).asBroadcastStream();

    if (index == 1) { // Paket Saya
      return FirebaseFirestore.instance
          .collection('user')
          .doc(uid)
          .collection('packages')
          .where('isUpdatedByAdmin', isEqualTo: true)
          .snapshots()
          .map((snap) => snap.docs.length);
    }
    
    if (index == 2) { // Konsolidasi
      return FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: uid)
          .where('isUpdatedByAdmin', isEqualTo: true)
          .snapshots()
          .map((snap) => snap.docs.length);
    }

    if (index == 7) { // Notifikasi
      return FirebaseFirestore.instance
          .collection('user')
          .doc(uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snap) => snap.docs.length);
    }

    return Stream<int>.value(0).asBroadcastStream();
  }

  void _clearNotificationBadge(String uid) async {
    var snapshot = await FirebaseFirestore.instance
        .collection('user')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
    for (var doc in snapshot.docs) {
      doc.reference.update({'isRead': true});
    }
  }
}

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final user = AuthService().currentUser;

    return Container(
      color: Colors.transparent, // Inherit from parent F0F4F8
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          children: [
            // 🚀 WELCOME CARD (Modern Compact)
            StreamBuilder<DocumentSnapshot>(
              stream: user != null
                  ? AuthService().getUserData(user.uid)
                  : const Stream.empty(),
              builder: (context, userSnap) {
                final userData = userSnap.data?.data() as Map<String, dynamic>?;
                final userIdCode = userData?['userIdCode'] ?? '-';

                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E3C72).withOpacity(0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      )
                    ],
                    border: Border.all(color: const Color(0xFF1E3C72).withOpacity(0.05)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -50,
                          top: -50,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          left: -30,
                          bottom: -30,
                          child: Icon(Icons.inventory_2_rounded, size: 150, color: const Color(0xFF427AB5).withOpacity(0.02)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFF427AB5).withOpacity(0.1),
                                    child: const Icon(Icons.person, color: Color(0xFF427AB5), size: 30),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                          Text(
                                            "Selamat Datang,",
                                            style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 12),
                                          ),
                                          Text(
                                            user?.displayName ?? 'Pengguna',
                                            style: const TextStyle(
                                              fontSize: 20, 
                                              fontWeight: FontWeight.w900, 
                                              color: Color(0xFF1E3C72),
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _buildModernBadge("ID: $userIdCode", const Color(0xFF427AB5).withOpacity(0.1), const Color(0xFF427AB5)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            // 📦 ALAMAT GUDANG (Modern Grid)
            _buildWarehouseAddressSection(),

            const SizedBox(height: 8),
            
            // 📊 STATISTIK (Bento Compact)
            LayoutBuilder(builder: (context, constraints) {
              final uid = AuthService().currentUser?.uid ?? "";
              
              return GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: isDesktop ? 2.5 : 0.85,
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('user')
                        .doc(uid)
                        .collection('packages')
                        .snapshots(),
                    builder: (context, snapshot) {
                      int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return statCard(isDesktop, "Paket di Gudang", count.toString(), Icons.inventory_2_rounded, const Color(0xFF427AB5));
                    },
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('orders')
                        .where('userId', isEqualTo: uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      int count = 0;
                      if (snapshot.hasData) {
                        count = snapshot.data!.docs.where((doc) {
                          final status = (doc.data() as Map<String, dynamic>)["status"];
                          return status != "Selesai" && status != "Ditolak";
                        }).length;
                      }
                      return statCard(isDesktop, "Sedang Diproses", count.toString(), Icons.local_shipping_rounded, Colors.orange);
                    },
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('orders')
                        .where('userId', isEqualTo: uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return statCard(isDesktop, "Total Pengiriman", count.toString(), Icons.assignment_turned_in_rounded, Colors.green);
                    },
                  ),
                ],
              );
            }),

            const SizedBox(height: 8),

            // 💡 INFO TIPS
            if (isDesktop)
              Row(
                children: [
                  Expanded(child: infoCard(Icons.lightbulb_outline_rounded, "Tips Cepat", "Gunakan fitur konsolidasi untuk menghemat biaya pengiriman antar negara.")),
                  const SizedBox(width: 15),
                  Expanded(child: infoCard(Icons.security_rounded, "Keamanan", "Pastikan paket Anda dipacking dengan aman sesuai standar Satupaket.")),
                ],
              )
            else
              Column(
                children: [
                  infoCard(Icons.lightbulb_outline_rounded, "Tips Cepat", "Gunakan fitur konsolidasi untuk menghemat biaya pengiriman."),
                  infoCard(Icons.security_rounded, "Keamanan", "Pastikan paket Anda dipacking dengan aman."),
                ],
              ),
            
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildModernBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.1)),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildCompactBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    CustomNotification.showSuccess(context, "$label disalin!");
  }

  Widget _buildWarehouseAddressSection() {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return const SizedBox();

    return StreamBuilder<DocumentSnapshot>(
      stream: AuthService().getUserData(currentUser.uid),
      builder: (context, userSnap) {
        final userData = userSnap.data?.data() as Map<String, dynamic>?;
        final userIdCode = userData?['userIdCode'] ?? '-';
        final userName = currentUser.displayName ?? userData?['name'] ?? '-';

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('warehouse_addresses').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();

            final doc = snapshot.data!.docs.first;
            final data = doc.data() as Map<String, dynamic>;

            final alamatLengkap =
                "${data["detail"]}, ${data["kecamatan"]}, ${data["kota"]}, ${data["provinsi"]} ${data["kodePos"]}";
            final penerima = data["penerima"] ?? "-";
            final telp = data["telp"] ?? "-";

            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF1E3C72).withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Elegant Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      border: Border(bottom: BorderSide(color: const Color(0xFF1E3C72).withOpacity(0.05))),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.location_on_rounded, color: Color(0xFF1E3C72), size: 22),
                        SizedBox(width: 12),
                        Text(
                          "Alamat Gudang Tujuan",
                          style: TextStyle(
                            color: Color(0xFF1E3C72), 
                            fontWeight: FontWeight.w900, 
                            fontSize: 14,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              _buildUnifiedAddressRow(
                                context,
                                icon: Icons.map_rounded,
                                title: "ALAMAT LENGKAP",
                                value: alamatLengkap,
                                copyText: alamatLengkap,
                                copyLabel: "Alamat",
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(height: 1, color: Colors.white, thickness: 1),
                              ),
                              _buildUnifiedAddressRow(
                                context,
                                icon: Icons.person_pin_rounded,
                                title: "PENGIRIM & KODE UNIK",
                                value: "$userName - $userIdCode",
                                copyText: "$userName - $userIdCode",
                                copyLabel: "Nama & Kode Unik",
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF427AB5).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: const Color(0xFF427AB5).withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, color: Color(0xFF427AB5), size: 16),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Gunakan alamat di atas pada e-commerce Anda untuk mengirimkan paket ke gudang kami.",
                                  style: TextStyle(
                                    color: const Color(0xFF1E3C72).withOpacity(0.7),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUnifiedAddressRow(BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String copyText,
    required String copyLabel,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF427AB5), size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF427AB5),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1E3C72),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _copyToClipboard(context, copyText, copyLabel),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.copy_rounded, color: const Color(0xFF427AB5).withOpacity(0.5), size: 18),
            ),
          ),
        ),
      ],
    );
  }


  Widget statCard(bool isDesktop, String title, String value, IconData icon, Color color) {

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
        border: Border.all(color: color.withOpacity(0.08)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(icon, color: color.withOpacity(0.05), size: isDesktop ? 60 : 40),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 12 : 6, vertical: isDesktop ? 8 : 10),
            child: isDesktop 
              ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            value,
                            style: const TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.w900, 
                              color: Color(0xFF1E3C72),
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            title.toUpperCase(), 
                            style: TextStyle(
                              color: const Color(0xFF94A3B8), 
                              fontWeight: FontWeight.w900, 
                              fontSize: 8,
                              letterSpacing: 1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 14),
                    ),
                    const Spacer(),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.w900, 
                        color: Color(0xFF1E3C72),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title.toUpperCase(), 
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF94A3B8), 
                        fontWeight: FontWeight.w900, 
                        fontSize: 7,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget infoCard(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
        border: Border.all(color: const Color(0xFF1E3C72).withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF427AB5).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF427AB5), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: const TextStyle(
                    fontWeight: FontWeight.w900, 
                    color: Color(0xFF1E3C72),
                    fontSize: 13,
                  )
                ),
                const SizedBox(height: 4),
                Text(
                  desc, 
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.5), 
                    fontSize: 10, 
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}


