import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class AiService {
  Interpreter? _interpreter;
  bool _isModelLoaded = false;

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
      var inputTensor = List.generate(1, (_) => List.generate(640, (_) => List.generate(640, (_) => List.filled(3, 0.0))));
      final planeY = image.planes[0];
      int scaleX = image.width ~/ 640;
      int scaleY = image.height ~/ 640;

      for (int y = 0; y < 640; y++) {
        for (int x = 0; x < 640; x++) {
          int srcX = (x * scaleX).clamp(0, image.width - 1);
          int srcY = (y * scaleY).clamp(0, image.height - 1);
          inputTensor[0][y][x][0] = planeY.bytes[srcY * planeY.bytesPerRow + srcX] / 255.0;
          inputTensor[0][y][x][1] = inputTensor[0][y][x][0];
          inputTensor[0][y][x][2] = inputTensor[0][y][x][0];
        }
      }

      var outputTensor = List.generate(1, (_) => List.generate(84, (_) => List.filled(8400, 0.0)));
      _interpreter!.run(inputTensor, outputTensor);

      double maxScore = 0.0;
      int detectedClassId = -1;

      for (int i = 0; i < 8400; i++) {
        for (int classId = 0; classId < 80; classId++) {
          double score = outputTensor[0][4 + classId][i];
          if (score > maxScore) {
            maxScore = score;
            detectedClassId = classId;
          }
        }
      }

      if (detectedClassId != -1 && maxScore > 0.45) {
        return _clothingLabels[detectedClassId].toUpperCase();
      }
      return "Pakaian / Kulit";
    } catch (e) {
      return "Scanning...";
    }
  }

  void dispose() {
    _interpreter?.close();
  }
}