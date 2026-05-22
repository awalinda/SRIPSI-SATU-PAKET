import 'package:flutter/material.dart';

class PrivasiPage extends StatelessWidget {
  const PrivasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 TITLE
            const Text(
              "Info Privasi",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E3C72),
              ),
            ),

            const SizedBox(height: 25),

            // 🔹 SECTION 1
            _buildSection(
              title: "Pilihan Anda",
              content:
                  "Anda memiliki hak untuk mengelola bagaimana informasi pribadi Anda dikumpulkan dan digunakan. "
                  "Anda dapat meminta salinan data, memperbarui informasi, atau menyesuaikan data yang tidak akurat.",
            ),

            const SizedBox(height: 20),

            // 🔹 SECTION 2
            _buildSection(
              title: "Akses, Pembaruan, dan Penghapusan",
              content:
                  "1. Meminta akses data pribadi\n"
                  "2. Memperbaiki informasi\n"
                  "3. Menghapus data tertentu\n\n"
                  "Beberapa data tetap disimpan untuk kebutuhan hukum dan keamanan.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity, // 🔥 biar full lebar
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF427AB5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
