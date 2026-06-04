import 'package:flutter/material.dart';
import '../scanner/scanner_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // Color swatches preview
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSwatch(const Color(0xFFFF5733), '#FF5733', 'RED'),
                  const SizedBox(width: 12),
                  _buildSwatch(const Color(0xFF33FF57), '#33FF57', 'GREEN'),
                  const SizedBox(width: 12),
                  _buildSwatch(const Color(0xFF3357FF), '#3357FF', 'BLUE'),
                ],
              ),
              const SizedBox(height: 52),
              const Text(
                "See Colors\nDifferently",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Real-time color detection for\naccessibility and professional\nworkflows.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const ScannerScreen()),
                    );
                  },
                  child: const Text(
                    "Start Scanning",
                    style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {},
                  child: const Text("Learn More"),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                "REAL-TIME DETECTION\nHEX & RGB • EDGE AI",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white38,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwatch(Color color, String hex, String label) {
    return Column(
      children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 16, offset: const Offset(0, 6))],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1)),
        Text(hex, style: const TextStyle(color: Colors.white38, fontSize: 9)),
      ],
    );
  }
}
