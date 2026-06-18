import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/package_service.dart';
import '../../services/order_service.dart';

import 'barang_masuk_page.dart';
import 'biaya_page.dart';
import 'konfirmasi_page.dart';
import 'barang_keluar_page.dart';
import 'alamat_toko_page.dart';
import 'privasi_page.dart';
import 'pesan_page.dart';
import 'profil_page.dart';
import 'manajemen_layanan_page.dart';
import 'ulasan_page.dart';
import '../../widgets/custom_notification.dart';

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({super.key});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  int selectedIndex = 0;
  bool isBarangMasukExpanded = false;
  String _barangMasukFilter = "All";
  bool isKonfirmasiExpanded = false;
  String _konfirmasiFilter = "Menunggu Konfirmasi";
  bool isBarangKeluarExpanded = false;
  String _barangKeluarFilter = "Diantar";
  final PackageService _packageService = PackageService();
  StreamSubscription? _adminEventSub;
  final DateTime _sessionStartTime = DateTime.now();
  final ScrollController _sidebarScrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late Stream<QuerySnapshot> _packagesStream;
  late Stream<QuerySnapshot> _pengirimanStream;
  late Stream<QuerySnapshot> _ordersStream;
  late Stream<QuerySnapshot> _chatRoomsStream;
  late Stream<QuerySnapshot> _userStream;

  bool get isMobile => MediaQuery.of(context).size.width <= 1100;

  @override
  void initState() {
    super.initState();
    _packagesStream = _packageService.getAdminPackagesStream();
    _pengirimanStream = OrderService.getPengirimanStream();
    _ordersStream = FirebaseFirestore.instance.collection('orders').snapshots();
    _chatRoomsStream = FirebaseFirestore.instance.collection('chatRooms').snapshots();
    _userStream = FirebaseFirestore.instance.collection('user').snapshots();
    _listenForAdminEvents();
  }

  @override
  void dispose() {
    _adminEventSub?.cancel();
    _sidebarScrollController.dispose();
    super.dispose();
  }

  void _listenForAdminEvents() {
    // Listen for events in packages_admin
    _adminEventSub = FirebaseFirestore.instance
        .collection('packages_admin')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final createdAt = data["createdAt"] as Timestamp?;
          
          // Only notify if created after session started
          if (createdAt != null && createdAt.toDate().isAfter(_sessionStartTime)) {
            if (mounted) {
              CustomNotification.show(
                context, 
                "📦 Barang Masuk: Resi ${data['resi']} baru saja diterima!",
                type: NotificationType.success,
                duration: const Duration(seconds: 5),
              );
            }
          }
        } else if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data() as Map<String, dynamic>;
          // If a note was just added via flag
          if (data["hasNewNote"] == true) {
            if (mounted) {
              CustomNotification.show(
                context, 
                "📝 Catatan: ${data['nama'] ?? 'User'} mengirim pesan untuk resi ${data['resi']}",
                type: NotificationType.info,
                duration: const Duration(seconds: 5),
              );
              // Hapus flag agar tidak muncul berulang
              change.doc.reference.update({"hasNewNote": FieldValue.delete()});
            }
          }
        }
      }
    });
  }

  void _showEventDialog({required String title, required String message, required int targetIndex, bool isWelcome = false}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 20,
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🎨 ICON / ILLUSTRATION
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF427AB5).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isWelcome ? Icons.verified_user_rounded : Icons.notifications_active_rounded,
                    size: 40,
                    color: const Color(0xFF427AB5),
                  ),
                ),
                const SizedBox(height: 25),
                
                // 📝 TEXT
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
                ),
                const SizedBox(height: 35),
                
                // 🚀 ACTION BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => selectedIndex = targetIndex);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF427AB5),
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: const Color(0xFF427AB5).withOpacity(0.4),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text(
                      isWelcome ? "Mulai Kelola" : "Cek Sekarang",
                      style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
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

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      key: _scaffoldKey,
      appBar: isMobile
          ? AppBar(
              backgroundColor: const Color(0xFF427AB5),
              elevation: 0,
              title: const Text("SATUPAKET ADMIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            )
          : null,
      drawer: isMobile ? Drawer(child: _buildSidebar(context)) : null,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF427AB5), Color(0xFF6594B1), Color(0xFFBDEBFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: isMobile ? 0 : 10,
              right: isMobile ? 0 : 10,
              top: isMobile ? 0 : 10,
              bottom: isMobile ? 15 : 10, // Tambahan padding bawah di mobile
            ),
            child: Row(
              children: [
                // ================= SIDEBAR (DESKTOP) =================
                if (!isMobile) _buildSidebar(context),

                if (!isMobile) const SizedBox(width: 15),

                // ================= CONTENT =================
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(isMobile ? 20 : 30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isMobile ? double.infinity : 1400,
                        ),
                        child: _buildContent(),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    
    return Container(
      width: isMobile ? double.infinity : 260,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isMobile ? const Color(0xFF427AB5) : Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(isMobile ? 0 : 30),
        border: isMobile ? null : Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: isMobile ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // 🔥 LOGO
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
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
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          Expanded(
            child: ListView(
              controller: _sidebarScrollController,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text("OPERASIONAL", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
                _menuItem(Icons.dashboard_outlined, "Dashboard", 0),
                _expandableBarangMasuk(),
                _expandableKonfirmasiPesanan(),
                _expandableBarangKeluar(),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  child: Text("PENGATURAN", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
                _menuItem(Icons.attach_money_outlined, "Manajemen Biaya", 4),
                _menuItem(Icons.store_outlined, "Alamat Toko", 5),
                _menuItem(Icons.room_service_outlined, "Manajemen Layanan", 6),
                _menuItem(Icons.star_outline_rounded, "Ulasan", 7),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  child: Text("LAINNYA", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
                _menuItem(Icons.message_outlined, "Pesan", 8),
                _menuItem(Icons.privacy_tip_outlined, "Info Privasi", 9),
              ],
            ),
          ),

          // 🔥 PROFIL
          const Divider(color: Colors.white12, indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.all(20),
            child: InkWell(
              onTap: () {
                setState(() => selectedIndex = 10);
                if (isMobile) Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(15),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Admin Central",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text("Super Admin", style: TextStyle(color: Colors.white60, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= SWITCH =================
  Widget _buildContent() {
    return IndexedStack(
      index: selectedIndex,
      children: [
        _dashboardContent(), // 0
        BarangMasukPage(filter: _barangMasukFilter), // 1
        KonfirmasiPage(filter: _konfirmasiFilter), // 2
        BarangKeluarPage(filter: _barangKeluarFilter), // 3
        BiayaPage(), // 4
        const AlamatTokoPage(), // 5
        const ManajemenLayananPage(), // 6
        const UlasanPage(), // 7
        const PesanPage(), // 8
        const PrivasiPage(), // 9
        const ProfilPage(), // 10
      ],
    );
  }

  // ================= MENU =================
  Widget _menuItem(IconData icon, String title, int index) {
    bool active = selectedIndex == index;

    Stream<QuerySnapshot> getStream() {
      if (title == "Konfirmasi Pesanan") return _ordersStream;
      if (title == "Pesan") return _chatRoomsStream;
      return _packagesStream;
    }

    return StreamBuilder<QuerySnapshot>(
      stream: getStream(),
      builder: (context, snapshot) {
        int badgeCount = 0;
        if (snapshot.hasData) {
          if (title == "Barang Masuk") {
            badgeCount = snapshot.data!.docs.where((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return data["catatanUser"] != null;
            }).length;
          } else if (title == "Konfirmasi Pesanan") {
            badgeCount = snapshot.data!.docs.where((doc) {
              final s = (doc.data() as Map<String, dynamic>)["status"];
              return s == "Menunggu Konfirmasi" || s == "Diproses";
            }).length;
          } else if (title == "Pesan") {
            badgeCount = snapshot.data!.docs.fold<int>(0, (prev, doc) {
              final d = doc.data() as Map<String, dynamic>;
              final count = d["unreadCountAdmin"] ?? 0;
              return prev + (count is int ? count : (count as num).toInt());
            });
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              setState(() {
                selectedIndex = index;
              });
              if (MediaQuery.of(context).size.width <= 1100) {
                Navigator.pop(context);
              }
            },
            borderRadius: BorderRadius.circular(15),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
              decoration: BoxDecoration(
                color: active ? Colors.white.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
                border: active 
                  ? Border.all(color: Colors.white.withOpacity(0.2)) 
                  : Border.all(color: Colors.transparent),
              ),
              child: Row(
                children: [
                  // 🍭 INDICATOR
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: active ? 4 : 0,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  SizedBox(width: active ? 12 : 0),
                  
                  Icon(
                    icon, 
                    color: active ? Colors.white : Colors.white70,
                    size: 22,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: active ? Colors.white : Colors.white70,
                        fontWeight: active ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (badgeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
                      child: Text(badgeCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ================= EXPANDABLE MENU (BARANG MASUK) =================
  Widget _expandableBarangMasuk() {
    bool isAnyChildActive = selectedIndex == 1;

    return StreamBuilder<QuerySnapshot>(
      stream: _packageService.getAdminPackagesStream(),
      builder: (context, snapshot) {
        int badgeCountRequest = 0;
        int badgeCountDitolak = 0;
        
        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          badgeCountRequest = docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return data["catatanUser"] != null;
          }).length;
          
          badgeCountDitolak = docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return data["rejectionReason"] != null && data["userApprovalStatus"] != "approved";
          }).length;
        }

        int totalBadgeCount = badgeCountRequest + badgeCountDitolak;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    isBarangMasukExpanded = !isBarangMasukExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(15),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                  decoration: BoxDecoration(
                    color: isAnyChildActive && !isBarangMasukExpanded ? Colors.white.withOpacity(0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                    border: isAnyChildActive
                      ? Border.all(color: Colors.white.withOpacity(0.2))
                      : Border.all(color: Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isAnyChildActive ? 4 : 0,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      SizedBox(width: isAnyChildActive ? 12 : 0),
                      
                      Icon(
                        Icons.inventory_outlined,
                        color: isAnyChildActive ? Colors.white : Colors.white70,
                        size: 22,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          "Barang Masuk",
                          style: TextStyle(
                            color: isAnyChildActive ? Colors.white : Colors.white70,
                            fontWeight: isAnyChildActive ? FontWeight.bold : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (totalBadgeCount > 0 && !isBarangMasukExpanded)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
                          child: Text(totalBadgeCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      Icon(
                        isBarangMasukExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: isAnyChildActive ? Colors.white : Colors.white70,
                        size: 20,
                      )
                    ],
                  ),
                ),
              ),
            ),
            if (isBarangMasukExpanded)
              Padding(
                padding: const EdgeInsets.only(left: 35, bottom: 8),
                child: Column(
                  children: [
                    _subMenuItem("Semua Barang Masuk", "All", 0),
                    _subMenuItem("Request", "Request", badgeCountRequest),
                    _subMenuItem("Ditolak", "Ditolak", badgeCountDitolak),
                  ],
                ),
              )
          ],
        );
      }
    );
  }

  // ================= EXPANDABLE MENU (KONFIRMASI PESANAN) =================
  Widget _expandableKonfirmasiPesanan() {
    bool isAnyChildActive = selectedIndex == 2;

    return StreamBuilder<QuerySnapshot>(
      stream: OrderService.getAllOrdersStream(),
      builder: (context, snapshot) {
        int badgeMenunggu = 0;
        int badgeDiproses = 0;
        
        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          badgeMenunggu = docs.where((doc) {
            final s = (doc.data() as Map<String, dynamic>)["status"];
            return s == "Menunggu Konfirmasi";
          }).length;
          
          badgeDiproses = docs.where((doc) {
            final s = (doc.data() as Map<String, dynamic>)["status"];
            return s == "Diproses";
          }).length;
        }

        int totalBadgeCount = badgeMenunggu + badgeDiproses;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    isKonfirmasiExpanded = !isKonfirmasiExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(15),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                  decoration: BoxDecoration(
                    color: isAnyChildActive && !isKonfirmasiExpanded ? Colors.white.withOpacity(0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                    border: isAnyChildActive
                      ? Border.all(color: Colors.white.withOpacity(0.2))
                      : Border.all(color: Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isAnyChildActive ? 4 : 0,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      SizedBox(width: isAnyChildActive ? 12 : 0),
                      
                      Icon(
                        Icons.pending_actions_rounded,
                        color: isAnyChildActive ? Colors.white : Colors.white70,
                        size: 22,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          "Konfirmasi Pesanan",
                          style: TextStyle(
                            color: isAnyChildActive ? Colors.white : Colors.white70,
                            fontWeight: isAnyChildActive ? FontWeight.bold : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (totalBadgeCount > 0 && !isKonfirmasiExpanded)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
                          child: Text(totalBadgeCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      Icon(
                        isKonfirmasiExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: isAnyChildActive ? Colors.white : Colors.white70,
                        size: 20,
                      )
                    ],
                  ),
                ),
              ),
            ),
            if (isKonfirmasiExpanded)
              Padding(
                padding: const EdgeInsets.only(left: 35, bottom: 8),
                child: Column(
                  children: [
                    _subMenuItemKonfirmasi("Menunggu Konfirmasi", "Menunggu Konfirmasi", badgeMenunggu),
                    _subMenuItemKonfirmasi("Diproses", "Diproses", badgeDiproses),
                  ],
                ),
              ),
          ],
        );
      }
    );
  }

  // ================= EXPANDABLE MENU (BARANG KELUAR) =================
  Widget _expandableBarangKeluar() {
    bool isAnyChildActive = selectedIndex == 3;

    return StreamBuilder<QuerySnapshot>(
      stream: OrderService.getPengirimanStream(),
      builder: (context, snapshot) {
        int badgeDiantar = 0;
        int badgeSelesai = 0;
        
        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          badgeDiantar = docs.where((doc) {
            final s = (doc.data() as Map<String, dynamic>)["status"];
            return s != "Selesai";
          }).length;
          
          badgeSelesai = docs.where((doc) {
            final s = (doc.data() as Map<String, dynamic>)["status"];
            return s == "Selesai";
          }).length;
        }

        int totalBadgeCount = badgeDiantar; // Biasanya tidak perlu alert banyak untuk yg selesai, prioritas diantar

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    isBarangKeluarExpanded = !isBarangKeluarExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(15),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                  decoration: BoxDecoration(
                    color: isAnyChildActive && !isBarangKeluarExpanded ? Colors.white.withOpacity(0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                    border: isAnyChildActive
                      ? Border.all(color: Colors.white.withOpacity(0.2))
                      : Border.all(color: Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isAnyChildActive ? 4 : 0,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      SizedBox(width: isAnyChildActive ? 12 : 0),
                      
                      Icon(
                        Icons.local_shipping,
                        color: isAnyChildActive ? Colors.white : Colors.white70,
                        size: 22,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          "Barang Keluar",
                          style: TextStyle(
                            color: isAnyChildActive ? Colors.white : Colors.white70,
                            fontWeight: isAnyChildActive ? FontWeight.bold : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (totalBadgeCount > 0 && !isBarangKeluarExpanded)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
                          child: Text(totalBadgeCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      Icon(
                        isBarangKeluarExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: isAnyChildActive ? Colors.white : Colors.white70,
                        size: 20,
                      )
                    ],
                  ),
                ),
              ),
            ),
            if (isBarangKeluarExpanded)
              Padding(
                padding: const EdgeInsets.only(left: 35, bottom: 8),
                child: Column(
                  children: [
                    _subMenuItemBarangKeluar("Diantar", "Diantar", badgeDiantar),
                    _subMenuItemBarangKeluar("Selesai", "Selesai", badgeSelesai),
                  ],
                ),
              ),
          ],
        );
      }
    );
  }

  Widget _subMenuItem(String title, String filter, int badgeCount) {
    bool active = selectedIndex == 1 && _barangMasukFilter == filter;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedIndex = 1;
            _barangMasukFilter = filter;
          });
          if (isMobile) {
            Navigator.pop(context);
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          decoration: BoxDecoration(
            color: active ? Colors.white.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? Colors.white : Colors.white38,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.white70,
                    fontSize: 13,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
                  child: Text(badgeCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subMenuItemKonfirmasi(String title, String filter, int badgeCount) {
    bool active = selectedIndex == 2 && _konfirmasiFilter == filter;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedIndex = 2;
            _konfirmasiFilter = filter;
          });
          if (isMobile) {
            Navigator.pop(context);
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          decoration: BoxDecoration(
            color: active ? Colors.white.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? Colors.white : Colors.white38,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.white70,
                    fontSize: 13,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
                  child: Text(badgeCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subMenuItemBarangKeluar(String title, String filter, int badgeCount) {
    bool active = selectedIndex == 3 && _barangKeluarFilter == filter;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedIndex = 3;
            _barangKeluarFilter = filter;
          });
          if (isMobile) {
            Navigator.pop(context);
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          decoration: BoxDecoration(
            color: active ? Colors.white.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? Colors.white : Colors.white38,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.white70,
                    fontSize: 13,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
                  child: Text(badgeCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= DASHBOARD =================
  Widget _dashboardContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: _packagesStream,
      builder: (context, packageSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: _pengirimanStream,
          builder: (context, pengirimanSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: _ordersStream,
              builder: (context, orderSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: _chatRoomsStream,
                  builder: (context, chatSnapshot) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: _userStream,
                      builder: (context, userSnapshot) {
                        // 1. Error & Loading State Check
                        if (packageSnapshot.hasError || pengirimanSnapshot.hasError || orderSnapshot.hasError || chatSnapshot.hasError || userSnapshot.hasError) {
                          return Center(child: Text("Terjadi kesalahan data. Silakan coba lagi."));
                        }

                        if (packageSnapshot.connectionState == ConnectionState.waiting || 
                            pengirimanSnapshot.connectionState == ConnectionState.waiting ||
                            orderSnapshot.connectionState == ConnectionState.waiting ||
                            chatSnapshot.connectionState == ConnectionState.waiting ||
                            userSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        // 2. Data Preparation
                        final packages = packageSnapshot.data?.docs ?? [];
                        final pengiriman = pengirimanSnapshot.data?.docs ?? [];
                        final allOrders = orderSnapshot.data?.docs ?? [];
                        final chatRooms = chatSnapshot.data?.docs ?? [];
                        final allUsers = userSnapshot.data?.docs ?? [];

                        // 3. Aggregation - Main Cards
                        int totalMasuk = packages.length;
                        int totalKeluar = 0;
                        for (var doc in pengiriman) {
                          final data = doc.data() as Map<String, dynamic>;
                          List items = data["items"] ?? [];
                          totalKeluar += items.length;
                        }
                        int totalStok = totalMasuk - totalKeluar;

                        // 4. Aggregation - Status & Payment Metrics
                        int countMenunggu = 0;
                        int countDiproses = 0;
                        int totalDitolak = 0;
                        int totalCOD = 0;
                        int totalTransfer = 0;
                        for (var doc in allOrders) {
                          final data = doc.data() as Map<String, dynamic>;
                          final status = data["status"];
                          final pembayaran = data["pembayaran"];

                          if (status == "Menunggu Konfirmasi") countMenunggu++;
                          else if (status == "Diproses") countDiproses++;
                          else if (status == "Ditolak") totalDitolak++;

                          if (pembayaran == "COD") totalCOD++;
                          else totalTransfer++;
                        }

                        // 5. Aggregation - Other Metrics
                        int pesanBaru = chatRooms.where((doc) => (doc.data() as Map<String, dynamic>)["lastSenderRole"] == "user").length;
                        int totalUserCount = allUsers.length;

                        // 5b. Request Catatan User (packages with catatanUser)
                        int requestCatatan = packages.where((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          return d["catatanUser"] != null && d["catatanUser"].toString().trim().isNotEmpty;
                        }).length;

                        // 6. Aggregation - Charts Data
                        double kecil = 0, sedang = 0, besar = 0;
                        for (var doc in packages) {
                          final data = doc.data() as Map<String, dynamic>;
                          if (data["kategori"] == "Kecil") kecil++;
                          else if (data["kategori"] == "Sedang") sedang++;
                          else if (data["kategori"] == "Besar") besar++;
                        }
                        double totalPie = kecil + sedang + besar;
                        if (totalPie == 0) totalPie = 1;

                        List<int> trendMasuk = List.filled(7, 0);
                        List<int> trendKeluar = List.filled(7, 0);
                        DateTime now = DateTime.now();
                        List<String> last7DaysStr = [];
                        for (int i = 6; i >= 0; i--) {
                          last7DaysStr.add(DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: i))));
                        }

                        for (var doc in packages) {
                          final d = doc.data() as Map<String, dynamic>;
                          String? tgl = d["tanggal"];
                          if (tgl != null) {
                            int idx = last7DaysStr.indexOf(tgl);
                            if (idx != -1) trendMasuk[idx]++;
                          }
                        }
                        for (var doc in pengiriman) {
                          final d = doc.data() as Map<String, dynamic>;
                          String? tgl = d["tanggal"];
                          if (tgl != null) {
                            int idx = last7DaysStr.indexOf(tgl);
                            if (idx != -1) trendKeluar[idx] += (d["items"] as List? ?? []).length;
                          }
                        }

                        // 7. Render UI (Responsive)

                        Widget content = Padding(
                          padding: EdgeInsets.fromLTRB(20, 20, 20, isMobile ? 30 : 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              const Text("Dashboard Utama", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                              const SizedBox(height: 14),

                              // ⚡ INFO CARDS
                              isMobile 
                                ? GridView.count(
                                    crossAxisCount: 2,
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 1.4, // Changed from 2.1 to make cards taller
                                    children: [
                                      _card(countMenunggu.toString(), "Menunggu ACC", Icons.pending_actions_rounded, Colors.orange, isExpanded: false, onTap: () => setState(() { selectedIndex = 2; _konfirmasiFilter = "Menunggu Konfirmasi"; isKonfirmasiExpanded = true; })),
                                      _card(countDiproses.toString(), "Sedang Diproses", Icons.sync_rounded, const Color(0xFF427AB5), isExpanded: false, onTap: () => setState(() { selectedIndex = 2; _konfirmasiFilter = "Diproses"; isKonfirmasiExpanded = true; })),
                                      _card(requestCatatan.toString(), "Request Catatan", Icons.note_alt_rounded, Colors.purple, isExpanded: false, onTap: () => setState(() { selectedIndex = 1; _barangMasukFilter = "Request"; isBarangMasukExpanded = true; })),
                                      _card(totalMasuk.toString(), "Barang Masuk", Icons.inventory_2, Colors.blue, isExpanded: false, onTap: () => setState(() { selectedIndex = 1; _barangMasukFilter = "All"; isBarangMasukExpanded = true; })),
                                      _card(totalKeluar.toString(), "Barang Keluar", Icons.local_shipping, Colors.orange, isExpanded: false, onTap: () => setState(() { selectedIndex = 3; _barangKeluarFilter = "Semua Status"; isBarangKeluarExpanded = true; })),
                                      _card(totalStok.toString(), "Total Stok", Icons.storage, totalStok < 0 ? Colors.red : Colors.green, isExpanded: false),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      Row(
                                        children: [
                                          _card(countMenunggu.toString(), "Menunggu ACC", Icons.pending_actions_rounded, Colors.orange, onTap: () => setState(() { selectedIndex = 2; _konfirmasiFilter = "Menunggu Konfirmasi"; isKonfirmasiExpanded = true; })),
                                          _card(countDiproses.toString(), "Sedang Diproses", Icons.sync_rounded, const Color(0xFF427AB5), onTap: () => setState(() { selectedIndex = 2; _konfirmasiFilter = "Diproses"; isKonfirmasiExpanded = true; })),
                                          _card(requestCatatan.toString(), "Request Catatan", Icons.note_alt_rounded, Colors.purple, onTap: () => setState(() { selectedIndex = 1; _barangMasukFilter = "Request"; isBarangMasukExpanded = true; })),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          _card(totalMasuk.toString(), "Barang Masuk", Icons.inventory_2, Colors.blue, onTap: () => setState(() { selectedIndex = 1; _barangMasukFilter = "All"; isBarangMasukExpanded = true; })),
                                          _card(totalKeluar.toString(), "Barang Keluar", Icons.local_shipping, Colors.orange, onTap: () => setState(() { selectedIndex = 3; _barangKeluarFilter = "Semua Status"; isBarangKeluarExpanded = true; })),
                                          _card(totalStok.toString(), "Total Stok", Icons.storage, totalStok < 0 ? Colors.red : Colors.green),
                                        ],
                                      ),
                                    ],
                                  ),

                              const SizedBox(height: 16),

                              // 📊 CHARTS
                              if (isMobile) ...[
                                SizedBox(height: 250, child: _chartBarangMasuk(trendMasuk)),
                                const SizedBox(height: 14),
                                SizedBox(height: 200, child: _chartPengiriman(trendKeluar)),
                                const SizedBox(height: 14),
                                SizedBox(height: 180, child: _chartJenisBarang(kecil, sedang, besar, totalPie)),
                              ] else
                                Expanded(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(flex: 3, child: _chartBarangMasuk(trendMasuk)),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          children: [
                                            Expanded(child: _chartPengiriman(trendKeluar)),
                                            const SizedBox(height: 14),
                                            Expanded(child: _chartJenisBarang(kecil, sedang, besar, totalPie)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );

                        return isMobile ? SingleChildScrollView(child: content) : content;
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // ================= CARD =================
  Widget _card(String value, String title, IconData icon, Color color, {bool isExpanded = true, VoidCallback? onTap}) {
    Widget content = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: isExpanded ? const EdgeInsets.only(right: 14) : EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: isMobile ? 18 : 24),
            ),
            SizedBox(width: isMobile ? 8 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (isExpanded) return Expanded(child: content);
    return content;
  }

  Widget _notificationCard(String value, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 20),
                if (value != "0")
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                  ),
                  Text(
                    title,
                    style: TextStyle(fontSize: 10, color: color.withOpacity(0.8), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ================= CHARTS =================
  Widget _chartJenisBarang(double kecil, double sedang, double besar, double total) {
    bool hasData = (kecil + sedang + besar) > 0;
    
    return _box(
      "Proporsi Kategori Barang",
      hasData ? Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 25, // Reduced from 35
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  if (kecil > 0) Expanded(flex: (kecil*100).toInt(), child: Container(color: Colors.redAccent.withOpacity(0.8))),
                  if (sedang > 0) Expanded(flex: (sedang*100).toInt(), child: Container(color: Colors.orangeAccent.withOpacity(0.8))),
                  if (besar > 0) Expanded(flex: (besar*100).toInt(), child: Container(color: Colors.greenAccent.withOpacity(0.8))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10), // Reduced from 15
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (kecil > 0) _indicatorPercent(Colors.redAccent, "Kecil", kecil, total),
              if (sedang > 0) _indicatorPercent(Colors.orangeAccent, "Sedang", sedang, total),
              if (besar > 0) _indicatorPercent(Colors.greenAccent, "Besar", besar, total),
            ],
          )
        ],
      ) : const Center(child: Text("Belum ada data", style: TextStyle(color: Colors.grey))),
    );
  }

  Widget _indicatorPercent(Color color, String title, double value, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)), // Reduced from 10
            const SizedBox(width: 4), // Reduced from 5
            Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)), // Reduced from 11
          ],
        ),
        const SizedBox(height: 2), // Reduced from 4
        Text("${((value/total)*100).toStringAsFixed(1)}%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)), // Reduced from 14
      ],
    );
  }

  Widget _chartPengiriman(List<int> trendKeluar) {
    double maxY = trendKeluar.reduce((curr, next) => curr > next ? curr : next).toDouble() + 2;
    if (maxY < 5) maxY = 5;

    return _box(
      "Pengiriman (7 Hari Terakhir)",
      BarChart(
        BarChartData(
          maxY: maxY,
          barGroups: List.generate(7, (i) => _bar(i, trendKeluar[i].toDouble())),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text("H-${6 - value.toInt()}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
        ),
      ),
    );
  }

  Widget _chartBarangMasuk(List<int> trendMasuk) {
    double maxY = trendMasuk.reduce((curr, next) => curr > next ? curr : next).toDouble() + 5;
    if (maxY < 10) maxY = 10;

    return _box(
      "Tren Barang Masuk (7 Hari Terakhir)",
      LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: const Color(0xFF427AB5),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: const Color(0xFF427AB5).withOpacity(0.1)),
              spots: List.generate(7, (i) => FlSpot(i.toDouble(), trendMasuk[i].toDouble())),
            )
          ],
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  int val = value.toInt();
                  if (val < 0 || val > 6) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text("H-${6 - val}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
        ),
      ),
    );
  }

  BarChartGroupData _bar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [BarChartRodData(toY: y, color: Colors.orange, width: 15, borderRadius: BorderRadius.circular(4))],
    );
  }

  Widget _box(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(12), // Reduced from 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)), // Added font size
          const SizedBox(height: 10), // Reduced from 15
          Expanded(child: child),
        ],
      ),
    );
  }
}
