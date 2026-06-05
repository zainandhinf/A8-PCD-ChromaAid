import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';

/// Kategori warna dari colors.json
enum ColorCategory {
  fabric,  // warna pakaian
  leaf,    // warna natural/kulit
  unknown,
}

/// Satu entri warna dari library colors.json
class ColorEntry {
  final String name;
  final String hex;
  final int r;
  final int g;
  final int b;
  final ColorCategory category;

  const ColorEntry({
    required this.name,
    required this.hex,
    required this.r,
    required this.g,
    required this.b,
    required this.category,
  });

  factory ColorEntry.fromJson(Map<String, dynamic> json) {
    final rgb = (json['rgb'] as List).cast<int>();
    final cat = (json['category'] as String).toUpperCase();
    return ColorEntry(
      name: json['name'] as String,
      hex: json['hex'] as String,
      r: rgb[0],
      g: rgb[1],
      b: rgb[2],
      category: cat == 'FABRIC'
          ? ColorCategory.fabric
          : cat == 'LEAF'
              ? ColorCategory.leaf
              : ColorCategory.unknown,
    );
  }
}

/// Hasil satu rekomendasi warna pakaian
class ColorRecommendation {
  final ColorEntry color;
  final String reason;       // alasan kenapa cocok (dalam Bahasa Indonesia)
  final double harmonyScore; // 0.0–1.0, makin tinggi makin cocok

  const ColorRecommendation({
    required this.color,
    required this.reason,
    required this.harmonyScore,
  });
}

/// Service rekomendasi warna pakaian berbasis teori warna:
/// complementary, analogous, triadic, neutral, dan skin-tone aware.
///
/// Cara pakai:
///   await ColorRecommendationService.init();
///   final recs = ColorRecommendationService.recommend(r: 196, g: 85, b: 42);
class ColorRecommendationService {
  static List<ColorEntry> _library = [];
  static bool _initialized = false;

  // ── Init ──────────────────────────────────────────────────────────────────

