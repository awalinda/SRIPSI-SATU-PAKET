import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/address_service.dart';
import '../../widgets/custom_notification.dart';

class AlamatPage extends StatefulWidget {
  const AlamatPage({super.key});

  @override
  State<AlamatPage> createState() => _AlamatPageState();
}

class _AlamatPageState extends State<AlamatPage> {
  bool showForm = false;
  bool isLoading = false;
  String? editingId; // Track ID buat Edit

  // DATA PROVINSI & KABUPATEN
  String selectedProvinsi = "Lampung";
  String? selectedKabupaten;

  final List<String> kabupatenLampung = [
    "Bandar Lampung",
    "Metro",
    "Lampung Selatan",
    "Lampung Tengah",
    "Lampung Timur",
    "Lampung Utara",
    "Lampung Barat",
    "Tulang Bawang",
    "Tulang Bawang Barat",
    "Way Kanan",
    "Pesawaran",
    "Pringsewu",
    "Pesisir Barat",
    "Mesuji",
    "Tanggamus",
  ];

  // DATA KECAMATAN (Dinamis berdasarkan Kabupaten)
  // DATA KECAMATAN (Dinamis berdasarkan Kabupaten - Seluruh Lampung)
  final Map<String, List<String>> kecamatanMap = {
    "Bandar Lampung": [
      "Bumi Waras", "Enggal", "Kedamaian", "Kedaton", "Kemiling", "Labuhan Ratu",
      "Langgkapura", "Panjang", "Rajabasa", "Sukabumi", "Sukarame", "Tanjung Karang Barat",
      "Tanjung Karang Pusat", "Tanjung Karang Timur", "Tanjung Senang", "Teluk Betung Barat",
      "Teluk Betung Selatan", "Teluk Betung Timur", "Teluk Betung Utara", "Way Halim"
    ],
    "Metro": [
      "Metro Barat", "Metro Pusat", "Metro Selatan", "Metro Timur", "Metro Utara"
    ],
    "Lampung Selatan": [
      "Bakauheni", "Candipuro", "Jati Agung", "Kalianda", "Katibung", "Ketapang", 
      "Merbau Mataram", "Natar", "Palas", "Penengahan", "Rajabasa", "Sidomulyo", 
      "Sragi", "Tanjung Bintang", "Tanjung Sari", "Way Panji", "Way Sulan"
    ],
    "Lampung Tengah": [
      "Anak Ratu Aji", "Anak Tuha", "Bandar Mataram", "Bandar Surabaya", "Bangunrejo", 
      "Bekri", "Bumi Nabung", "Bumi Ratu Nuban", "Gunung Sugih", "Kalirejo", "Kota Gajah", 
      "Padang Ratu", "Pubian", "Punggur", "Putra Rumbia", "Rumbia", "Selagai Lingga", 
      "Sendang Agung", "Seputih Agung", "Seputih Banyak", "Seputih Mataram", "Seputih Raman", 
      "Seputih Surabaya", "Terbanggi Besar", "Terusan Nunyai", "Trimurjo", "Way Pengubuan", "Way Seputih"
    ],
    "Lampung Timur": [
      "Bandar Sribhawono", "Batanghari", "Batanghari Nuban", "Braja Selebah", "Bumi Agung", 
      "Gunung Pelindung", "Jabung", "Labuhan Maringgai", "Labuhan Ratu", "Marga Sekampung", 
      "Marga Tiga", "Mataram Baru", "Melinting", "Metro Kibang", "Pasir Sakti", "Pekalongan", 
      "Purbolinggo", "Raman Utara", "Sekampung", "Sekampung Udik", "Sukadana", "Waway Karya", 
      "Way Bungur", "Way Jepara"
    ],
    "Lampung Utara": [
      "Abung Barat", "Abung Kunang", "Abung Pekurun", "Abung Selatan", 
      "Abung Semuli", "Abung Surakarta", "Abung Tengah", "Abung Timur", 
      "Abung Tinggi", "Blambangan Pagar", "Bukit Kemuning", "Bunga Mayang", 
      "Hulu Sungkai", "Kotabumi", "Kotabumi Selatan", "Kotabumi Utara", 
      "Muara Sungkai", "Sungkai Utara", "Sungkai Barat", "Sungkai Jaya", 
      "Sungkai Selatan", "Sungkai Tengah", "Tanjung Raja"
    ],
    "Lampung Barat": [
      "Air Hitam", "Balik Bukit", "Bandar Negeri Suoh", "Batu Brak", "Batu Ketulis", 
      "Belalau", "Gedung Surian", "Kebun Tebu", "Lumbok Seminung", "Pagar Dewa", 
      "Sekincau", "Sukau", "Sumber Jaya", "Suoh", "Way Tenong"
    ],
    "Tulang Bawang": [
      "Banjar Agung", "Banjar Baru", "Banjar Margo", "Dente Teladas", "Gedung Aji", 
      "Gedung Aji Baru", "Gedung Meneng", "Menggala", "Menggala Timur", "Meraksa Aji", 
      "Penawar Aji", "Penawar Tama", "Rawa Jitu Selatan", "Rawa Jitu Timur", "Rawa Pitu"
    ],
    "Tulang Bawang Barat": [
      "Batu Putih", "Gunung Agung", "Gunung Terang", "Lambu Kibang", "Pagar Dewa", 
      "Tulang Bawang Tengah", "Tulang Bawang Udik", "Tumijajar", "Way Kenanga"
    ],
    "Way Kanan": [
      "Banjit", "Baradatu", "Blambangan Umpu", "Bumi Agung", "Buay Bahuga", 
      "Gunung Labuhan", "Kasui", "Negara Batin", "Negeri Agung", "Negeri Besar", 
      "Pakuan Ratu", "Rebang Tangkas", "Umpu Semenguk", "Way Tuba"
    ],
    "Pesawaran": [
      "Gedong Tataan", "Kedondong", "Marga Punduh", "Negeri Katon", "Padang Cermin", 
      "Punduh Pedada", "Tegineneng", "Teluk Pandan", "Way Lima", "Way Khilau", "Way Ratai"
    ],
    "Pringsewu": [
      "Adiluwih", "Ambarawa", "Banyumas", "Gading Rejo", "Pagelaran", 
      "Pagelaran Utara", "Pardasuka", "Pringsewu", "Sukoharjo"
    ],
    "Pesisir Barat": [
      "Bangkunat", "Karya Penggawa", "Krui Selatan", "Lemong", "Ngambur", 
      "Ngaras", "Pesisir Selatan", "Pesisir Tengah", "Pesisir Utara", "Pulau Pisang", "Way Krui"
    ],
    "Mesuji": [
      "Mesuji", "Mesuji Timur", "Panca Jaya", "Rawa Jitu Utara", 
      "Simpang Pematang", "Tanjung Raya", "Way Serdang"
    ],
    "Tanggamus": [
      "Air Naningan", "Bandar Negeri Semuong", "Bulok", "Cukuh Balak", "Gisting", 
      "Gunung Alip", "Kelumbayan", "Kelumbayan Barat", "Kota Agung", "Kota Agung Barat", 
      "Kota Agung Timur", "Limau", "Pugung", "Pulau Panggung", "Semaka", "Sumberejo", 
      "Talang Padang", "Ulu Belu", "Wonosobo"
    ]
  };

