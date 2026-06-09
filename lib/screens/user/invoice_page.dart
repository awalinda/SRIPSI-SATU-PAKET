import 'package:flutter/material.dart';
import 'dart:convert';

class InvoicePage extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const InvoicePage({
    super.key,
    required this.orderData,
  });

  @override
  Widget build(BuildContext context) {
    String formatHarga(int harga) => "Rp${harga.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
    
    List<dynamic> paket = orderData["paket"] ?? [];
    String tipe = orderData["tipe"] ?? "antar";
    int total = (orderData["total"] ?? 0).toInt();
    String status = orderData["status"] ?? "Menunggu Konfirmasi";
    String resi = orderData["resi"] ?? "-";
    String pembayaran = orderData["pembayaran"] ?? "Transfer";
    String kurir = orderData["pengiriman"] ?? "-";

    // Format Alamat
    dynamic rawAlamat = orderData["alamatTujuan"] ?? orderData["alamat"] ?? "-";
    String finalAlamat = "-";
    if (rawAlamat is Map) {
      finalAlamat = "${rawAlamat['namaLengkap'] ?? ''}, ${rawAlamat['telepon'] ?? ''}\n${rawAlamat['detail'] ?? ''}, ${rawAlamat['desa'] ?? ''}, ${rawAlamat['kecamatan'] ?? ''}, ${rawAlamat['kabupaten'] ?? ''}, ${rawAlamat['provinsi'] ?? ''} ${rawAlamat['kodePos'] ?? ''}";
    } else if (rawAlamat is String) {
      finalAlamat = rawAlamat;
    }

    // Warna status
    Color statusColor = Colors.blue;
    if (status == "Selesai") statusColor = Colors.green;
    if (status == "Ditolak") statusColor = Colors.red;
    if (status == "Diproses" || status == "Dikirim") statusColor = Colors.orange;

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
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildInfoRow("Nomor Pesanan (Resi)", resi),
                  const SizedBox(height: 10),

                  // 📦 LIST BARANG
                  const Text("Daftar Barang", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  const SizedBox(height: 15),
                  ...paket.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Builder(
                          builder: (context) {
                            String? firstImage;
                            if (p["images"] != null && (p["images"] as List).isNotEmpty) {
                              firstImage = (p["images"] as List).first.toString();
                            }
                            return Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
                              child: firstImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.memory(
                                        base64Decode(firstImage),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(Icons.inventory_2_rounded, color: Color(0xFF427AB5), size: 18),
                            );
                          }
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
                  _buildInfoRow("Metode Penerimaan", tipe == "antar" ? "Antar ke Rumah ($kurir)" : "Ambil di Gudang"),
                  _buildInfoRow("Metode Pembayaran", pembayaran),
                  
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
                          finalAlamat,
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

            const SizedBox(height: 30),

            // 🔹 BUTTON BACK
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF427AB5).withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: const Text("Tutup Detail", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF427AB5))),
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
