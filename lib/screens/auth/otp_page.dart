import 'package:flutter/material.dart';

class OtpPage extends StatefulWidget {
  final String phone;
  const OtpPage({super.key, required this.phone});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final List<TextEditingController> otpController = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final String correctOtp = "123456"; // 🔥 dummy OTP

  void verifyOtp() {
    String inputOtp = otpController.map((e) => e.text).join();

    if (inputOtp == correctOtp) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Verifikasi Berhasil")));

      // 👉 pindah ke dashboard / login
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Kode OTP salah")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF427AB5), Color(0xFF3F7CAC), Color(0xFFBDEBFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: Center(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white30),
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock, size: 50, color: Colors.white),

                const SizedBox(height: 20),

                const Text(
                  "Verifikasi OTP",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Kode dikirim ke ${widget.phone}",
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                // 🔥 INPUT OTP
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 45,
                      child: TextField(
                        controller: otpController[index],
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                        maxLength: 1,
                        decoration: InputDecoration(
                          counterText: "",
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.25),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            FocusScope.of(context).nextFocus();
                          }
                        },
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 30),

                // 🔥 BUTTON
                InkWell(
                  onTap: verifyOtp,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF427AB5), Color(0xFFBDEBFF)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      "Verifikasi",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // 🔁 RESEND
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Kode OTP dikirim ulang")),
                    );
                  },
                  child: const Text(
                    "Kirim Ulang",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
