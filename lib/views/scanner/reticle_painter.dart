import 'package:flutter/material.dart';

class AdvancedReticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.38);
    const rectSize = 120.0;
    const cornerLen = 22.0;
    final rect = Rect.fromCenter(center: center, width: rectSize, height: rectSize);

    // Gambar 4 sudut (corner brackets)
    Paint p = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Kiri atas
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(cornerLen, 0), p);
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(0, cornerLen), p);

    // Kanan atas
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(-cornerLen, 0), p);
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(0, cornerLen), p);

    // Kiri bawah
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(cornerLen, 0), p);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(0, -cornerLen), p);

    // Kanan bawah
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(-cornerLen, 0), p);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(0, -cornerLen), p);

    // Gambar crosshair
    canvas.drawLine(Offset(center.dx - 8, center.dy), Offset(center.dx + 8, center.dy), p);
    canvas.drawLine(Offset(center.dx, center.dy - 8), Offset(center.dx, center.dy + 8), p);

    // Lingkaran kecil di tengah
    canvas.drawCircle(center, 2.5, Paint()..color = Colors.white);

    // Label SCANNING di bawah kotak
    TextPainter tp = TextPainter(
      text: const TextSpan(
        text: '[ SCANNING ]',
        style: TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 1.5),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, rect.bottom + 8));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
