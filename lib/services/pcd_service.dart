import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

Map<String, dynamic> processCameraFrame(CameraImage image) {
  final int width = image.width;
  final int height = image.height;
  final int centerX = width ~/ 2;
  final int centerY = height ~/ 2;

  final int kernelSize = 5; // Area matriks 5x5 untuk Average Pooling
  final int offset = kernelSize ~/ 2;

  int totalR = 0, totalG = 0, totalB = 0;
  int count = 0;

  for (int y = centerY - offset; y <= centerY + offset; y++) {
    for (int x = centerX - offset; x <= centerX + offset; x++) {
      if (x >= 0 && x < width && y >= 0 && y < height) {
        final int uvIndex = (kernelSize * (y ~/ 2)) + (x ~/ 2);
        final int indexY = y * image.planes[0].bytesPerRow + x;
        final int indexU =
            (y ~/ 2) * image.planes[1].bytesPerRow +
            (x ~/ 2) * image.planes[1].bytesPerPixel!;
        final int indexV =
            (y ~/ 2) * image.planes[2].bytesPerRow +
            (x ~/ 2) * image.planes[2].bytesPerPixel!;

        final int Y = image.planes[0].bytes[indexY];
        final int U = image.planes[1].bytes[indexU];
        final int V = image.planes[2].bytes[indexV];

        // Konversi YUV ke RGB dengan pengaturan kontras
        int R = (Y + 1.402 * (V - 128)).round().clamp(0, 255);
        int G = (Y - 0.344136 * (U - 128) - 0.714136 * (V - 128)).round().clamp(
          0,
          255,
        );
        int B = (Y + 1.772 * (U - 128)).round().clamp(0, 255);

        // --- TAMBAHAN OPERASI PCD: KONTRAS & KECERAHAN ---
        double contrastFactor =
            1.2; // Nilai > 1.0 untuk meningkatkan kontras (Contrast Stretching)
        int brightnessOffset =
            10; // Nilai positif untuk mencerahkan gambar (Brightness Adjustment)

        // Rumus PCD: New_Pixel = (Contrast * (Old_Pixel - 128)) + 128 + Brightness
        R = ((contrastFactor * (R - 128)) + 128 + brightnessOffset).round();
        G = ((contrastFactor * (G - 128)) + 128 + brightnessOffset).round();
        B = ((contrastFactor * (B - 128)) + 128 + brightnessOffset).round();

        // Klem nilai akhir ke rentang 0 - 255
        R = R.clamp(0, 255);
        G = G.clamp(0, 255);
        B = B.clamp(0, 255);

        totalR += R;
        totalG += G;
        totalB += B;
        count++;
      }
    }
  }

  return {'r': totalR ~/ count, 'g': totalG ~/ count, 'b': totalB ~/ count};
}

class PcdService {
  Future<Map<String, dynamic>> extractColorFromFrame(CameraImage frame) async {
    return await compute(processCameraFrame, frame);
  }
}
