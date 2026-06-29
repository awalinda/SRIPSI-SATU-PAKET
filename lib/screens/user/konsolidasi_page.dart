import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';
import 'dart:math';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/package_service.dart';
import 'dashboard_user.dart';

class KonsolidasiPage extends StatefulWidget {
  final List<Map<String, dynamic>> selectedPaket;
  final double totalBerat;

  const KonsolidasiPage({
    super.key,
    required this.selectedPaket,
    required this.totalBerat,
  });

  @override
  State<KonsolidasiPage> createState() => _KonsolidasiPageState();
}

class _KonsolidasiPageState extends State<KonsolidasiPage> {
  String tipe = "antar";
  String selectedPembayaran = "Transfer";
  XFile? _proofImage;
  Uint8List? _proofImageBytes;
  bool _isLoading = false;
  Map<String, dynamic>? _selectedAddress;
  String? _selectedAddressId;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Kompres kualitas agar Base64 tidak terlalu besar
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _proofImage = image;
        _proofImageBytes = bytes;
      });
    }
  }

  List<Map<String, dynamic>> pengemasan = [
    {"nama": "Bubble Wrap", "harga": 0, "checked": false},
    {"nama": "Kardus", "harga": 0, "checked": false},
    {"nama": "Kayu", "harga": 0, "checked": false},
  ];

  Map<String, int> pengirimanHarga = {
    "Reguler": 0,
    "Express": 0,
  };

  String selectedPengiriman = "Reguler";
  int hargaPerKg = 0;
  Map<String, dynamic>? paymentInfo;

  @override
  void initState() {
    super.initState();
    _fetchMasterData();
  }

  void _fetchMasterData() {
    // 🔥 Ambil Biaya Master (Real-time Stream)
    FirebaseFirestore.instance.collection('settings').doc('biaya').snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            hargaPerKg = data["hargaPerKg"] ?? 0;
            
            // Update harga pengemasan tapi tetap jaga status 'checked'
            var bwChecked = pengemasan.isNotEmpty ? (pengemasan[0]["checked"] ?? false) : false;
            var kdChecked = pengemasan.length > 1 ? (pengemasan[1]["checked"] ?? false) : false;
            var kyChecked = pengemasan.length > 2 ? (pengemasan[2]["checked"] ?? false) : false;

            pengemasan = [
              {"nama": "Bubble Wrap", "harga": data["bubbleWrap"] ?? 0, "checked": bwChecked},
              {"nama": "Kardus", "harga": data["kardus"] ?? 0, "checked": kdChecked},
              {"nama": "Kayu", "harga": data["kayu"] ?? 0, "checked": kyChecked},
            ];

            pengirimanHarga = {
              "Reguler": data["shippingReguler"] ?? 0,
              "Express": data["shippingExpress"] ?? 0,
            };
          });
        }
      }
    });

    // 🔥 Ambil Data Rekening
    FirebaseFirestore.instance.collection('settings').doc('payment').get().then((doc) {
      if (doc.exists) {
        if (mounted) {
          setState(() {
            paymentInfo = doc.data() as Map<String, dynamic>;
          });
        }
      }
    });
  }

  int get _totalBiayaFoto {
    int total = 0;
    for (var p in widget.selectedPaket) {
      final biaya = p["biayaTambahanFoto"];
      if (biaya != null) total += (biaya as int);
    }
    return total;
  }

  int get totalHarga {
    int total = 0;
    
    // Biaya Tambahan Foto
    total += _totalBiayaFoto;
    
    // Biaya Konsolidasi per Paket (Rp 2.000 / paket)
    total += widget.selectedPaket.length * 2000;

    // Jika pembayaran BUKAN COD (misal Transfer / Antar), maka ada ongkos kirim
    if (selectedPembayaran != "COD") {
      // 1. Hitung Berat (Konversi gram ke KG)
      double beratKg = widget.totalBerat / 1000;
      double beratBulat = beratKg.ceilToDouble();
      if (beratBulat < 1) beratBulat = 1;

      // 2. Biaya Dasar Paket (Berat Terhitung x Harga Per KG)
      total += (beratBulat * hargaPerKg).toInt();

      // 3. Biaya Tambahan Layanan (Reguler/Express)
      int serviceFee = pengirimanHarga[selectedPengiriman] ?? 0;
      total += serviceFee;

      // 4. Biaya Pengemasan (Bubble Wrap, dll)
      if (tipe == "antar") {
        for (var p in pengemasan) {
          if (p["checked"] == true) {
            total += p["harga"] as int;
          }
        }
      }
    }
    
    return total;
  }

  @override
  Widget build(BuildContext context) {
    String formatHarga(int harga) => "Rp${harga.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text(
          "Checkout Konsolidasi", 
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 16)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left_rounded, color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📦 RINCIAN BARANG
            _tidySectionHeader("Daftar Barang"),
            _buildTidyCard(
              child: Column(
                children: widget.selectedPaket.map((p) => _buildTidyItemRow(p)).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // 🚚 METODE TERIMA
            _tidySectionHeader("Metode Penerimaan"),
            Row(
              children: [
                _buildTidyOptionCard("antar", "Antar ke Rumah", Icons.local_shipping_rounded),
                const SizedBox(width: 12),
                _buildTidyOptionCard("ambil", "Ambil di Gudang", Icons.warehouse_rounded),
              ],
            ),
            const SizedBox(height: 20),

            // 🎁 PENGEMASAN (Hanya untuk antar)
            if (tipe == "antar") ...[
              _tidySectionHeader("Layanan Tambahan"),
              _buildTidyCard(
                child: Column(
                  children: pengemasan.map((item) => _buildTidyCheckbox(item, formatHarga)).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ⚡ OPSI PENGIRIMAN
            if (tipe == "antar") ...[
              _tidySectionHeader("Opsi Pengiriman"),
              ...pengirimanHarga.keys.map((key) {
                final harga = pengirimanHarga[key] ?? 0;
                return _buildTidyShippingTile(
                  key, 
                  formatHarga(harga)
                );
              }),
              const SizedBox(height: 20),
            ],

            // 📍 ALAMAT
            _tidySectionHeader(tipe == "antar" ? "Alamat Pengiriman" : "Lokasi Pengambilan"),
            if (tipe == "ambil")
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('warehouse_addresses').snapshots(),
                builder: (context, snapshot) {
                  String displayAddress = "Menunggu alamat gudang...";
                  String title = "Gudang SATUPAKET";
                  String? penerima;

                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                    title = data["namaGudang"] ?? "Gudang Utama";
                    displayAddress = "${data["detail"] ?? ''}, ${data["kecamatan"] ?? ''}, ${data["kota"] ?? ''}, ${data["provinsi"] ?? ''} ${data["kodePos"] ?? ''}";
                    penerima = data["penerima"];
                  }

                  return _buildTidyCard(
                    padding: 16,
                    child: Row(
                      children: [
                        Icon(Icons.location_on_rounded, color: Colors.grey.shade400, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                              const SizedBox(height: 4),
                              if (penerima != null)
                                Text("CP: $penerima", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF427AB5))),
                              Text(
                                displayAddress,
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
              )
            else
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('user')
                    .doc(AuthService().currentUser?.uid)
                    .collection('addresses')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildTidyCard(
                      padding: 16,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const DashboardUser(initialIndex: 4)),
                          );
                        },
                        child: Column(
                          children: [
                            Icon(Icons.add_location_alt_rounded, color: Colors.orange.shade300, size: 30),
                            const SizedBox(height: 10),
                            const Text("Belum Ada Alamat", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text("Klik untuk menambahkan alamat rumah Anda", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  }

                  final addresses = snapshot.data!.docs;
                  // Auto-select first address if none selected
                  if (_selectedAddressId == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _selectedAddressId = addresses.first.id;
                        _selectedAddress = addresses.first.data() as Map<String, dynamic>;
                      });
                    });
                  }

                  return Column(
                    children: [
                      ...addresses.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        bool isSelected = _selectedAddressId == doc.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => setState(() {
                              _selectedAddressId = doc.id;
                              _selectedAddress = data;
                            }),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF427AB5).withOpacity(0.05) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF427AB5) : Colors.grey.shade200,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: const Color(0xFF427AB5).withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ] : [],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded, 
                                    color: isSelected ? const Color(0xFF427AB5) : Colors.grey.shade300, 
                                    size: 24,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              data["label"] ?? "Alamat", 
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900, 
                                                fontSize: 14,
                                                color: isSelected ? const Color(0xFF427AB5) : Colors.black87,
                                              ),
                                            ),
                                            if (isSelected) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF427AB5),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: const Text("Terpilih", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${data["namaLengkap"] ?? ''} | ${data["telepon"] ?? ''}",
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "${data["detail"] ?? ''}, ${data["kecamatan"] ?? ''}, ${data["kabupaten"] ?? ''}, ${data["provinsi"] ?? ''}",
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11, height: 1.4),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      
                      // Tombol Tambah Alamat Baru
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const DashboardUser(initialIndex: 4)),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text("Gunakan Alamat Lain", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF427AB5),
                          side: BorderSide(color: const Color(0xFF427AB5).withOpacity(0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 20),

            // 💰 PEMBAYARAN
            _tidySectionHeader("Metode Pembayaran"),
            if (tipe == "antar")
              _buildTidyCard(
                padding: 16,
                child: Row(
                  children: [
                    Icon(Icons.account_balance_rounded, color: Colors.grey.shade400, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text("Transfer Bank", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF427AB5), size: 18),
                  ],
                ),
              )
            else
              _buildTidyCard(
                padding: 16,
                child: Row(
                  children: [
                    Icon(Icons.payments_rounded, color: Colors.grey.shade400, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text("Bayar di Tempat (COD)", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF427AB5), size: 18),
                  ],
                ),
              ),

            // 🏦 INFO TRANSFER
            if (tipe == "antar" && selectedPembayaran == "Transfer") ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paymentInfo?["bankName"]?.toString().toUpperCase() ?? "BANK INFO", 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)
                    ),
                    const SizedBox(height: 8),
                    Text(
                      paymentInfo?["accountNumber"] ?? "0000-0000-00", 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "a.n. ${paymentInfo?["accountHolder"] ?? "-"}", 
                      style: const TextStyle(color: Colors.white60, fontSize: 11)
                    ),
                  ],
                ),
              ),
            ],

            // 📸 UNGGAH BUKTI PEMBAYARAN
            if (tipe == "antar" && selectedPembayaran == "Transfer") ...[
              const SizedBox(height: 20),
              _tidySectionHeader("Bukti Pembayaran"),
              _buildTidyCard(
                padding: 16,
                child: Column(
                  children: [
                    if (_proofImage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _proofImageBytes != null
                              ? Image.memory(_proofImageBytes!, fit: BoxFit.cover)
                              : const SizedBox(),
                        ),
                      ),
                    
                    if (_proofImage == null)
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.cloud_upload_outlined, color: Colors.grey.shade400, size: 40),
                              const SizedBox(height: 10),
                              const Text("Unggah Bukti Transfer", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text("Format: JPG, PNG (Maks 1MB)", style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                            ],
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text("Ganti Foto"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF427AB5),
                                side: const BorderSide(color: Color(0xFF427AB5)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            onPressed: () => setState(() {
                              _proofImage = null;
                              _proofImageBytes = null;
                            }),
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.05),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
            // 📊 RINGKASAN BIAYA
            _tidySectionHeader("Ringkasan Biaya"),
            _buildTidyCard(
              padding: 16,
              child: Column(
                children: [
                  _buildCostRow(
                    "Total Berat Aktual", 
                    widget.totalBerat < 1000 
                      ? "${widget.totalBerat.toStringAsFixed(0)} g" 
                      : "${(widget.totalBerat / 1000).toStringAsFixed(2)} kg"
                  ),
                  _buildCostRow(
                    "Berat Tagihan (KG)", 
                    "${(widget.totalBerat / 1000).ceil() < 1 ? 1 : (widget.totalBerat / 1000).ceil()} kg",
                    isBold: true
                  ),
                  const Divider(height: 20),
                  _buildCostRow("Biaya Konsolidasi (${widget.selectedPaket.length} Paket)", formatHarga(widget.selectedPaket.length * 2000)),
                  
                  if (selectedPembayaran != "COD") ...[
                    _buildCostRow("Biaya Pengiriman", formatHarga(((widget.totalBerat / 1000).ceil() < 1 ? 1 : (widget.totalBerat / 1000).ceil()) * hargaPerKg)),
                  ],

                  if (tipe == "antar") ...[
                    _buildCostRow("Layanan ${selectedPengiriman}", formatHarga(pengirimanHarga[selectedPengiriman] ?? 0)),
                    ...pengemasan.where((p) => p["checked"] == true).map((p) => 
                      _buildCostRow("Tambahan ${p["nama"]}", formatHarga(p["harga"] as int))
                    ),
                  ],
                  if (_totalBiayaFoto > 0) ...[
                    const Divider(height: 16),
                    ...widget.selectedPaket
                        .where((p) => (p["biayaTambahanFoto"] ?? 0) > 0)
                        .map((p) => _buildCostRow(
                              "Foto: ${p["labelFoto"] ?? 'Tambahan foto'}",
                              formatHarga((p["biayaTambahanFoto"] as int)),
                              isHighlight: true,
                            )),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Total Pembayaran", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text(formatHarga(totalHarga), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF427AB5))),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              width: 160,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF427AB5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Buat Pesanan", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tidySectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Container(width: 3, height: 14, decoration: BoxDecoration(color: const Color(0xFF427AB5), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF374151))),
        ],
      ),
    );
  }

  Widget _buildTidyCard({required Widget child, double padding = 0}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _buildTidyItemRow(Map<String, dynamic> p) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF427AB5), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p["keterangan"] ?? p["nama"] ?? "Tanpa Nama", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(p["resi"] ?? "No Resi", style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
              ],
            ),
          ),
          Text(
            (p["berat"] ?? 0) < 1000 
              ? "${p["berat"]} g" 
              : "${((p["berat"] ?? 0) / 1000).toStringAsFixed(1)} kg", 
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)
          ),
        ],
      ),
    );
  }

  Widget _buildTidyOptionCard(String value, String label, IconData icon) {
    bool isSelected = tipe == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          tipe = value;
          if (value == "ambil") selectedPembayaran = "COD";
          if (value == "antar") selectedPembayaran = "Transfer";
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF427AB5).withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? const Color(0xFF427AB5) : Colors.grey.shade200, width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? const Color(0xFF427AB5) : Colors.grey.shade400, size: 24),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: isSelected ? const Color(0xFF427AB5) : Colors.grey.shade600, fontWeight: FontWeight.w800, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTidyCheckbox(Map<String, dynamic> item, Function format) {
    bool isChecked = item["checked"] ?? false;
    return InkWell(
      onTap: () => setState(() => item["checked"] = !isChecked),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, color: isChecked ? const Color(0xFF427AB5) : Colors.grey.shade300, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(item["nama"], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
            Text(format(item["harga"] as int), style: const TextStyle(color: Color(0xFF427AB5), fontWeight: FontWeight.w800, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildTidyShippingTile(String key, String harga) {
    bool isSelected = selectedPengiriman == key;
    return GestureDetector(
      onTap: () => setState(() => selectedPengiriman = key),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF427AB5) : Colors.grey.shade200, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: isSelected ? const Color(0xFF427AB5) : Colors.grey.shade300, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(key, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  Text("Biaya: $harga", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTidyPaymentCard(String value, String label, IconData icon) {
    bool isSelected = selectedPembayaran == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedPembayaran = value),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? const Color(0xFF427AB5) : Colors.grey.shade200, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? const Color(0xFF427AB5) : Colors.grey.shade400, size: 18),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: isSelected ? const Color(0xFF427AB5) : Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCostRow(String label, String value, {bool isBold = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isHighlight ? const Color(0xFF427AB5) : Colors.grey.shade600,
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              fontSize: 13,
              color: isHighlight ? const Color(0xFF427AB5) : (isBold ? const Color(0xFF111827) : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitOrder() async {
    // 🛑 VALIDASI ALAMAT (Jika Antar ke Rumah)
    if (tipe == "antar" && _selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.location_off_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text("Harap tambahkan alamat pengiriman!", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      );
      return;
    }

    // 🛑 VALIDASI TRANSFER
    if (tipe == "antar" && selectedPembayaran == "Transfer" && _proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text("Harap unggah bukti pembayaran!", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String resi = "SP${Random().nextInt(999999).toString().padLeft(6, '0')}";
      
      String? buktiUrl;
      if (_proofImage != null) {
        buktiUrl = await PackageService().uploadImageToStorage(_proofImage!);
      }

      Map<String, dynamic> order = {
          "userId": AuthService().currentUser?.uid,
          "nama": AuthService().currentUser?.displayName ?? "User",
          "resi": resi,
          "total": totalHarga,
          "status": "Menunggu Konfirmasi",
          "paket": widget.selectedPaket,
          "tipe": tipe,
          "pengiriman": tipe == "antar" ? selectedPengiriman : "Ambil",
          "pembayaran": selectedPembayaran,
          "alamatTujuan": tipe == "antar" ? _selectedAddress : "Ambil di Gudang",
        };
        // Save payment proof as URL
        if (buktiUrl != null) {
          order["buktiPembayaran"] = buktiUrl;
        }

      await OrderService.tambahOrder(order);

      // 🔥 HAPUS DARI PAKET SAYA
      final String? uid = AuthService().currentUser?.uid;
      if (uid != null) {
        List<String> packageIds = widget.selectedPaket
            .map((p) => p["id"] as String)
            .where((id) => id.isNotEmpty)
            .toList();
        if (packageIds.isNotEmpty) {
          await PackageService().deletePackages(uid, packageIds);
        }
      }

      if (!mounted) return;
      
      // 🔥 REDIRECT KE KONSOLIDASI (STATUS PAGE)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const DashboardUser(initialIndex: 2)),
        (route) => false,
      );

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text("Checkout Berhasil", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text("Pesanan dengan resi $resi berhasil dibuat! Silakan pantau status pengiriman Anda di menu Konsolidasi."),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF427AB5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Mengerti"),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal membuat pesanan: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

