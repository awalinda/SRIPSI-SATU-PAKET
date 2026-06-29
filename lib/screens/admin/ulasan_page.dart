import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:satupaket/utils/image_helper.dart';

class UlasanPage extends StatefulWidget {
  const UlasanPage({super.key});

  @override
  State<UlasanPage> createState() => _UlasanPageState();
}

class _UlasanPageState extends State<UlasanPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool get isMobile => MediaQuery.of(context).size.width < 800;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            const Text(
              "Ulasan Pelanggan",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E3C72),
              ),
            ),
            const SizedBox(height: 15),
            _buildSearchBar(),
          ] else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Ulasan Pelanggan",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E3C72),
                  ),
                ),
                _buildSearchBar(),
              ],
            ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('rating', isNull: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text("Belum ada ulasan dari pelanggan.", style: TextStyle(color: Colors.grey)),
                  );
                }

                // Filter & Sort client-side
                List<QueryDocumentSnapshot> filteredDocs = docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String nama = (data['nama'] ?? '').toString().toLowerCase();
                  String resi = (data['resi'] ?? '').toString().toLowerCase();
                  return nama.contains(_searchQuery) || resi.contains(_searchQuery);
                }).toList();

                filteredDocs.sort((a, b) {
                  var dataA = a.data() as Map<String, dynamic>;
                  var dataB = b.data() as Map<String, dynamic>;
                  Timestamp? timeA = dataA['reviewDate'] as Timestamp?;
                  Timestamp? timeB = dataB['reviewDate'] as Timestamp?;
                  if (timeA == null) return 1;
                  if (timeB == null) return -1;
                  return timeB.compareTo(timeA);
                });

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text("Tidak ditemukan ulasan yang cocok.", style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data = filteredDocs[index].data() as Map<String, dynamic>;
                    
                    final String nama = data['nama']?.toString() ?? 'Anonim';
                    final String resi = data['resi']?.toString() ?? '-';
                    
                    String paket = '-';
                    if (data['paket'] is Map) {
                      paket = data['paket']['kategori']?.toString() ?? 'Paket';
                    } else if (data['paket'] is List) {
                      var lst = data['paket'] as List;
                      if (lst.isNotEmpty && lst.first is Map) {
                        paket = lst.first['kategori']?.toString() ?? 'Paket';
                      } else {
                        paket = lst.join(', ');
                      }
                    } else {
                      paket = data['paket']?.toString() ?? '-';
                    }
                    if (paket.length > 50) paket = 'Paket';

                    String tipe = '-';
                    if (data['tipe'] is Map) {
                      tipe = data['tipe']['nama']?.toString() ?? '-';
                    } else if (data['tipe'] is List) {
                      var lst = data['tipe'] as List;
                      if (lst.isNotEmpty && lst.first is Map) {
                        tipe = lst.first['nama']?.toString() ?? '-';
                      } else {
                        tipe = lst.join(', ');
                      }
                    } else {
                      tipe = data['tipe']?.toString() ?? '-';
                    }
                    if (tipe.length > 50) tipe = '-';

                    final double rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
                    final String reviewText = data['reviewText']?.toString() ?? '';
                    
                    String? reviewImageBase64;
                    if (data['reviewImageBase64'] is String) {
                      reviewImageBase64 = data['reviewImageBase64'];
                    } else if (data['reviewImageBase64'] is List) {
                      var lst = data['reviewImageBase64'] as List;
                      if (lst.isNotEmpty) reviewImageBase64 = lst.first.toString();
                    }
                    
                    String tanggal = "";
                    if (data['reviewDate'] != null) {
                      tanggal = DateFormat("dd MMM yyyy, HH:mm").format((data['reviewDate'] as Timestamp).toDate());
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF427AB5).withOpacity(0.1),
                                radius: 25,
                                child: Text(
                                  nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF427AB5),
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nama,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Resi: $resi • Paket $paket ($tipe)",
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                    ),
                                    if (tanggal.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        tanggal,
                                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.amber.shade200),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                          if (reviewText.isNotEmpty) ...[
                            const SizedBox(height: 15),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xffF9FAFB),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Text(
                                reviewText,
                                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87),
                              ),
                            ),
                          ],
                          if (reviewImageBase64 != null && reviewImageBase64.isNotEmpty) ...[
                            const SizedBox(height: 15),
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => Dialog(
                                    backgroundColor: Colors.transparent,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: reviewImageBase64!.startsWith('http') ? Image.network(ImageHelper.getCorsUrl(reviewImageBase64), fit: BoxFit.contain) : Image.memory(base64Decode(reviewImageBase64!), fit: BoxFit.contain),
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: reviewImageBase64.startsWith('http') 
                                  ? Image.network(
                                      ImageHelper.getCorsUrl(reviewImageBase64),
                                      height: 120,
                                      width: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                    )
                                  : Image.memory(
                                      base64Decode(reviewImageBase64),
                                      height: 120,
                                      width: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                    ),
                              ),
                            )
                          ],
                        ],
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

  Widget _buildSearchBar() {
    return SizedBox(
      width: isMobile ? double.infinity : 300,
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: "Cari nama atau resi...",
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFF427AB5), width: 1.5),
          ),
        ),
      ),
    );
  }
}
