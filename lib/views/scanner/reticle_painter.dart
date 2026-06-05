import 'package:flutter/material.dart';

class ReticlePainter extends CustomPainter {
  final Offset center;
  final double boxSize;

  ReticlePainter({required this.center, this.boxSize = 120});

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final accentPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final circlePaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final rect = Rect.fromCenter(center: center, width: boxSize, height: boxSize);
    canvas.drawRect(rect, borderPaint);
    canvas.drawCircle(center, 8, circlePaint);

    const double cornerLength = 20;

    // corner brackets
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(cornerLength, 0), accentPaint);
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(0, cornerLength), accentPaint);

    canvas.drawLine(rect.topRight, rect.topRight + const Offset(-cornerLength, 0), accentPaint);
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(0, cornerLength), accentPaint);

    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(cornerLength, 0), accentPaint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(0, -cornerLength), accentPaint);

    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(-cornerLength, 0), accentPaint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(0, -cornerLength), accentPaint);

    // crosshair
    canvas.drawLine(center + const Offset(-18, 0), center + const Offset(-6, 0), borderPaint);
    canvas.drawLine(center + const Offset(6, 0), center + const Offset(18, 0), borderPaint);
    canvas.drawLine(center + const Offset(0, -18), center + const Offset(0, -6), borderPaint);
    canvas.drawLine(center + const Offset(0, 6), center + const Offset(0, 18), borderPaint);
  }

  @override
  bool shouldRepaint(covariant ReticlePainter oldDelegate) {
    return center != oldDelegate.center || boxSize != oldDelegate.boxSize;
  }
}
