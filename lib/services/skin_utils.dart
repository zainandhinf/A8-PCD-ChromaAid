import 'package:flutter/material.dart';

class SkinUtils {
  static bool isSkinTone(int r, int g, int b) {
    final hsl = HSLColor.fromColor(Color.fromRGBO(r, g, b, 1));
    final h = hsl.hue; // 0-360
    final s = hsl.saturation; // 0-1
    final l = hsl.lightness; // 0-1
    
    // hue: merah-oranye (0-40)
    // saturation: 0.15 - 0.65
    // lightness: 0.25 - 0.75
    return (h >= 0 && h <= 40) && (s >= 0.15 && s <= 0.65) && (l >= 0.25 && l <= 0.75);
  }

  static String getSkinToneLevel(int r, int g, int b) {
    if (!isSkinTone(r, g, b)) return 'Bukan Skin Tone';
    
    final l = HSLColor.fromColor(Color.fromRGBO(r, g, b, 1)).lightness;
    if (l < 0.40) return 'Gelap';
    if (l < 0.60) return 'Medium';
    return 'Terang';
  }
}
