class ImageHelper {
  /// Mengembalikan URL asli.
  /// Karena CORS sudah dikonfigurasi di Firebase Storage,
  /// gambar akan langsung tampil tanpa masalah di CanvasKit.
  static String getCorsUrl(String url) {
    return url;
  }
}


