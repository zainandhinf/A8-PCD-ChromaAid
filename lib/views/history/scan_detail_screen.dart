import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/hive_color_model.dart';
import '../../utils/color_utils.dart';

class ScanDetailScreen extends StatelessWidget {
  final int r, g, b;
  final String hex;
  final String colorName;
  final String objectLabel;
  
  const ScanDetailScreen({
    super.key,
    required this.r,
    required this.g,
    required this.b,
    required this.hex,
    required this.colorName,
    required this.objectLabel,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = Color.fromRGBO(r, g, b, 1.0);
    final isLight = (0.299 * r + 0.587 * g + 0.114 * b) > 128;
    final topTextColor = isLight ? Colors.black54 : Colors.white70;
    
    final cmyk = ColorUtils.rgbToCmyk(r, g, b);
    final compColor = ColorUtils.getComplementaryColor(r, g, b);
    
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Top Bar elements
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Text(
                    'SCN_ID: ${(r+g+b/3).toStringAsFixed(1)}\nCAP_TL: 12:44:01',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.spaceMono(color: topTextColor, fontSize: 10, letterSpacing: 1.5),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Info Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 150),
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: Color(0xFF141618),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            colorName.replaceAll(' ', '\n').toUpperCase(),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(border: Border.all(color: Colors.white38)),
                          child: Text(
                            '94%\nCONFIDENCE',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildTag('[NATURAL]'),
                        const SizedBox(width: 8),
                        _buildTag('[STONE]'),
                        const SizedBox(width: 8),
                        _buildTag('[EXTERIOR]'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Diagnostic Values
                    _buildBoxSection(
                      title: 'DIAGNOSTIC VALUES',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('HEX: $hex', style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 12)),
                          const SizedBox(height: 12),
                          Text('RGB: $r, $g, $b', style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 12)),
                          const SizedBox(height: 12),
                          Text('CMYK: ${cmyk['c']}, ${cmyk['m']}, ${cmyk['y']}, ${cmyk['k']}', style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Complementary Array
                    _buildBoxSection(
                      title: 'COMPLEMENTARY ARRAY',
                      child: Row(
                        children: [
                          _buildMiniSwatch(Color.fromRGBO(r, g, b, 1.0).withOpacity(0.5)),
                          const SizedBox(width: 8),
                          _buildMiniSwatch(Color.fromRGBO(g, b, r, 1.0)),
                          const SizedBox(width: 8),
                          _buildMiniSwatch(compColor.withOpacity(0.7)),
                          const SizedBox(width: 8),
                          _buildMiniSwatch(compColor),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    const Divider(color: Colors.white24, thickness: 1),
                    const SizedBox(height: 16),
                    
                    Center(
                      child: TextButton(
                        onPressed: () {
                          // Save logic
                        },
                        child: Text(
                          'SAVE TO LIBRARY',
                          style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white54,
                          side: const BorderSide(color: Colors.white38, width: 1),
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          '[ RETAKE ]',
                          style: GoogleFonts.spaceMono(fontSize: 12, letterSpacing: 2.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(border: Border.all(color: Colors.white24)),
      child: Text(text, style: GoogleFonts.spaceMono(color: Colors.white54, fontSize: 10)),
    );
  }

  Widget _buildBoxSection({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101214),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white12))),
            child: Text(title, style: GoogleFonts.spaceMono(color: Colors.white54, fontSize: 10, letterSpacing: 1.5)),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniSwatch(Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.white38, width: 1),
      ),
    );
  }
}
