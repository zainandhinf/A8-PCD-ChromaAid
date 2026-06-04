import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class ColorUtils {
  static List<dynamic> _colorDatabase = [];

  // Load color database from JSON
  static Future<void> loadColorDatabase() async {
    if (_colorDatabase.isNotEmpty) return;
    try {
      final String response = await rootBundle.loadString('assets/colors.json');
      // Format JSON bebas, kita asumsikan berupa List of Objects atau Object dengan array 'colors'
      final dynamic data = await json.decode(response);
      if (data is List) {
        _colorDatabase = data;
      } else if (data is Map && data.containsKey('colors')) {
        _colorDatabase = data['colors'];
      }
    } catch (e) {
      print("Error loading color database: $e");
    }
  }

  // Find nearest color name using Euclidean distance
  static String getNearestColorName(int r, int g, int b) {
    if (_colorDatabase.isEmpty) return "Warna";

    double minDistance = double.infinity;
    String closestName = "Warna";

    for (var colorItem in _colorDatabase) {
      // Struktur JSON warna standar XKCD / umum
      // Menangani format array hex/rgb yang bervariasi secara fleksibel
      int dbR = 0, dbG = 0, dbB = 0;
      String name = "Warna";

      if (colorItem is Map) {
        name = colorItem['name'] ?? colorItem['color'] ?? "Warna";
        
        if (colorItem.containsKey('r') && colorItem.containsKey('g') && colorItem.containsKey('b')) {
           dbR = (colorItem['r'] as num).toInt();
           dbG = (colorItem['g'] as num).toInt();
           dbB = (colorItem['b'] as num).toInt();
        } else if (colorItem.containsKey('hex')) {
           String hex = colorItem['hex'].toString().replaceAll('#', '');
           if (hex.length == 6) {
             dbR = int.parse(hex.substring(0, 2), radix: 16);
             dbG = int.parse(hex.substring(2, 4), radix: 16);
             dbB = int.parse(hex.substring(4, 6), radix: 16);
           }
        }
      }

      // Euclidean distance formula
      double distance = sqrt(pow(r - dbR, 2) + pow(g - dbG, 2) + pow(b - dbB, 2));

      if (distance < minDistance) {
        minDistance = distance;
        closestName = name;
      }
    }

    return closestName.toUpperCase();
  }

  // Convert RGB to CMYK
  static Map<String, int> rgbToCmyk(int r, int g, int b) {
    if (r == 0 && g == 0 && b == 0) {
      return {'c': 0, 'm': 0, 'y': 0, 'k': 100};
    }
    double rPrime = r / 255.0;
    double gPrime = g / 255.0;
    double bPrime = b / 255.0;

    double k = 1.0 - max(max(rPrime, gPrime), bPrime);
    double c = k == 1.0 ? 0 : (1.0 - rPrime - k) / (1.0 - k);
    double m = k == 1.0 ? 0 : (1.0 - gPrime - k) / (1.0 - k);
    double y = k == 1.0 ? 0 : (1.0 - bPrime - k) / (1.0 - k);

    return {
      'c': (c * 100).round(),
      'm': (m * 100).round(),
      'y': (y * 100).round(),
      'k': (k * 100).round(),
    };
  }

  // Get complementary color (HSL Hue rotation by 180 deg)
  static Color getComplementaryColor(int r, int g, int b) {
    final hsl = HSLColor.fromColor(Color.fromRGBO(r, g, b, 1.0));
    final newHue = (hsl.hue + 180.0) % 360.0;
    return hsl.withHue(newHue).toColor();
  }
}
