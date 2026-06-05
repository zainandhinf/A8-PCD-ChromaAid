import 'dart:math';
import 'package:flutter/material.dart';

/// Mapping koordinat dari sensor kamera ke widget preview Flutter.
///
/// Sensor fisik dan layar bisa memiliki orientasi/aspek rasio berbeda,
/// sehingga titik tengah sampling harus dikalibrasi ke posisi reticle.
class CoordinateService {
  CoordinateService._();

  /// Peta titik sensor ke layar dengan asumsi preview ditampilkan di area penuh
  /// dan dipusatkan di layar.
  static Offset mapSensorToScreen({
    required Offset sensorPoint,
    required Size sensorSize,
    required Size widgetSize,
    bool isFrontCamera = false,
  }) {
    if (sensorSize.width <= 0 || sensorSize.height <= 0) {
      return widgetSize.center(Offset.zero);
    }

    var normalizedPoint = sensorPoint;
    var normalizedSensorSize = sensorSize;

    // Jika sensor landscape namun layar portrait, putar koordinat sensor.
    final bool sensorLandscape = sensorSize.width > sensorSize.height;
    final bool widgetPortrait = widgetSize.height >= widgetSize.width;
    if (sensorLandscape && widgetPortrait) {
      normalizedPoint = Offset(sensorSize.height - sensorPoint.dy, sensorPoint.dx);
      normalizedSensorSize = Size(sensorSize.height, sensorSize.width);
    }

    final sensorAspect = normalizedSensorSize.width / normalizedSensorSize.height;
    final widgetAspect = widgetSize.width / widgetSize.height;

    final fittedSize = widgetAspect > sensorAspect
        ? Size(widgetSize.width, widgetSize.width / sensorAspect)
        : Size(widgetSize.height * sensorAspect, widgetSize.height);

    final dx = normalizedPoint.dx * fittedSize.width / normalizedSensorSize.width;
    final dy = normalizedPoint.dy * fittedSize.height / normalizedSensorSize.height;

    var result = Offset((widgetSize.width - fittedSize.width) / 2 + dx,
        (widgetSize.height - fittedSize.height) / 2 + dy);

    if (isFrontCamera) {
      result = Offset(widgetSize.width - result.dx, result.dy);
    }

    return result;
  }
}
