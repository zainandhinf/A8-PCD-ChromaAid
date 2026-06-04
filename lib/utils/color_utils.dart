// lib/services/color_utils.dart
// Utility functions for color conversion and naming

import 'dart:math';

class ColorUtils {
  /// Convert RGB to HEX string (e.g. "#FF5733")
  static String rgbToHex(int r, int g, int b) {
    return '#${r.toRadixString(16).padLeft(2, '0').toUpperCase()}'
        '${g.toRadixString(16).padLeft(2, '0').toUpperCase()}'
        '${b.toRadixString(16).padLeft(2, '0').toUpperCase()}';
  }

  /// Convert RGB to CMYK
  static Map<String, int> rgbToCmyk(int r, int g, int b) {
    if (r == 0 && g == 0 && b == 0) {
      return {'c': 0, 'm': 0, 'y': 0, 'k': 100};
    }
    double rr = r / 255.0;
    double gg = g / 255.0;
    double bb = b / 255.0;
    double k = 1 - [rr, gg, bb].reduce(max);
    double c = (1 - rr - k) / (1 - k);
    double m = (1 - gg - k) / (1 - k);
    double y = (1 - bb - k) / (1 - k);
    return {
      'c': (c * 100).round(),
      'm': (m * 100).round(),
      'y': (y * 100).round(),
      'k': (k * 100).round(),
    };
  }

  /// Get a human-readable color name based on RGB value
  static String getColorName(int r, int g, int b) {
    // Convert to HSL for better classification
    double rr = r / 255.0;
    double gg = g / 255.0;
    double bb = b / 255.0;

    double maxC = [rr, gg, bb].reduce(max);
    double minC = [rr, gg, bb].reduce(min);
    double delta = maxC - minC;

    double lightness = (maxC + minC) / 2.0;
    double saturation = 0;
    double hue = 0;

    if (delta != 0) {
      saturation = delta / (1 - (2 * lightness - 1).abs());

      if (maxC == rr) {
        hue = 60 * (((gg - bb) / delta) % 6);
      } else if (maxC == gg) {
        hue = 60 * (((bb - rr) / delta) + 2);
      } else {
        hue = 60 * (((rr - gg) / delta) + 4);
      }
      if (hue < 0) hue += 360;
    }

    // Classify by lightness first
    if (lightness < 0.12) return 'JET BLACK';
    if (lightness > 0.92) return 'PURE WHITE';
    if (saturation < 0.10) {
      if (lightness < 0.3) return 'CHARCOAL';
      if (lightness < 0.5) return 'SLATE GRAY';
      if (lightness < 0.75) return 'SILVER';
      return 'OFF WHITE';
    }

    // Classify by hue
    if (hue < 15 || hue >= 345) return saturation > 0.6 ? 'CRIMSON RED' : 'DUSTY ROSE';
    if (hue < 30) return lightness < 0.4 ? 'BURNT SIENNA' : 'TANGERINE';
    if (hue < 50) return lightness < 0.5 ? 'AMBER' : 'GOLDEN YELLOW';
    if (hue < 65) return saturation > 0.5 ? 'LIME YELLOW' : 'KHAKI';
    if (hue < 100) return lightness < 0.35 ? 'OLIVE' : 'LIME GREEN';
    if (hue < 150) return lightness < 0.4 ? 'FOREST GREEN' : 'MINT';
    if (hue < 165) return 'SEAFOAM';
    if (hue < 195) return lightness < 0.45 ? 'TEAL' : 'AQUA';
    if (hue < 220) return lightness < 0.4 ? 'DEEP SKY' : 'SKY BLUE';
    if (hue < 250) return lightness < 0.4 ? 'ROYAL BLUE' : 'CORNFLOWER';
    if (hue < 275) return lightness < 0.4 ? 'INDIGO' : 'PERIWINKLE';
    if (hue < 300) return lightness < 0.4 ? 'DEEP VIOLET' : 'LAVENDER';
    if (hue < 330) return lightness < 0.4 ? 'PLUM' : 'PINK';
    return 'ROSE';
  }

  /// Get a color category tag
  static List<String> getColorTags(int r, int g, int b) {
    double rr = r / 255.0;
    double gg = g / 255.0;
    double bb = b / 255.0;
    double maxC = [rr, gg, bb].reduce(max);
    double minC = [rr, gg, bb].reduce(min);
    double lightness = (maxC + minC) / 2.0;
    double saturation = 0;
    double hue = 0;
    double delta = maxC - minC;
    if (delta != 0) {
      saturation = delta / (1 - (2 * lightness - 1).abs());
      if (maxC == rr) hue = 60 * (((gg - bb) / delta) % 6);
      else if (maxC == gg) hue = 60 * (((bb - rr) / delta) + 2);
      else hue = 60 * (((rr - gg) / delta) + 4);
      if (hue < 0) hue += 360;
    }

    List<String> tags = [];
    if (lightness > 0.7) tags.add('LIGHT');
    else if (lightness < 0.3) tags.add('DARK');
    else tags.add('MID');

    if (saturation < 0.2) tags.add('NEUTRAL');
    else if (saturation > 0.7) tags.add('VIVID');
    else tags.add('MUTED');

    if ((hue >= 0 && hue < 60) || (hue >= 300 && hue < 360)) tags.add('WARM');
    else if (hue >= 180 && hue < 270) tags.add('COOL');
    else if (hue >= 60 && hue < 180) tags.add('NATURE');

    return tags.take(3).toList();
  }

  /// Generate complementary colors array (analogous + complement)
  static List<Map<String, int>> getComplementaryColors(int r, int g, int b) {
    double rr = r / 255.0, gg = g / 255.0, bb = b / 255.0;
    double maxC = [rr, gg, bb].reduce(max);
    double minC = [rr, gg, bb].reduce(min);
    double delta = maxC - minC;
    double lightness = (maxC + minC) / 2.0;
    double saturation = delta == 0 ? 0 : delta / (1 - (2 * lightness - 1).abs());
    double hue = 0;
    if (delta != 0) {
      if (maxC == rr) hue = 60 * (((gg - bb) / delta) % 6);
      else if (maxC == gg) hue = 60 * (((bb - rr) / delta) + 2);
      else hue = 60 * (((rr - gg) / delta) + 4);
      if (hue < 0) hue += 360;
    }

    List<Map<String, int>> result = [];
    for (double offset in [-30.0, 30.0, 180.0]) {
      double h = (hue + offset) % 360;
      result.add(_hslToRgb(h, saturation, lightness));
    }
    return result;
  }

  static Map<String, int> _hslToRgb(double h, double s, double l) {
    double c = (1 - (2 * l - 1).abs()) * s;
    double x = c * (1 - ((h / 60) % 2 - 1).abs());
    double m = l - c / 2;
    double rr = 0, gg = 0, bb = 0;
    if (h < 60) { rr = c; gg = x; }
    else if (h < 120) { rr = x; gg = c; }
    else if (h < 180) { gg = c; bb = x; }
    else if (h < 240) { gg = x; bb = c; }
    else if (h < 300) { rr = x; bb = c; }
    else { rr = c; bb = x; }
    return {
      'r': ((rr + m) * 255).round().clamp(0, 255),
      'g': ((gg + m) * 255).round().clamp(0, 255),
      'b': ((bb + m) * 255).round().clamp(0, 255),
    };
  }
}
