import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Data class untuk hasil pipeline PCD lengkap.
class PcdResult {
  final int r;
  final int g;
  final int b;
  final String hex;

  const PcdResult({
    required this.r,
    required this.g,
    required this.b,
    required this.hex,
  });

  /// Flutter Color
  int get colorValue => (0xFF << 24) | (r << 16) | (g << 8) | b;

  bool get isLight => (0.299 * r + 0.587 * g + 0.114 * b) > 128;

  @override
  String toString() => 'PcdResult(R:$r G:$g B:$b $hex)';
}

/// Top-level function untuk di-spawn ke Isolate via compute().
/// Harus berada di luar class agar bisa dipakai oleh compute().
///
/// Pipeline PCD:
///   Step 1 — Konversi YUV → RGB (dari CameraImage plane)
///   Step 2 — Contrast Stretching + Brightness Adjustment
///   Step 3 — White Balance (Gray World Assumption)
///   Step 4 — Average Pooling 5×5 di area tengah frame
PcdResult processCameraFrameFull(CameraImage image) {
  final int width = image.width;
  final int height = image.height;
  final int centerX = width ~/ 2;
  final int centerY = height ~/ 2;

  const int kernelSize = 5;
  const int offset = kernelSize ~/ 2;
  const double contrastFactor = 1.2;
  const int brightnessOffset = 10;

  // ── Kumpulkan semua piksel mentah untuk White Balance ────────────────────
  // Kita ambil sample dari area yang lebih luas (center 20% gambar)
  // untuk menghitung rata-rata global yang lebih stabil.
  int wbSampleArea = 40; // radius sampling white balance
  double wbSumR = 0, wbSumG = 0, wbSumB = 0;
  int wbCount = 0;

  for (int y = centerY - wbSampleArea; y <= centerY + wbSampleArea; y += 2) {
    for (int x = centerX - wbSampleArea; x <= centerX + wbSampleArea; x += 2) {
      if (x < 0 || x >= width || y < 0 || y >= height) continue;
      final rawRgb = _yuvToRgb(image, x, y);
      wbSumR += rawRgb[0];
      wbSumG += rawRgb[1];
      wbSumB += rawRgb[2];
      wbCount++;
    }
  }

  // Scale factor White Balance (Gray World): targetkan avg = 128
  final double wbScaleR = wbCount > 0 && wbSumR > 0
      ? 128.0 / (wbSumR / wbCount) : 1.0;
  final double wbScaleG = wbCount > 0 && wbSumG > 0
      ? 128.0 / (wbSumG / wbCount) : 1.0;
  final double wbScaleB = wbCount > 0 && wbSumB > 0
      ? 128.0 / (wbSumB / wbCount) : 1.0;

  // ── Average Pooling 5×5 di area tengah ───────────────────────────────────
  int totalR = 0, totalG = 0, totalB = 0;
  int count = 0;

  for (int y = centerY - offset; y <= centerY + offset; y++) {
    for (int x = centerX - offset; x <= centerX + offset; x++) {
      if (x < 0 || x >= width || y < 0 || y >= height) continue;

      // Step 1: YUV → RGB
      final rawRgb = _yuvToRgb(image, x, y);
      int R = rawRgb[0];
      int G = rawRgb[1];
      int B = rawRgb[2];

      // Step 2: Contrast Stretching + Brightness
      R = ((contrastFactor * (R - 128)) + 128 + brightnessOffset).round().clamp(0, 255);
      G = ((contrastFactor * (G - 128)) + 128 + brightnessOffset).round().clamp(0, 255);
      B = ((contrastFactor * (B - 128)) + 128 + brightnessOffset).round().clamp(0, 255);

      // Step 3: White Balance correction
      R = (R * wbScaleR).round().clamp(0, 255);
      G = (G * wbScaleG).round().clamp(0, 255);
      B = (B * wbScaleB).round().clamp(0, 255);

      totalR += R;
      totalG += G;
      totalB += B;
      count++;
    }
  }

  if (count == 0) return const PcdResult(r: 0, g: 0, b: 0, hex: '#000000');

  final finalR = totalR ~/ count;
  final finalG = totalG ~/ count;
  final finalB = totalB ~/ count;

  final hex =
      '#${finalR.toRadixString(16).padLeft(2, '0').toUpperCase()}'
      '${finalG.toRadixString(16).padLeft(2, '0').toUpperCase()}'
      '${finalB.toRadixString(16).padLeft(2, '0').toUpperCase()}';

  return PcdResult(r: finalR, g: finalG, b: finalB, hex: hex);
}

/// Konversi satu piksel YUV (dari CameraImage) ke RGB.
List<int> _yuvToRgb(CameraImage image, int x, int y) {
  final int indexY = y * image.planes[0].bytesPerRow + x;
  final int indexU =
      (y ~/ 2) * image.planes[1].bytesPerRow +
      (x ~/ 2) * (image.planes[1].bytesPerPixel ?? 1);
  final int indexV =
      (y ~/ 2) * image.planes[2].bytesPerRow +
      (x ~/ 2) * (image.planes[2].bytesPerPixel ?? 1);

  if (indexY >= image.planes[0].bytes.length ||
      indexU >= image.planes[1].bytes.length ||
      indexV >= image.planes[2].bytes.length) {
    return [0, 0, 0];
  }

  final int Y = image.planes[0].bytes[indexY];
  final int U = image.planes[1].bytes[indexU];
  final int V = image.planes[2].bytes[indexV];

  final int R = (Y + 1.402 * (V - 128)).round().clamp(0, 255);
  final int G = (Y - 0.344136 * (U - 128) - 0.714136 * (V - 128))
      .round()
      .clamp(0, 255);
  final int B = (Y + 1.772 * (U - 128)).round().clamp(0, 255);

  return [R, G, B];
}

/// Service wrapper untuk dipakai dari ScannerScreen.
/// Semua komputasi berjalan di background Isolate via compute().
class PcdService {
  /// Proses satu frame kamera → PcdResult.
  /// Berjalan di Isolate terpisah (tidak memblokir UI).
  Future<PcdResult> extractColorFromFrame(CameraImage frame) async {
    return await compute(processCameraFrameFull, frame);
  }
}
