import 'package:tflite_flutter/tflite_flutter.dart';

class AiService {
  Interpreter? _interpreter;
  bool isModelLoaded = false;

  Future<void> initModel() async {
    try {
      // Membaca model Edge AI yang ringan (YOLOv8 Nano)
      _interpreter = await Interpreter.fromAsset('assets/yolov8_nano.tflite');
      isModelLoaded = true;
      print("Edge AI: YOLOv8 Model berhasil dimuat ke dalam memori.");

      // Mendapatkan informasi bentuk input/output tensor
      var inputShape = _interpreter!.getInputTensor(0).shape;
      print(
        "AI Input Shape membutuhkan: $inputShape",
      ); // Biasanya [1, 640, 640, 3]
    } catch (e) {
      print("Edge AI Error: Gagal memuat model. $e");
    }
  }

  // Fungsi inferensi (Akan diisi penuh pada Sprint 3 bersama konversi koordinat)
  List<dynamic> runObjectDetection(List<List<List<int>>> imageMatrix) {
    if (!isModelLoaded || _interpreter == null) return [];

    // Siapkan wadah output (Sesuai dengan output shape YOLOv8)
    var outputBuffer = List.filled(1 * 84 * 8400, 0.0).reshape([1, 84, 8400]);

    // _interpreter!.run(imageMatrix, outputBuffer); // Uncomment di Sprint 3

    return outputBuffer;
  }
}
