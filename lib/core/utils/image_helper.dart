import 'dart:convert';
import 'dart:io';

class ImageHelper {
  /// Membaca file gambar dan mengodekannya menjadi Base64 Data URI string.
  /// Contoh output: "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQ..."
  static Future<String> fileToBase64(File file) async {
    final bytes = await file.readAsBytes();
    final base64String = base64Encode(bytes);
    // Menggunakan ekstensi file sebagai tipe mime gambar secara sederhana
    final extension = file.path.split('.').last.toLowerCase();
    final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
    return 'data:$mimeType;base64,$base64String';
  }
}
