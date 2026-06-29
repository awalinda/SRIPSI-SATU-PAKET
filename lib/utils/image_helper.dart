import 'package:flutter/foundation.dart' show kIsWeb;

class ImageHelper {
  /// Mengembalikan URL proxy CORS jika dijalankan di Web dan URL berasal dari Firebase Storage.
  /// Ini adalah solusi cepat (workaround) agar gambar bisa tampil di Flutter Web (CanvasKit) tanpa perlu menyetel CORS di Cloud Shell.
  static String getCorsUrl(String url) {
    if (kIsWeb && url.startsWith('http') && url.contains('firebasestorage')) {
      // Menggunakan local proxy server
      return "http://localhost:8080/?url=${Uri.encodeComponent(url)}";
    }
    return url;
  }
}
