import 'package:flutter/material.dart';
import 'dart:convert';

class InvoicePage extends StatelessWidget {
  final List<dynamic> paket;
  final String tipe;
  final int total;
  final double? rating;
  final String? reviewText;
  final String? reviewImageBase64;

  const InvoicePage({
    super.key,
    required this.paket,
    required this.tipe,
    required this.total,
    this.rating,
    this.reviewText,
    this.reviewImageBase64,
  });

  @override
  Widget build(BuildContext context) {
    String formatHarga(int harga) => "Rp${harga.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Detail Pesanan", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🔹 CARD UTAMA
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Status Pesanan", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Text("AKTIF", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // 📦 LIST BARANG
                  const Text("Daftar Barang", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  const SizedBox(height: 15),
                  ...paket.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF427AB5), size: 18),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p["nama"] ?? "-", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(p["resi"] ?? "-", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                            ],
                          ),
                        ),
                        Text(
                          (p["berat"] ?? 0) < 1000 
                            ? "${p["berat"]} g" 
                            : "${((p["berat"] ?? 0) / 1000).toStringAsFixed(1)} kg", 
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)
                        ),
                      ],
                    ),
                  )).toList(),

                  const Divider(height: 40),

                  // 🚚 INFO PENGIRIMAN
                  _buildInfoRow("Metode Penerimaan", tipe == "antar" ? "Antar ke Rumah" : "Ambil di Gudang"),
                  _buildInfoRow("Estimasi Tiba", "2 - 4 Hari Kerja"),
                  
                  const SizedBox(height: 20),
                  const Text("Alamat Tujuan", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_rounded, color: Color(0xFF427AB5), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tipe == "antar" 
                            ? "Rumah Utama\nJl. Pangeran Antasari No.128, Bandar Lampung"
                            : "Warehouse SATUPAKET\nJl. Pangeran Antasari No.128, Bandar Lampung",
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 40),

                  // 💰 RINGKASAN BIAYA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Pembayaran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(formatHarga(total), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF427AB5))),
                    ],
                  ),
                ],
              ),
            ),

            if (rating != null) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Ulasan Anda", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                    const SizedBox(height: 15),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < rating! ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 20,
                        );
                      }),
                    ),
                    if (reviewText != null && reviewText!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        reviewText!,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
                      ),
                    ],
                    if (reviewImageBase64 != null && reviewImageBase64!.isNotEmpty) ...[
                      const SizedBox(height: 15),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.memory(
                          base64Decode(reviewImageBase64!),
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),

            // 🔹 BUTTON BACK
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: const Text("Tutup Detail", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
