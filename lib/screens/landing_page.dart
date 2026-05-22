import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../routes/app_routes.dart';
import '../services/biaya_service.dart';
import 'dart:async';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _simulatorKey = GlobalKey();
  bool _isScrolled = false;

  final BiayaService _biayaService = BiayaService();
  StreamSubscription? _biayaSubscription;
  final TextEditingController _weightController = TextEditingController(text: "1000");

  // 🔥 SIMULATOR STATE
  int _packageCount = 1;
  
  // 🔥 PRICE DATA FROM FIRESTORE
  int _hargaPerKg = 13000; // Default values
  Map<String, int> _shippingPrices = {"Reguler": 0, "Express": 0};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 50 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 50 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });
    _fetchPrices();
  }

  void _fetchPrices() {
    _biayaSubscription = _biayaService.getMasterBiayaStream().listen((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _hargaPerKg = (data["hargaPerKg"] as num?)?.toInt() ?? 13000;
            _shippingPrices = {
              "Reguler": (data["shippingReguler"] as num?)?.toInt() ?? 0,
              "Express": (data["shippingExpress"] as num?)?.toInt() ?? 0,
            };
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _biayaSubscription?.cancel();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFDFF),
      body: Stack(
        children: [
          // 🔥 MAIN CONTENT
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                _buildHero(size, isDesktop),
                _buildSimulator(isDesktop),
                _buildStats(isDesktop),
                _buildFeatures(isDesktop),
                _buildPromoBanner(isDesktop),
                _buildCTASection(isDesktop),
                _buildFooter(isDesktop),
              ],
            ),
          ),

          // 🔥 NAVBAR
          _buildNavbar(isDesktop),
        ],
      ),
    );
  }

  Widget _buildNavbar(bool isDesktop) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 80,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 20),
      decoration: BoxDecoration(
        color: _isScrolled ? Colors.white : Colors.transparent,
        boxShadow: _isScrolled
            ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
            : [],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // LOGO
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Image.asset('lib/assets/images/logo.png', width: 28, height: 28, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "SATUPAKET",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E3C72),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),

          // MENU (Desktop)
          if (isDesktop)
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3C72),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: const Text("Mulai Sekarang", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            )
          else
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: Color(0xFF1E3C72)),
              onPressed: _showMobileMenu,
            ),
        ],
      ),
    );
  }

  Widget _navbarItem(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1E3C72),
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  void _showMobileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 30),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF427AB5).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.login_rounded, color: Color(0xFF427AB5)),
                ),
                title: const Text("Masuk", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.login);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF427AB5).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_add_rounded, color: Color(0xFF427AB5)),
                ),
                title: const Text("Daftar Sekarang", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.login);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHero(Size size, bool isDesktop) {
    return Container(
      height: isDesktop ? 800 : 700,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Stack(
        children: [
          // Background accents (Not too blue)
          Positioned(
            right: -100,
            top: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF427AB5).withOpacity(0.03),
              ),
            ),
          ),
          Positioned(
            left: size.width * 0.1,
            top: size.height * 0.2,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(color: Color(0xFF427AB5), shape: BoxShape.circle),
            ),
          ),
          Positioned(
            right: size.width * 0.15,
            bottom: size.height * 0.3,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: const Color(0xFF427AB5).withOpacity(0.4), shape: BoxShape.circle),
            ),
          ),
          
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 25),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF427AB5).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.flash_on_rounded, color: Color(0xFF427AB5), size: 14),
                            const SizedBox(width: 8),
                            const Text(
                              "SOLUSI ONGKIR HEMAT LAMPUNG",
                              style: TextStyle(
                                color: Color(0xFF427AB5), 
                                fontWeight: FontWeight.w900, 
                                fontSize: 11, 
                                letterSpacing: 1.5
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        "Kirim Paket ke\nSeluruh Kabupaten\nLebih Hemat!",
                        style: GoogleFonts.poppins(
                          fontSize: isDesktop ? 68 : 42,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1E3C72),
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 25),
                      Text(
                        "Layanan konsolidasi paket lokal pertama di Lampung. Belanja dari mana saja, kumpulkan di gudang Bandar Lampung, dan kirim sekaligus ke kabupaten Anda.",
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.6),
                          fontSize: isDesktop ? 18 : 16,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 45),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3C72),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 45 : 30, vertical: 25),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              elevation: 20,
                              shadowColor: const Color(0xFF1E3C72).withOpacity(0.3),
                            ),
                            child: const Text("Mulai Sekarang", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          ),
                          const SizedBox(width: 20),
                          if (isDesktop)
                            TextButton.icon(
                              onPressed: () {
                                final ctx = _simulatorKey.currentContext;
                                if (ctx != null) {
                                  Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
                                }
                              },
                              icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF427AB5), size: 30),
                              label: const Text("Lihat Cara Kerja", style: TextStyle(color: Color(0xFF1E3C72), fontWeight: FontWeight.w900)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isDesktop)
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 450,
                            width: 450,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [const Color(0xFF427AB5).withOpacity(0.1), const Color(0xFF427AB5).withOpacity(0.01)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            height: 350,
                            width: 350,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1E3C72).withOpacity(0.1),
                                  blurRadius: 50,
                                  offset: const Offset(0, 20),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Image.asset('lib/assets/images/logo.png', height: 200, fit: BoxFit.contain),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      color: Colors.white,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: isDesktop ? 100 : 40,
        runSpacing: 40,
        children: [
          _statItem("5k+", "Paket Terkirim"),
          _statItem("2k+", "Pengguna Aktif"),
          _statItem("99%", "Tingkat Kepuasan"),
          _statItem("15+", "Kabupaten/Kota"),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 32, 
            fontWeight: FontWeight.w900, 
            color: const Color(0xFF1E3C72),
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.black.withOpacity(0.4), fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildFeatures(bool isDesktop) {
    return Container(
      key: _featuresKey,
      padding: EdgeInsets.symmetric(vertical: 80, horizontal: isDesktop ? 100 : 25),
      color: const Color(0xFFFBFDFF),
      child: Column(
        children: [
          Text(
            "Keunggulan Layanan Kami",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w900, color: const Color(0xFF1E3C72)),
          ),
          const SizedBox(height: 15),
          Text(
            "Nikmati kemudahan logistik dengan standar pelayanan terbaik.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 16),
          ),
          const SizedBox(height: 60),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _featureCard(Icons.wallet_rounded, "Hemat Hingga 70%", "Biaya pengiriman borongan yang jauh lebih murah dibanding pengiriman satuan.")),
                const SizedBox(width: 25),
                Expanded(child: _featureCard(Icons.shield_rounded, "Keamanan Terjamin", "Asuransi paket dan sistem verifikasi foto untuk memastikan paket Anda aman.")),
                const SizedBox(width: 25),
                Expanded(child: _featureCard(Icons.track_changes_rounded, "Tracking Real-time", "Pantau posisi paket Anda secara langsung dari dashboard user.")),
              ],
            )
          else
            Column(
              children: [
                _featureCard(Icons.wallet_rounded, "Hemat Hingga 70%", "Biaya pengiriman borongan yang jauh lebih murah."),
                const SizedBox(height: 20),
                _featureCard(Icons.shield_rounded, "Keamanan Terjamin", "Asuransi paket dan sistem verifikasi foto."),
                const SizedBox(height: 20),
                _featureCard(Icons.track_changes_rounded, "Tracking Real-time", "Pantau posisi paket Anda secara langsung."),
              ],
            ),
        ],
      ),
    );
  }

  Widget _featureCard(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E3C72).withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3C72).withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF427AB5).withOpacity(0.08),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: const Color(0xFF427AB5), size: 28),
          ),
          const SizedBox(height: 25),
          Text(title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF1E3C72))),
          const SizedBox(height: 12),
          Text(desc, style: TextStyle(color: Colors.black.withOpacity(0.5), height: 1.6, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPromoBanner(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 60, horizontal: isDesktop ? 100 : 25),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3C72),
          borderRadius: BorderRadius.circular(30),
          image: DecorationImage(
            image: const NetworkImage('https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?q=80&w=2070&auto=format&fit=crop'),
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
        ),
        child: Column(
          children: [
            Text(
              "Dukungan Full 24/7",
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            const Text(
              "Tim kami siap membantu kendala pengiriman Anda kapan saja melalui fitur Chat Admin.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCTASection(bool isDesktop) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 25, vertical: 80),
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFF1E3C72).withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3C72).withOpacity(0.05),
            blurRadius: 40,
            offset: const Offset(0, 20),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: const Icon(Icons.rocket_launch_rounded, color: Color(0xFF1E3C72), size: 40),
          ),
          const SizedBox(height: 30),
          Text(
            "Siap untuk Berhemat?",
            style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w900, color: const Color(0xFF1E3C72)),
          ),
          const SizedBox(height: 15),
          Text(
            "Gabung sekarang dan nikmati tarif pengiriman termurah di Lampung.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 18),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3C72),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 22),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 0,
            ),
            child: const Text("Daftar Akun Gratis", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulator(bool isDesktop) {
    // 🔥 OFFICIAL CALCULATION FORMULA (Matching KonsolidasiPage)
    // Normal Ecommerce: Rp 42.000 per package (Jakarta -> Lampung)
    double separateCost = _packageCount * 42000.0;
    
    double weightValGram = double.tryParse(_weightController.text) ?? 0;
    
    // 1. Hitung Berat (Input sekarang dianggap Total Berat)
    double totalWeightKg = weightValGram / 1000;
    // Pembulatan ke atas (> 1kg -> 2kg, dsb)
    double beratBulat = totalWeightKg.ceilToDouble();
    if (beratBulat < 1) beratBulat = 1;

    double consolidatedCost = 0;

    // 2. Biaya Dasar Paket (Berat Terhitung x Harga Per KG)
    consolidatedCost += (beratBulat * _hargaPerKg);

    // 3. Biaya Konsolidasi per Paket (Rp 2.000 / paket)
    consolidatedCost += _packageCount * 2000;
    
    double savings = separateCost - consolidatedCost;
    if (savings < 0) savings = 0;

    return Container(
      key: _simulatorKey,
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40, horizontal: isDesktop ? 100 : 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
      ),
      child: Column(
        children: [
          // Elegant Header Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3C72).withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "ESTIMASI BIAYA",
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1E3C72),
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            "Cek Biaya Konsolidasi Anda",
            style: GoogleFonts.poppins(
              fontSize: isDesktop ? 28 : 22,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1E3C72),
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          Container(
            width: 400, // LEBIH KOMPAK & RAPI
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3C72).withOpacity(0.06),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                )
              ],
              border: Border.all(color: const Color(0xFF1E3C72).withOpacity(0.05)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _simulatorLabel("Jumlah Paket"),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _counterButton(Icons.remove, () {
                            if (_packageCount > 1) setState(() => _packageCount--);
                          }),
                          Text(
                            "$_packageCount Paket",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E3C72)),
                          ),
                          _counterButton(Icons.add, () {
                            if (_packageCount < 20) setState(() => _packageCount++);
                          }),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _simulatorLabel("Total Berat (gram)"),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        onChanged: (val) => setState(() {}),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Contoh: 1500",
                          prefixIcon: const Icon(Icons.monitor_weight_outlined, size: 18),
                          suffixText: "gram",
                          suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade100),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF427AB5), width: 1.5),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const SizedBox(height: 20),
                      const Text(
                        "*Biaya dihitung real-time berdasarkan data master tarif SATUPAKET.",
                        style: TextStyle(fontSize: 10, color: Colors.black38, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E3C72),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Total Biaya", style: TextStyle(color: Colors.white60, fontSize: 11)),
                              SizedBox(height: 2),
                              Text("SATUPAKET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                            ],
                          ),
                          Text(
                            NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(consolidatedCost),
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Anda Hemat", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                            Text(
                              NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(savings),
                              style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Dibandingkan Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(separateCost)} (Ongkir Normal)",
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1E3C72),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Text("MULAI KONSOLIDASI SEKARANG", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
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
  }

  Widget _simulatorLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E3C72),
        ),
      ),
    );
  }

  Widget _counterButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: const Color(0xFF427AB5).withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: const Color(0xFF1E3C72), size: 20),
        ),
      ),
    );
  }


  Widget _buildFooter(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 50),
      color: Colors.white,
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("SATUPAKET", style: GoogleFonts.poppins(color: const Color(0xFF1E3C72), fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  Text("Solusi Logistik Hemat Lampung", style: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 14)),
                ],
              ),
              if (isDesktop)
                Row(
                  children: [
                    _footerLink("Tentang Kami"),
                    const SizedBox(width: 30),
                    _footerLink("Hubungi Kami"),
                    const SizedBox(width: 30),
                    _footerLink("Privasi"),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 60),
          Text("© 2026 Satupaket Technology. All rights reserved.", style: TextStyle(color: Colors.black.withOpacity(0.3), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _footerLink(String text) {
    return Text(text, style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 14, fontWeight: FontWeight.w600));
  }
}
