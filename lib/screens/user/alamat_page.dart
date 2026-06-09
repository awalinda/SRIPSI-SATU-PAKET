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

  // 🔹 CONTROLLERS
  final _labelController = TextEditingController();
  final _kotaController = TextEditingController();
  final _namaController = TextEditingController();
  final _kecamatanController = TextEditingController();
  final _desaController = TextEditingController();
  final _detailController = TextEditingController();
  final _kodeposController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    _kotaController.dispose();
    _namaController.dispose();
    _kecamatanController.dispose();
    _desaController.dispose();
    _detailController.dispose();
    _kodeposController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _labelController.clear();
    _kotaController.clear();
    _namaController.clear();
    _kecamatanController.clear();
    _desaController.clear();
    _detailController.clear();
    _kodeposController.clear();
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
      _kotaController.text = data['kota'] ?? "";
      _namaController.text = data['namaLengkap'] ?? "";
      _kecamatanController.text = data['kecamatan'] ?? "";
      _desaController.text = data['desa'] ?? "";
      _detailController.text = data['detail'] ?? "";
      _kodeposController.text = data['kodePos'] ?? "";
      _phoneController.text = data['telepon'] ?? "";
    });
  }

  Future<void> _saveAddress() async {
    if (selectedKabupaten == null || _labelController.text.isEmpty || _namaController.text.isEmpty) {
      CustomNotification.showError(context, "Harap isi Label, Nama, dan Kabupaten");
      return;
    }

    setState(() => isLoading = true);
    try {
      final data = {
        "label": _labelController.text,
        "provinsi": selectedProvinsi,
        "kabupaten": selectedKabupaten,
        "kota": _kotaController.text,
        "namaLengkap": _namaController.text,
        "kecamatan": _kecamatanController.text,
        "desa": _desaController.text,
        "detail": _detailController.text,
        "kodePos": _kodeposController.text,
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
          
          inputField(_labelController, "Label Alamat (Contoh: Rumah, Kantor)"),

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
              const Text("Kabupaten"),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                value: selectedKabupaten,
                hint: const Text("Pilih Kabupaten"),
                items: kabupatenLampung.map((kab) {
                  return DropdownMenuItem(value: kab, child: Text(kab));
                }).toList(),
                onChanged: (value) => setState(() => selectedKabupaten = value),
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

          inputField(_kotaController, "Kota"),
          inputField(_namaController, "Nama Penerima"),
          inputField(_kecamatanController, "Kecamatan"),
          inputField(_desaController, "Nama Desa"),
          inputField(_detailController, "Detail Alamat (Jalan, No Rumah, dll)"),
          inputField(_kodeposController, "Kode Pos"),
          inputField(_phoneController, "Nomor Telepon Penerima", keyboardType: TextInputType.phone),

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
  Widget inputField(TextEditingController controller, String label, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
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
