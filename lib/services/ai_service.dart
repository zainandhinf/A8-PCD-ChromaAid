import 'dart:isolate';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  Interpreter? _interpreter;
  bool _isModelLoaded = false;
  double _threshold = 0.45;

  void updateThreshold(double newThreshold) {
    _threshold = newThreshold;
  }

  bool get isModelLoaded => _isModelLoaded;

  final List<String> _clothingLabels = [
    "person", "bicycle", "car", "motorcycle", "airplane", "bus", "train", "truck", "boat",
    "traffic light", "fire hydrant", "stop sign", "parking meter", "bench", "bird", "cat",
    "dog", "horse", "sheep", "cow", "elephant", "bear", "zebra", "giraffe", "backpack",
    "umbrella", "handbag", "tie", "suitcase", "frisbee", "skis", "snowboard", "sports ball",
    "kite", "baseball bat", "baseball glove", "skateboard", "surfboard", "tennis racket",
    "bottle", "wine glass", "cup", "fork", "knife", "spoon", "bowl", "banana", "apple",
    "sandwich", "orange", "broccoli", "carrot", "hot dog", "pizza", "donut", "cake",
    "chair", "couch", "potted plant", "bed", "dining table", "toilet", "tv", "laptop",
    "mouse", "remote", "keyboard", "cell phone", "microwave", "oven", "toaster", "sink",
    "refrigerator", "book", "clock", "vase", "scissors", "teddy bear", "hair drier", "toothbrush"
  ];

  Future<void> initModel() async {
    if (_isModelLoaded) return;
    try {
      _interpreter = await Interpreter.fromAsset('assets/yolov8_nano.tflite');
      _isModelLoaded = true;
    } catch (e) {
      print("Error loading TFLite Model: $e");
    }
  }

  Future<String> runObjectDetection(CameraImage image) async {
    if (!_isModelLoaded || _interpreter == null) return "AI Offline";

    try {
      // Ekstrak data sebelum dikirim ke Isolate
      final Uint8List planeYBytes = image.planes[0].bytes;
      final int width = image.width;
      final int height = image.height;
      final int bytesPerRow = image.planes[0].bytesPerRow;
      final int address = _interpreter!.address;

      // Jalankan SEMUA tahapan AI di Isolate (Preprocess, Inference, Postprocess)
      final int packedResult = await Isolate.run(() {
        // 1. Preprocess
        final int scaleX = width ~/ 640;
        final int scaleY = height ~/ 640;
        final Float32List inputBuffer = Float32List(1 * 640 * 640 * 3);
        int idx = 0;

        for (int y = 0; y < 640; y++) {
          int srcY = (y * scaleY).clamp(0, height - 1);
          int rowOffset = srcY * bytesPerRow;
          for (int x = 0; x < 640; x++) {
            int srcX = (x * scaleX).clamp(0, width - 1);
            double val = planeYBytes[rowOffset + srcX] / 255.0;
            inputBuffer[idx++] = val;
            inputBuffer[idx++] = val;
            inputBuffer[idx++] = val;
          }
        }

        // 2. Inference
        var isolateInterpreter = Interpreter.fromAddress(address);
        var inputReshaped = inputBuffer.reshape([1, 640, 640, 3]);
        var outBuf = Float32List(1 * 84 * 8400);
        var outputReshaped = outBuf.reshape([1, 84, 8400]);
        
        isolateInterpreter.run(inputReshaped, outputReshaped);

        // 3. Postprocess
        double maxScore = 0.0;
        int detectedClassId = -1;
        for (int i = 0; i < 8400; i++) {
          for (int classId = 0; classId < 80; classId++) {
            double score = outBuf[(4 + classId) * 8400 + i];
            if (score > maxScore) {
              maxScore = score;
              detectedClassId = classId;
            }
          }
        }
        return (detectedClassId << 16) | (maxScore * 10000).toInt();
      });

      int classId = packedResult >> 16;
      double maxScore = (packedResult & 0xFFFF) / 10000.0;

      // Handle sign extension if classId was -1
      if (classId > 32767) classId = -1;

      if (classId != -1 && maxScore > _threshold) {
        return _clothingLabels[classId].toUpperCase();
      }
      return "Pakaian / Kulit";
    } catch (e) {
      print("AI Error: $e");
      return "Scanning...";
    }
  }

  void dispose() {
    _interpreter?.close();
  }
}
