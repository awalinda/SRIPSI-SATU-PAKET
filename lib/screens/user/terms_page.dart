import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(25)),
        ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(25),
            child: Row(
              children: [
                const Icon(Icons.description_rounded, color: Color(0xFF427AB5)),
                const SizedBox(width: 12),
                const Text(
                  "Syarat & Ketentuan",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTermSection("1. Definisi Service", "SATUPAKET adalah platform jasa konsolidasi barang yang membantu pengiriman barang dari berbagai sumber ke satu alamat tujuan dengan sistem efisiensi biaya."),
                  _buildTermSection("2. Tanggung Jawab Barang", "Barang yang dikirim ke gudang kami wajib menyertakan User ID yang valid. Kami tidak bertanggung jawab atas barang yang hilang atau tertahan karena tidak adanya identitas pemilik yang jelas."),
                  _buildTermSection("3. Larangan Barang", "Dilarang mengirimkan barang ilegal, narkotika, senjata api, bahan peledak, atau barang lain yang dilarang oleh hukum Republik Indonesia."),
                  _buildTermSection("4. Biaya & Pembayaran", "Biaya dihitung berdasarkan berat aktual atau volume (mana yang lebih besar). Pembayaran wajib dilakukan sebelum barang dikirim dari gudang konsolidasi ke alamat tujuan."),
                  _buildTermSection("5. Keamanan Data", "Data pribadi Anda hanya digunakan untuk keperluan operasional pengiriman dan tidak akan disebarluaskan kepada pihak ketiga tanpa izin."),
                  const SizedBox(height: 30),
                  const Text("Dengan mencentang kotak setuju, Anda dianggap telah membaca dan menyetujui seluruh ketentuan di atas.", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }
  Widget _buildTermSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF427AB5))),
          const SizedBox(height: 8),
          Text(content, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5)),
        ],
      ),
    );
  }
}
