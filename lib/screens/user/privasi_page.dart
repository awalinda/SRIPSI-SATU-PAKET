import 'package:flutter/material.dart';

class PrivasiPage extends StatelessWidget {
  const PrivasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //  JUDUL
          const Text(
            "Info Privasi",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E3C72)),
          ),
          const SizedBox(height: 20),

          _buildSection(
            "Pilihan Anda",
            "Anda memiliki hak untuk mengelola bagaimana informasi pribadi Anda dikumpulkan dan digunakan. "
            "Jika diperlukan, Anda dapat meminta salinan data yang terkait dengan akun Anda setelah kami memverifikasi identitas Anda. "
            "Anda juga dapat meminta kami untuk memperbarui, memperbaiki, atau menyesuaikan informasi apa pun yang sudah tidak akurat. "
            "Untuk mengajukan permintaan, silakan hubungi kami melalui detail kontak yang tercantum di bawah ini.",
          ),

          const SizedBox(height: 20),

          _buildSection(
            "Akses, Pembaruan, dan Penghapusan",
            "Bergantung pada peraturan yang berlaku di lokasi Anda, Anda dapat:\n\n"
            "1. Meminta akses ke informasi pribadi tertentu yang tersimpan di akun Anda;\n"
            "2. Meminta kami untuk merevisi atau memperbaiki informasi yang Anda yakini perlu diperbarui;\n"
            "3. Meminta kami untuk menghapus detail pribadi tertentu dari sistem kami.\n\n"
            "Harap diperhatikan bahwa beberapa data tidak dapat dihapus secara langsung atau sepenuhnya, karena kami mungkin diwajibkan untuk menyimpan catatan tertentu untuk keperluan hukum, keamanan, atau operasional. "
            "Hal ini dapat mencakup respons terhadap pertanyaan resmi atau penyimpanan riwayat transaksi.\n\n"
            "Jika Anda ingin menggunakan hak-hak ini, silakan ikuti petunjuk yang terdapat pada bagian “Hubungi Kami”. "
            "Demi perlindungan Anda, kami mungkin meminta verifikasi tambahan untuk memastikan bahwa setiap pembaruan atau permintaan diproses dengan aman.",
          ),
          
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF427AB5)),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.6),
          ),
        ],
      ),
    );
  }
}
