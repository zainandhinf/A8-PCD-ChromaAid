import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import '../models/color_model.dart';

class ColorService {
  static List<NamedColor> colorDictionary = [];

  // Fungsi untuk membaca dan mengekstrak file teks
  static Future<void> loadColorDictionary() async {
    try {
      final String fileText = await rootBundle.loadString('assets/wiki-color-list.text');
      
      // Membaca per baris
      final List<String> lines = fileText.split('\n');
      final RegExp hexRegex = RegExp(r'#([A-Fa-f0-9]{6})');

      for (String line in lines) {
        // Abaikan baris yang tidak memiliki kode Hex
        if (!line.contains('#')) continue;

        final match = hexRegex.firstMatch(line);
        if (match != null) {
          String hexCode = match.group(1)!;
          
          // Ambil nama warna (semua teks sebelum kode hex)
          int hexIndex = line.indexOf('#');
          String rawName = line.substring(0, hexIndex);
          
          // Bersihkan nama dari tag , tabulasi, dan spasi berlebih
          String cleanName = rawName
              .replaceAll(RegExp(r'\'), '')
              .replaceAll('\t', ' ')
              .trim();
          
          cleanName = cleanName.replaceAll(RegExp(r'\s+'), ' ');

          // Abaikan baris header teks
          if (cleanName.isEmpty || cleanName.toLowerCase().contains('hex triplet')) continue;

          // Konversi kode Hex ke RGB
          int hexValue = int.parse(hexCode, radix: 16);
          int r = (hexValue >> 16) & 0xFF;
          int g = (hexValue >> 8) & 0xFF;
          int b = hexValue & 0xFF;

          colorDictionary.add(NamedColor(cleanName, r, g, b));
        }
      }
      print("✅ Berhasil memuat ${colorDictionary.length} warna ke memori!");
    } catch (e) {
      print("❌ Gagal memuat kamus warna: $e");
    }
  }

  // Fungsi Nearest Neighbor
  static String getClosestColorName(int targetR, int targetG, int targetB) {
    if (colorDictionary.isEmpty) return "Memuat kamus warna...";

    NamedColor closestColor = colorDictionary.first;
    double minDistance = double.maxFinite;

    for (var color in colorDictionary) {
      double distance = sqrt(
        pow(color.r - targetR, 2) +
        pow(color.g - targetG, 2) +
        pow(color.b - targetB, 2)
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestColor = color;
      }
    }

    return closestColor.name;
  }
}