  /// Load colors.json dari assets sekali saja.
  static Future<void> init() async {
    if (_initialized) return;
    try {
      final jsonStr = await rootBundle.loadString('assets/colors.json');
      final list = jsonDecode(jsonStr) as List;
      _library = list.map((e) => ColorEntry.fromJson(e)).toList();
      _initialized = true;
    } catch (e) {
      // Fallback: library kosong, rekomendasi tetap jalan via algoritma
      _library = [];
      _initialized = true;
    }
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Rekomendasikan warna pakaian yang cocok dengan warna input.
  ///
  /// [inputCategory] — konteks warna input:
  ///   - 'skin'   → warna kulit pengguna, rekomendasikan pakaian cocok
  ///   - 'fabric' → warna pakaian yang dimiliki, rekomendasikan paduan
  ///   - null     → auto-detect dari karakteristik warna
  ///
  /// Mengembalikan hingga [maxResults] rekomendasi, diurutkan terbaik.
  static List<ColorRecommendation> recommend({
    required int r,
    required int g,
    required int b,
    String? inputCategory,
    int maxResults = 5,
  }) {
    final hsl = _rgbToHsl(r, g, b);
    final category = inputCategory ?? _inferCategory(r, g, b, hsl);

    final List<ColorRecommendation> results = [];

    // 1. Rekomendasi dari library colors.json (hanya FABRIC)
    for (final entry in _library.where((e) => e.category == ColorCategory.fabric)) {
      final score = _computeHarmonyScore(
        srcR: r, srcG: g, srcB: b, srcHsl: hsl,
        tgtR: entry.r, tgtG: entry.g, tgtB: entry.b,
        context: category,
      );
      final reason = _buildReason(hsl, _rgbToHsl(entry.r, entry.g, entry.b), category);
      results.add(ColorRecommendation(
        color: entry,
        reason: reason,
        harmonyScore: score,
      ));
    }

    // 2. Rekomendasi algoritmik (tidak tergantung library)
    final algorithmic = _generateAlgorithmicRecommendations(r, g, b, hsl, category);
    results.addAll(algorithmic);

    // Deduplikasi & sort
    results.sort((a, b) => b.harmonyScore.compareTo(a.harmonyScore));
    return results.take(maxResults).toList();
  }

  // ── Algoritma Rekomendasi ─────────────────────────────────────────────────

  /// Generate rekomendasi berbasis teori warna (complementary, analogous, dll)
  static List<ColorRecommendation> _generateAlgorithmicRecommendations(
    int r, int g, int b, List<double> hsl, String context,
  ) {
    final recommendations = <ColorRecommendation>[];
    final h = hsl[0]; // 0–360
    final s = hsl[1]; // 0–1
    final l = hsl[2]; // 0–1

    // ── Complementary (180° berlawanan) ────────────────────────────────────
    {
      final ch = (h + 180) % 360;
      final cs = (s * 0.8).clamp(0.3, 0.8); // sedikit redam agar tidak terlalu mencolok
      final cl = context == 'skin'
          ? (l > 0.5 ? l - 0.15 : l + 0.15).clamp(0.35, 0.75)
          : (0.45).clamp(0.3, 0.7);
      final rgb = _hslToRgb(ch, cs, cl);
      recommendations.add(ColorRecommendation(
        color: _makeEntry('Complementary', rgb[0], rgb[1], rgb[2]),
        reason: 'Warna komplementer — kontras alami yang menarik perhatian '
            'tanpa terasa berlebihan.',
        harmonyScore: context == 'skin' ? 0.88 : 0.82,
      ));
    }

    // ── Analogous +30° ────────────────────────────────────────────────────
    {
      final ah = (h + 30) % 360;
      final as_ = (s * 0.9).clamp(0.3, 0.85);
      final al = (l + 0.05).clamp(0.3, 0.75);
      final rgb = _hslToRgb(ah, as_, al);
      recommendations.add(ColorRecommendation(
        color: _makeEntry('Analogous (+30°)', rgb[0], rgb[1], rgb[2]),
        reason: 'Warna analogous — harmonis dan nyaman dipandang karena '
            'berada di spektrum yang berdekatan.',
        harmonyScore: 0.78,
      ));
    }

    // ── Analogous -30° ────────────────────────────────────────────────────
    {
      final ah = (h - 30 + 360) % 360;
      final as_ = (s * 0.9).clamp(0.3, 0.85);
      final al = (l - 0.05).clamp(0.3, 0.75);
      final rgb = _hslToRgb(ah, as_, al);
      recommendations.add(ColorRecommendation(
        color: _makeEntry('Analogous (-30°)', rgb[0], rgb[1], rgb[2]),
        reason: 'Warna analogous — menciptakan kesan hangat dan '
            'terpadu dalam satu palet.',
        harmonyScore: 0.76,
      ));
    }

    // ── Triadic ────────────────────────────────────────────────────────────
    {
      final th = (h + 120) % 360;
      final ts = (s * 0.75).clamp(0.25, 0.8);
      final tl = (0.5).clamp(0.35, 0.65);
      final rgb = _hslToRgb(th, ts, tl);
      recommendations.add(ColorRecommendation(
        color: _makeEntry('Triadic', rgb[0], rgb[1], rgb[2]),
        reason: 'Warna triadik — menawarkan variasi warna yang berani '
            'namun tetap seimbang secara visual.',
        harmonyScore: 0.70,
      ));
    }

    // ── Neutral / Akromatik ───────────────────────────────────────────────
    // Berdasarkan tone kulit/warna: pilih antara krem, abu, putih tulang, navy
    {
      final neutrals = _getNeutralRecommendations(r, g, b, hsl, context);
      recommendations.addAll(neutrals);
    }

    return recommendations;
  }

  /// Pilih warna netral yang paling cocok dengan input
  static List<ColorRecommendation> _getNeutralRecommendations(
    int r, int g, int b, List<double> hsl, String context,
  ) {
    final results = <ColorRecommendation>[];
    final warmth = _computeWarmth(r, g, b); // -1 (cool) to +1 (warm)

    if (warmth > 0.2) {
      // Warna hangat → netral hangat
      results.add(ColorRecommendation(
        color: _makeEntry('Krem Hangat', 245, 235, 215),
        reason: 'Netral hangat yang melengkapi undertone '
            'hangat pada warna ini dengan lembut.',
        harmonyScore: 0.74,
      ));
      results.add(ColorRecommendation(
        color: _makeEntry('Coklat Muda', 162, 128, 101),
        reason: 'Warna earthy tone yang natural dan mudah dipadukan '
            'dengan warna hangat.',
        harmonyScore: 0.71,
      ));
    } else if (warmth < -0.2) {
      // Warna dingin → netral dingin
      results.add(ColorRecommendation(
        color: _makeEntry('Abu Biru', 180, 188, 200),
        reason: 'Netral sejuk yang harmonis dengan undertone '
            'dingin pada warna ini.',
        harmonyScore: 0.74,
      ));
      results.add(ColorRecommendation(
        color: _makeEntry('Navy Soft', 44, 62, 90),
        reason: 'Biru navy memberi kesan elegan dan profesional '
            'saat dipadukan dengan warna sejuk.',
        harmonyScore: 0.72,
      ));
    } else {
      // Netral → putih bersih / hitam lunak
      results.add(ColorRecommendation(
        color: _makeEntry('Putih Bersih', 248, 248, 248),
        reason: 'Putih bersih adalah pasangan universal yang '
            'membuat warna apapun terlihat segar.',
        harmonyScore: 0.73,
      ));
      results.add(ColorRecommendation(
        color: _makeEntry('Hitam Soft', 30, 30, 35),
        reason: 'Hitam lembut memberikan kontras elegan yang '
            'menonjolkan warna utama.',
        harmonyScore: 0.72,
      ));
    }

    return results;
  }

  // ── Scoring ───────────────────────────────────────────────────────────────

  static double _computeHarmonyScore({
    required int srcR, required int srcG, required int srcB,
    required List<double> srcHsl,
    required int tgtR, required int tgtG, required int tgtB,
    required String context,
  }) {
    final tgtHsl = _rgbToHsl(tgtR, tgtG, tgtB);
    final hueDiff = _hueDifference(srcHsl[0], tgtHsl[0]);

    double score = 0.5;

    // Komplementer (160–200°)
    if (hueDiff >= 160 && hueDiff <= 200) score += 0.35;
    // Analogous (20–50°)
    else if (hueDiff >= 20 && hueDiff <= 50) score += 0.28;
    // Triadic (110–130°)
    else if (hueDiff >= 110 && hueDiff <= 130) score += 0.22;
    // Terlalu mirip (< 15°) — kurang menarik
    else if (hueDiff < 15) score -= 0.1;

    // Bonus untuk konteks kulit: hindari warna yang terlalu mirip skin
    if (context == 'skin') {
      final isSkinTone = _isSkinTone(tgtR, tgtG, tgtB);
      if (isSkinTone) score -= 0.2;
    }

    // Lightness contrast bonus
    final lDiff = (srcHsl[2] - tgtHsl[2]).abs();
    if (lDiff > 0.3) score += 0.1;

    return score.clamp(0.0, 1.0);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Infer apakah input adalah kulit atau kain berdasarkan karakteristik warna
  static String _inferCategory(int r, int g, int b, List<double> hsl) {
    if (_isSkinTone(r, g, b)) return 'skin';
    return 'fabric';
  }

  /// Deteksi apakah RGB kemungkinan adalah warna kulit manusia
  static bool _isSkinTone(int r, int g, int b) {
    // Rule-based skin detection (Kovac, 2003)
    if (r <= 95 || g <= 40 || b <= 20) return false;
    if ((r - g).abs() <= 15) return false;
    if (r <= g || r <= b) return false;
    // Hue dalam range kuning-oranye-coklat
    final hsl = _rgbToHsl(r, g, b);
    final h = hsl[0];
    final s = hsl[1];
    final l = hsl[2];
    return (h >= 0 && h <= 50) && s >= 0.1 && s <= 0.8 && l >= 0.2 && l <= 0.8;
  }

  /// Warmth: positif = warm (merah/kuning), negatif = cool (biru/hijau)
  static double _computeWarmth(int r, int g, int b) {
    final warm = (r * 0.6 + g * 0.1) / 255;
    final cool = (b * 0.7 + g * 0.3) / 255;
    return (warm - cool).clamp(-1.0, 1.0);
  }

  static double _hueDifference(double h1, double h2) {
    final diff = (h1 - h2).abs();
    return diff > 180 ? 360 - diff : diff;
  }

  static String _buildReason(List<double> srcHsl, List<double> tgtHsl, String context) {
    final diff = _hueDifference(srcHsl[0], tgtHsl[0]);
    if (diff >= 160 && diff <= 200) {
      return context == 'skin'
          ? 'Warna komplementer yang menonjolkan warna kulit dan memberikan kesan segar.'
          : 'Kontras komplementer yang bold dan menarik perhatian.';
    }
    if (diff >= 20 && diff <= 50) return 'Warna analogous yang harmonis dan nyaman dipandang.';
    if (diff >= 110 && diff <= 130) return 'Kombinasi triadik yang berani namun seimbang.';
    return 'Warna dari library yang serasi berdasarkan kedekatan spektrum.';
  }

  static ColorEntry _makeEntry(String name, int r, int g, int b) {
    final hex = '#'
        '${r.toRadixString(16).padLeft(2, '0').toUpperCase()}'
        '${g.toRadixString(16).padLeft(2, '0').toUpperCase()}'
        '${b.toRadixString(16).padLeft(2, '0').toUpperCase()}';
    return ColorEntry(
      name: name,
      hex: hex,
      r: r,
      g: g,
      b: b,
      category: ColorCategory.fabric,
    );
  }

  // ── Konversi Warna ────────────────────────────────────────────────────────

  /// RGB (0–255) → HSL (H: 0–360, S: 0–1, L: 0–1)
  static List<double> _rgbToHsl(int r, int g, int b) {
    final rf = r / 255.0;
    final gf = g / 255.0;
    final bf = b / 255.0;

    final max = [rf, gf, bf].reduce(math.max);
    final min = [rf, gf, bf].reduce(math.min);
    final delta = max - min;

    double h = 0, s = 0;
    final l = (max + min) / 2;

    if (delta != 0) {
      s = l > 0.5 ? delta / (2 - max - min) : delta / (max + min);

      if (max == rf) {
        h = ((gf - bf) / delta + (gf < bf ? 6 : 0)) * 60;
      } else if (max == gf) {
        h = ((bf - rf) / delta + 2) * 60;
      } else {
        h = ((rf - gf) / delta + 4) * 60;
      }
    }

    return [h, s, l];
  }

  /// HSL (H: 0–360, S: 0–1, L: 0–1) → RGB (0–255)
  static List<int> _hslToRgb(double h, double s, double l) {
    if (s == 0) {
      final val = (l * 255).round();
      return [val, val, val];
    }

    double hueToRgb(double p, double q, double t) {
      if (t < 0) t += 1;
      if (t > 1) t -= 1;
      if (t < 1 / 6) return p + (q - p) * 6 * t;
      if (t < 1 / 2) return q;
      if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
      return p;
    }

    final q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    final p = 2 * l - q;
    final hNorm = h / 360;

    return [
      (hueToRgb(p, q, hNorm + 1 / 3) * 255).round().clamp(0, 255),
      (hueToRgb(p, q, hNorm) * 255).round().clamp(0, 255),
      (hueToRgb(p, q, hNorm - 1 / 3) * 255).round().clamp(0, 255),
    ];
  }
}