  // 🔹 CONTROLLERS
  final _labelController = TextEditingController();
  final _namaController = TextEditingController();
  final _kecamatanController = TextEditingController();
  final _desaController = TextEditingController();
  final _detailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    _namaController.dispose();
    _kecamatanController.dispose();
    _desaController.dispose();
    _detailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _labelController.clear();
    _namaController.clear();
    _kecamatanController.clear();
    _desaController.clear();
    _detailController.clear();
    _phoneController.clear();
    selectedKabupaten = null;
    editingId = null;
  }

  void _startEdit(String id, Map<String, dynamic> data) {
    setState(() {
      editingId = id;
      showForm = true;
      _labelController.text = data['label'] ?? "";
      selectedKabupaten = data['kabupaten'];
      _namaController.text = data['namaLengkap'] ?? "";
      _kecamatanController.text = data['kecamatan'] ?? "";
      _desaController.text = data['desa'] ?? "";
      _detailController.text = data['detail'] ?? "";
      _phoneController.text = data['telepon'] ?? "";
    });
  }

  Future<void> _saveAddress() async {
    if (_labelController.text.isEmpty || 
        _namaController.text.isEmpty || 
        selectedKabupaten == null || 
        _kecamatanController.text.isEmpty || 
        _desaController.text.isEmpty || 
        _phoneController.text.isEmpty) {
      CustomNotification.showError(context, "Harap isi semua kolom yang wajib");
      return;
    }

    setState(() => isLoading = true);
    try {
      final data = {
        "label": _labelController.text,
        "provinsi": selectedProvinsi,
        "kabupaten": selectedKabupaten,
        "namaLengkap": _namaController.text,
        "kecamatan": _kecamatanController.text,
        "desa": _desaController.text,
        "detail": _detailController.text,
        "telepon": _phoneController.text,
      };

      if (editingId != null) {
        await AddressService().updateAddress(editingId!, data);
      } else {
        await AddressService().addAddress(data);
      }

      setState(() {
        showForm = false;
        _resetForm();
      });
      if (mounted) {
        CustomNotification.showSuccess(context, editingId != null ? "Alamat diperbarui!" : "Alamat disimpan!");
      }
    } catch (e) {
      if (mounted) CustomNotification.showError(context, "Gagal: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      padding: const EdgeInsets.all(20),
      child: showForm ? buildForm() : buildList(),
    );
  }

  // ================= LIST =================
  Widget buildList() {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return StreamBuilder<QuerySnapshot>(
      stream: AddressService().getAddresses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final addresses = snapshot.hasData ? snapshot.data!.docs : [];
        final addressCount = addresses.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Alamat Saya",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (addressCount >= 3) {
                      CustomNotification.showError(context, "Maksimal 3 alamat. Hapus salah satu untuk menambahkan yang baru.");
                    } else {
                      setState(() => showForm = true);
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Tambah Alamat"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: addressCount >= 3 ? Colors.grey : const Color(0xFF427AB5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Expanded(
              child: addresses.isEmpty
                  ? const Center(
                      child: Text("Belum ada alamat tersimpan.", style: TextStyle(color: Colors.grey)),
                    )
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isDesktop ? 3 : 1, // 🔥 Baris Sampingan
                        mainAxisSpacing: 15,
                        crossAxisSpacing: 15,
                        childAspectRatio: isDesktop ? 1.5 : 2.0,
                      ),
                      itemCount: addresses.length,
                      itemBuilder: (context, index) {
                        var doc = addresses[index];
                        var data = doc.data() as Map<String, dynamic>;
                        
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFF1E3C72).withOpacity(0.05)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1E3C72).withOpacity(0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF427AB5).withOpacity(0.05),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                  border: Border(bottom: BorderSide(color: const Color(0xFF427AB5).withOpacity(0.05))),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      data['label'] ?? "Tanpa Label",
                                      style: const TextStyle(color: Color(0xFF1E3C72), fontWeight: FontWeight.w900, fontSize: 13),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: Color(0xFF427AB5), size: 18),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _startEdit(doc.id, data),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text("Hapus Alamat"),
                                                content: const Text("Apakah Anda yakin ingin menghapus alamat ini?"),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text("Batal"),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      AddressService().deleteAddress(doc.id);
                                                      Navigator.pop(context);
                                                      CustomNotification.showSuccess(context, "Alamat dihapus");
                                                    },
                                                    child: const Text("Hapus", style: TextStyle(color: Colors.red)),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data['namaLengkap'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${data['detail']}, ${data['desa']}, ${data['kecamatan']}",
                                      style: const TextStyle(fontSize: 11, color: Colors.black87),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      "${data['kabupaten']}, ${data['provinsi']} ${data['kodePos']}",
                                      style: const TextStyle(fontSize: 11, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 4),
                                    Text("Telp: ${data['telepon']}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // ================= FORM =================
  Widget buildForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            editingId != null ? "Perbarui Alamat Pengiriman" : "Tambah Alamat Pengiriman Baru",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          inputField(_labelController, "Label Alamat", isRequired: true),
          inputField(_namaController, "Nama Penerima", isRequired: true),

          // 🔹 PROVINSI (FIX)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Provinsi"),
              const SizedBox(height: 5),
              TextField(
                readOnly: true,
                controller: TextEditingController(text: selectedProvinsi),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // 🔹 KABUPATEN DROPDOWN
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text("Kabupaten"),
                  Text(" *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                value: selectedKabupaten,
                hint: const Text("Pilih Kabupaten"),
                items: kabupatenLampung.map((kab) {
                  return DropdownMenuItem(value: kab, child: Text(kab));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedKabupaten = value;
                    _kecamatanController.clear(); // Reset kecamatan ketika kabupaten berubah
                  });
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // 🔹 KECAMATAN (Dropdown Dinamis atau TextField fallback)
          if (selectedKabupaten != null && kecamatanMap.containsKey(selectedKabupaten)) 
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Text("Kecamatan"),
                    Text(" *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 5),
                DropdownButtonFormField<String>(
                  value: kecamatanMap[selectedKabupaten]!.contains(_kecamatanController.text) ? _kecamatanController.text : null,
                  hint: const Text("Pilih Kecamatan"),
                  items: kecamatanMap[selectedKabupaten]!.map((kec) {
                    return DropdownMenuItem(value: kec, child: Text(kec));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _kecamatanController.text = value ?? "";
                    });
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
              ],
            )
          else 
            inputField(_kecamatanController, "Kecamatan", isRequired: true),

          inputField(_desaController, "Nama Desa", isRequired: true),
          inputField(_detailController, "Detail Alamat (Jalan, No Rumah, dll)"),
          inputField(_phoneController, "Nomor Telepon Penerima", keyboardType: TextInputType.phone, isRequired: true),

          const SizedBox(height: 30),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() => showForm = false);
                  _resetForm();
                },
                child: const Text("Batal"),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: isLoading ? null : _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF427AB5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(editingId != null ? "Perbarui Alamat" : "Simpan Alamat", style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= INPUT =================
  Widget inputField(TextEditingController controller, String label, {TextInputType keyboardType = TextInputType.text, bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label),
              if (isRequired) const Text(" *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
