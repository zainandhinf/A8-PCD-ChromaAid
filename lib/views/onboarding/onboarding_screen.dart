import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../scanner/scanner_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101214), // Deep tech dark
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            children: [
              Text(
                'CHROMA_AID_v1.0',
                style: GoogleFonts.spaceMono(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 2.0,
                ),
              ),
              const Spacer(),
              
              // Center Graphic Representation (Simulated Sci-fi Graphic)
              SizedBox(
                height: 250,
                width: 250,
                child: CustomPaint(
                  painter: _OnboardingGraphicPainter(),
                ),
              ),
              
              const Spacer(),
              Text(
                "See Colors\nDifferently",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Real-time color detection for\naccessibility and professional\nworkflows.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              
              // Buttons
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const ScannerScreen()),
                    );
                  },
                  child: Text(
                    'Start Scanning',
                    style: GoogleFonts.spaceMono(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54, width: 1),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  onPressed: () {},
                  child: Text(
                    'Learn More',
                    style: GoogleFonts.spaceMono(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              Text(
                "REAL-TIME DETECTION\nHEX & RGB • EDGE AI",
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceMono(
                  color: Colors.white38,
                  fontSize: 10,
                  letterSpacing: 2.0,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingGraphicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
      
    final paintSolid = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..style = PaintingStyle.fill;
      
    // Background plate
    final RRect outerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(40, 20, size.width - 80, size.height - 80),
      const Radius.circular(16),
    );
    canvas.drawRRect(outerRect, paintSolid);
    canvas.drawRRect(outerRect, paintLine);

    // Lines & crosshairs
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height - 40), paintLine);
    canvas.drawLine(Offset(0, (size.height - 40) / 2), Offset(size.width, (size.height - 40) / 2), paintLine);
    
    // Center dot
    canvas.drawCircle(Offset(size.width / 2, (size.height - 40) / 2), 4, Paint()..color = Colors.white);

    // Color Swatches simulation
    final RRect swatch1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, 48, 64),
      const Radius.circular(0),
    );
    canvas.drawRRect(swatch1, Paint()..color = const Color(0xFFFF5733));
    canvas.drawRect(Rect.fromLTWH(0, 0, 48, 64), Paint()..color = const Color(0xFF2C2C2C)..style = PaintingStyle.stroke);

    final RRect swatch2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width - 64, size.height - 110, 56, 48),
      const Radius.circular(0),
    );
    canvas.drawRRect(swatch2, Paint()..color = const Color(0xFF33FF57));
    
    final RRect swatch3 = RRect.fromRectAndRadius(
      Rect.fromLTWH(40, size.height - 70, 64, 48),
      const Radius.circular(0),
    );
    canvas.drawRRect(swatch3, Paint()..color = const Color(0xFF3357FF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
