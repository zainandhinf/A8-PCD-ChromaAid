import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

// Top-level function for preprocessing
Float32List preprocessImage(Map<String, dynamic> args) {
  final Uint8List planeY = args['planeY'];
  final int width = args['width'];
  final int height = args['height'];
  final int bytesPerRow = args['bytesPerRow'];

  final int scaleX = width ~/ 640;
  final int scaleY = height ~/ 640;

  final Float32List input = Float32List(1 * 640 * 640 * 3);
  int idx = 0;

  for (int y = 0; y < 640; y++) {
    int srcY = (y * scaleY).clamp(0, height - 1);
    int rowOffset = srcY * bytesPerRow;
    for (int x = 0; x < 640; x++) {
      int srcX = (x * scaleX).clamp(0, width - 1);
      double val = planeY[rowOffset + srcX] / 255.0;
      input[idx++] = val;
      input[idx++] = val;
      input[idx++] = val;
    }
  }
  return input;
}

// Top-level function for postprocessing
int postprocessOutput(Float32List outputBuffer) {
  double maxScore = 0.0;
  int detectedClassId = -1;
  // outputBuffer is [1, 84, 8400] flat
  // 84 = 4 bounding box + 80 class scores
  // So for classId 0..79, the index is (4 + classId) * 8400 + i
  
  for (int i = 0; i < 8400; i++) {
    for (int classId = 0; classId < 80; classId++) {
      double score = outputBuffer[(4 + classId) * 8400 + i];
      if (score > maxScore) {
        maxScore = score;
        detectedClassId = classId;
      }
    }
  }
  
  // Pack result: upper 16 bits = classId, lower 16 bits = score * 10000
  // Or just return a Map. compute supports Map.
  return (detectedClassId << 16) | (maxScore * 10000).toInt();
}

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
      // 1. Preprocess in Isolate (convert CameraImage to flat Float32List)
      final inputBuffer = await compute(preprocessImage, {
        'planeY': image.planes[0].bytes,
        'width': image.width,
        'height': image.height,
        'bytesPerRow': image.planes[0].bytesPerRow,
      });

      // 2. Inference on Main Thread (Fast because tensor is flat Float32List)
      // Input shape is [1, 640, 640, 3] -> flat 1228800
      var inputTensor = inputBuffer.buffer.asUint8List(); 
      // Output shape is [1, 84, 8400] -> flat 705600
      final Float32List outputBuffer = Float32List(1 * 84 * 8400);

      // tflite_flutter expects the reshaped list or raw buffer.
      // But we can just use run() if we pass the raw tensor?
      // Actually, passing flat list directly works if reshaped.
      var inputReshaped = inputBuffer.reshape([1, 640, 640, 3]);
      var outputReshaped = outputBuffer.reshape([1, 84, 8400]);
      
      _interpreter!.run(inputReshaped, outputReshaped);

      // 3. Postprocess in Isolate
      final packedResult = await compute(postprocessOutput, outputBuffer);
      
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
