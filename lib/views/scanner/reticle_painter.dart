import 'package:flutter/material.dart';

class ReticlePainter extends CustomPainter {
  final Offset focusPoint;
  final bool isCalibrating;

  ReticlePainter({required this.focusPoint, this.isCalibrating = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = focusPoint;

    final paintLine = Paint()
      ..color = Colors.white54
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
      
    final paintAccent = Paint()
      ..color = const Color(0xFF00FFC4) // Cyan accent
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
      
    final paintFill = Paint()
      ..color = const Color(0xFF00FFC4).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Corner brackets
    double bracketLen = 30.0;
    double cornerOffset = 120.0;
    
    // Top Left
    canvas.drawLine(Offset(center.dx - cornerOffset, center.dy - cornerOffset), Offset(center.dx - cornerOffset + bracketLen, center.dy - cornerOffset), paintLine);
    canvas.drawLine(Offset(center.dx - cornerOffset, center.dy - cornerOffset), Offset(center.dx - cornerOffset, center.dy - cornerOffset + bracketLen), paintLine);
    
    // Top Right
    canvas.drawLine(Offset(center.dx + cornerOffset, center.dy - cornerOffset), Offset(center.dx + cornerOffset - bracketLen, center.dy - cornerOffset), paintLine);
    canvas.drawLine(Offset(center.dx + cornerOffset, center.dy - cornerOffset), Offset(center.dx + cornerOffset, center.dy - cornerOffset + bracketLen), paintLine);
    
    // Bottom Left
    canvas.drawLine(Offset(center.dx - cornerOffset, center.dy + cornerOffset), Offset(center.dx - cornerOffset + bracketLen, center.dy + cornerOffset), paintLine);
    canvas.drawLine(Offset(center.dx - cornerOffset, center.dy + cornerOffset), Offset(center.dx - cornerOffset, center.dy + cornerOffset - bracketLen), paintLine);
    
    // Bottom Right
    canvas.drawLine(Offset(center.dx + cornerOffset, center.dy + cornerOffset), Offset(center.dx + cornerOffset - bracketLen, center.dy + cornerOffset), paintLine);
    canvas.drawLine(Offset(center.dx + cornerOffset, center.dy + cornerOffset), Offset(center.dx + cornerOffset, center.dy + cornerOffset - bracketLen), paintLine);

    // Crosshairs
    canvas.drawLine(Offset(center.dx, center.dy - 100), Offset(center.dx, center.dy + 100), paintLine);
    canvas.drawLine(Offset(center.dx - 100, center.dy), Offset(center.dx + 100, center.dy), paintLine);
    
    // Concentric circles (Radar style)
    canvas.drawCircle(center, 40, paintLine);
    canvas.drawCircle(center, 80, paintLine);
    
    // Radar sectors
    final path = Path();
    path.addArc(Rect.fromCircle(center: center, radius: 80), -0.5, 1.0);
    path.addArc(Rect.fromCircle(center: center, radius: 80), 3.14 - 0.5, 1.0);
    canvas.drawPath(path, Paint()..color=Colors.white12..style=PaintingStyle.stroke..strokeWidth=20);

    // Center target dot
    canvas.drawCircle(center, 4, paintAccent);
    canvas.drawCircle(center, 8, paintLine);
    if (isCalibrating) {
      canvas.drawCircle(center, 6, paintFill);
    }
  }

  @override
  bool shouldRepaint(covariant ReticlePainter oldDelegate) {
    return oldDelegate.focusPoint != focusPoint || oldDelegate.isCalibrating != isCalibrating;
  }
}
