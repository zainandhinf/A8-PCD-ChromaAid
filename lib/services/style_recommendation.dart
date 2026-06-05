import 'package:flutter/material.dart';
import 'skin_utils.dart';

class RecommendedColor {
  final Color color;
  final String label;
  
  RecommendedColor({required this.color, required this.label});
}

class StyleRecommendation {
  static List<RecommendedColor> getAutoRecommend(int r, int g, int b) {
    final base = HSLColor.fromColor(Color.fromRGBO(r, g, b, 1));
    
    // Complementary (+180)
    final compHue = (base.hue + 180) % 360;
    final complementary = base.withHue(compHue).toColor();
    
    // Analogous (-30)
    final ana1Hue = (base.hue - 30) < 0 ? base.hue - 30 + 360 : base.hue - 30;
    final analogous1 = base.withHue(ana1Hue).toColor();
    
    // Analogous (+30)
    final ana2Hue = (base.hue + 30) % 360;
    final analogous2 = base.withHue(ana2Hue).toColor();
    
    // Triadic (+120)
    final triHue = (base.hue + 120) % 360;
    final triadic = base.withHue(triHue).toColor();
    
    return [
      RecommendedColor(color: analogous1, label: 'Analogous (-30°)'),
      RecommendedColor(color: analogous2, label: 'Analogous (+30°)'),
      RecommendedColor(color: complementary, label: 'Complementary'),
      RecommendedColor(color: triadic, label: 'Triadic (+120°)'),
    ];
  }

  static List<RecommendedColor> getSkinRecommend(int r, int g, int b) {
    if (!SkinUtils.isSkinTone(r, g, b)) {
      return [
        RecommendedColor(color: Colors.grey, label: 'Bukan warna kulit'),
      ];
    }
    
    final level = SkinUtils.getSkinToneLevel(r, g, b);
    if (level == 'Gelap') {
      return [
        RecommendedColor(color: const Color(0xFF000080), label: 'Navy'),
        RecommendedColor(color: Colors.white, label: 'Putih'),
        RecommendedColor(color: const Color(0xFF006400), label: 'Hijau Tua'),
        RecommendedColor(color: const Color(0xFFFFD700), label: 'Emas'),
      ];
    } else if (level == 'Medium') {
      return [
        RecommendedColor(color: const Color(0xFFADD8E6), label: 'Biru Muda'),
        RecommendedColor(color: const Color(0xFFFFFDD0), label: 'Krem'),
        RecommendedColor(color: const Color(0xFFB22222), label: 'Merah Bata'),
        RecommendedColor(color: const Color(0xFF2E8B57), label: 'Sea Green'),
      ];
    } else { // Terang
      return [
        RecommendedColor(color: const Color(0xFFFFB6C1), label: 'Pastel Pink'),
        RecommendedColor(color: Colors.black, label: 'Hitam'),
        RecommendedColor(color: const Color(0xFF800020), label: 'Burgundy'),
        RecommendedColor(color: const Color(0xFF98FB98), label: 'Mint'),
      ];
    }
  }

  static List<RecommendedColor> getClothingRecommend(int r, int g, int b) {
    final hsl = HSLColor.fromColor(Color.fromRGBO(r, g, b, 1));
    
    if (hsl.saturation < 0.2) {
      return [
        RecommendedColor(color: Colors.black, label: 'Hitam (Kontras)'),
        RecommendedColor(color: Colors.white, label: 'Putih (Bersih)'),
        RecommendedColor(color: const Color(0xFF000080), label: 'Navy'),
        RecommendedColor(color: const Color(0xFF8B4513), label: 'Coklat Tua'),
      ];
    } else if (hsl.lightness < 0.3) {
      return [
        RecommendedColor(color: Colors.white, label: 'Putih (Kontras)'),
        RecommendedColor(color: const Color(0xFFF5F5DC), label: 'Beige'),
        RecommendedColor(color: hsl.withLightness(0.7).toColor(), label: 'Versi Terang'),
        RecommendedColor(color: const Color(0xFFD3D3D3), label: 'Abu Muda'),
      ];
    } else {
      return getAutoRecommend(r, g, b);
    }
  }
}
