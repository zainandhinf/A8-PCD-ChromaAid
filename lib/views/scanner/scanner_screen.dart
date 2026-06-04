import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../services/pcd_service.dart';
import '../../services/ai_service.dart';
import '../../utils/color_utils.dart';
import '../../models/hive_color_model.dart';
import '../../services/color_storage_service.dart';
import '../../services/session_service.dart';
import '../history/color_history_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  final PcdService _pcdService = PcdService();
  final AiService _aiService = AiService();

  bool _isProcessing = false;
  Map<String, dynamic>? _currentColor;

  // Overlay mode: 'hex', 'rgb', 'cmyk'
  String _displayMode = 'hex';

  // Tap to freeze/save
  bool _isFrozen = false;

  // Animation controller for color name fade
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Track previous color for smooth transition
  Map<String, dynamic>? _prevColor;

  DateTime _lastPcdProcessedTime = DateTime.now();
  DateTime _lastAiProcessedTime = DateTime.now();
  String _detectedObject = "Menganalisis...";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _setupSystem();
  }

  Future<void> _setupSystem() async {
    await _aiService.initModel();
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras[0],
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (!mounted) return;
        setState(() => _isCameraInitialized = true);

        _cameraController!.startImageStream((CameraImage image) async {
          if (_isProcessing || _isFrozen) return;
          
          final now = DateTime.now();
          if (now.difference(_lastPcdProcessedTime).inMilliseconds < 333) return;
          
          _isProcessing = true;
          _lastPcdProcessedTime = now;
          
          final rgbResult = await _pcdService.extractColorFromFrame(image);
          
          String? label;
          if (now.difference(_lastAiProcessedTime).inMilliseconds > 1200) {
            label = await _aiService.runObjectDetection(image);
            _lastAiProcessedTime = now;
          }

          if (mounted) {
            setState(() {
              _prevColor = _currentColor;
              // Ensure we convert PcdResult to Map if needed, wait PcdService returns Map or PcdResult?
              // The new scanner screen expects _currentColor to be Map<String, dynamic>?
              // but PcdService.extractColorFromFrame returns PcdResult!
              // I will map it properly.
              _currentColor = {
                'r': rgbResult.r,
                'g': rgbResult.g,
                'b': rgbResult.b,
                'hex': rgbResult.hex
              };
              if (label != null) _detectedObject = label;
            });
            _fadeController.forward(from: 0);
          }
          _isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void _toggleFreeze() {
    HapticFeedback.mediumImpact();
    setState(() => _isFrozen = !_isFrozen);
  }

  void _cycleDisplayMode() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_displayMode == 'hex') _displayMode = 'rgb';
      else if (_displayMode == 'rgb') _displayMode = 'cmyk';
      else _displayMode = 'hex';
    });
  }

  Future<void> _saveColor() async {
    if (_currentColor == null) return;
    HapticFeedback.heavyImpact();
    final int r = _currentColor!['r'];
    final int g = _currentColor!['g'];
    final int b = _currentColor!['b'];
    
    // Gunakan HiveColorModel seperti kesepakatan arsitektur sebelumnya
    final tags = ColorUtils.getColorTags(r, g, b);
    if (!tags.contains(_detectedObject)) {
      tags.insert(0, _detectedObject);
    }
    
    final colorName = ColorUtils.getColorName(r, g, b);
    final hexCode = ColorUtils.rgbToHex(r, g, b);
    final session = SessionService().currentSession;

    final scan = HiveColorModel(
      hex: hexCode,
      r: r,
      g: g,
      b: b,
      nama: colorName,
      tags: tags,
      catatan: '',
      sesiId: session,
      savedAt: DateTime.now(),
    );
    await ColorStorageService().saveColor(scan);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Color.fromRGBO(r, g, b, 1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
              boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 12)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(
                  '${ColorUtils.getColorName(r, g, b)} SAVED',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _cameraController?.stopImageStream();
      _cameraController?.dispose();
      setState(() => _isCameraInitialized = false);
    } else if (state == AppLifecycleState.resumed) {
      _setupSystem();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasColor = _currentColor != null;
    final int r = hasColor ? _currentColor!['r'] : 128;
    final int g = hasColor ? _currentColor!['g'] : 128;
    final int b = hasColor ? _currentColor!['b'] : 128;
    final String hex = ColorUtils.rgbToHex(r, g, b);
    final String colorName = ColorUtils.getColorName(r, g, b);
    final Map<String, int> cmyk = ColorUtils.rgbToCmyk(r, g, b);
    final List<String> tags = ColorUtils.getColorTags(r, g, b);
    final List<Map<String, int>> complements = ColorUtils.getComplementaryColors(r, g, b);

    // Determine if text on swatch should be dark or light
    final double luma = 0.299 * r + 0.587 * g + 0.114 * b;
    final Color textOnColor = luma > 155 ? Colors.black87 : Colors.white;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ─── Layer 1: Camera Feed ────────────────────────────────────
          if (_isCameraInitialized)
            CameraPreview(_cameraController!)
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5),
                    SizedBox(height: 16),
                    Text('INITIALIZING EDGE AI', style: TextStyle(color: Colors.white38, letterSpacing: 2, fontSize: 11)),
                  ],
                ),
              ),
            ),

          // ─── Layer 2: Freeze overlay dim ────────────────────────────
          if (_isFrozen)
            Container(color: Colors.black.withOpacity(0.25)),

          // ─── Layer 3 moved to end of Stack ───────────────────────────

          // ─── Layer 4: Reticle + Center Color Indicator ───────────────
          if (_isCameraInitialized)
            Positioned.fill(
              child: CustomPaint(
                painter: AdvancedReticlePainter(
                  accentColor: hasColor ? Color.fromRGBO(r, g, b, 1) : Colors.white,
                  isFrozen: _isFrozen,
                ),
              ),
            ),

          // ─── Layer 5: Tap to freeze hint ────────────────────────────
          if (_isCameraInitialized && !hasColor)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 140),
                child: Text(
                  'TAP TO FREEZE',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),

          // ─── Layer 6: Main Color Card (bottom) ──────────────────────
          if (hasColor)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildColorCard(
                r: r, g: g, b: b,
                hex: hex, colorName: colorName,
                cmyk: cmyk, tags: tags, complements: complements,
                textOnColor: textOnColor,
              ),
            ),

          // ─── Layer 7: Tap area for freeze ───────────────────────────
          if (_isCameraInitialized)
            Positioned.fill(
              bottom: hasColor ? 320 : 0,
              child: GestureDetector(
                onTap: _toggleFreeze,
                behavior: HitTestBehavior.translucent,
              ),
            ),
            
          // ─── Layer 3: Top HUD (Moved here for z-index) ────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    // App title
                    const Text(
                      'CHROMA_AID',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const Spacer(),
                    // Edge AI badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF00FF88).withOpacity(0.6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              color: _isFrozen ? Colors.orangeAccent : const Color(0xFF00FF88),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(
                                color: (_isFrozen ? Colors.orangeAccent : const Color(0xFF00FF88)).withOpacity(0.7),
                                blurRadius: 4,
                              )],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isFrozen ? 'FROZEN' : 'EDGE AI ACTIVE',
                            style: TextStyle(
                              color: _isFrozen ? Colors.orangeAccent : const Color(0xFF00FF88),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // History button
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ColorHistoryScreen())),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(Icons.history, color: Colors.white, size: 18),
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

  Widget _buildColorCard({
    required int r, required int g, required int b,
    required String hex, required String colorName,
    required Map<String, int> cmyk, required List<String> tags,
    required List<Map<String, int>> complements,
    required Color textOnColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.7), blurRadius: 30, offset: const Offset(0, -10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36, height: 3,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Big color swatch
                GestureDetector(
                  onTap: _cycleDisplayMode,
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(r, g, b, 1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(r, g, b, 0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Color name
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          colorName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Tags
                      Row(
                        children: tags.map((tag) => Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 9,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
                // Confidence badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF88).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF00FF88).withOpacity(0.3)),
                  ),
                  child: const Text(
                    '98%\nMATCH',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF00FF88),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Color Values Panel ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: GestureDetector(
              onTap: _cycleDisplayMode,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.07)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildValueChip('HEX', hex, _displayMode == 'hex'),
                    _buildDivider(),
                    _buildValueChip('RGB', '$r, $g, $b', _displayMode == 'rgb'),
                    _buildDivider(),
                    _buildValueChip(
                      'CMYK',
                      'C${cmyk['c']} M${cmyk['m']} Y${cmyk['y']} K${cmyk['k']}',
                      _displayMode == 'cmyk',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Complementary Colors ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                const Text(
                  'COMPLEMENTARY',
                  style: TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 1.5),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    // current color mini
                    _buildColorDot(r, g, b, size: 28, isActive: true),
                    const SizedBox(width: 6),
                    ...complements.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _buildColorDot(c['r']!, c['g']!, c['b']!, size: 28),
                    )),
                  ],
                ),
              ],
            ),
          ),

          // ── Action Buttons ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              children: [
                // Freeze toggle
                Expanded(
                  child: GestureDetector(
                    onTap: _toggleFreeze,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _isFrozen ? Colors.orangeAccent.withOpacity(0.15) : Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isFrozen ? Colors.orangeAccent.withOpacity(0.5) : Colors.white24,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isFrozen ? Icons.play_arrow : Icons.pause,
                            color: _isFrozen ? Colors.orangeAccent : Colors.white70,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isFrozen ? 'RESUME' : 'FREEZE',
                            style: TextStyle(
                              color: _isFrozen ? Colors.orangeAccent : Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Save button (primary)
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: _saveColor,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(r, g, b, 1),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(r, g, b, 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bookmark_add_outlined, color: textOnColor, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'SAVE TO LIBRARY',
                            style: TextStyle(
                              color: textOnColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom padding for home indicator
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildValueChip(String label, String value, bool isActive) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF00FF88) : Colors.white38,
            fontSize: 9,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white60,
            fontSize: isActive ? 13 : 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 28, color: Colors.white.withOpacity(0.08));
  }

  Widget _buildColorDot(int r, int g, int b, {double size = 28, bool isActive = false}) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: Color.fromRGBO(r, g, b, 1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.white.withOpacity(0.5) : Colors.white.withOpacity(0.12),
          width: isActive ? 2 : 1,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Advanced Reticle Painter — chromatic scanning animation
// ─────────────────────────────────────────────────────────────────────────────

class AdvancedReticlePainter extends CustomPainter {
  final Color accentColor;
  final bool isFrozen;

  AdvancedReticlePainter({required this.accentColor, required this.isFrozen});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.38);
    const double rectSize = 120.0;
    const double cornerLen = 22.0;

    final Paint cornerPaint = Paint()
      ..color = isFrozen ? Colors.orangeAccent : Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint accentPaint = Paint()
      ..color = accentColor.withOpacity(0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final Rect rect = Rect.fromCenter(center: center, width: rectSize, height: rectSize);

    // Draw corner brackets
    _drawCorner(canvas, Offset(rect.left, rect.top), cornerLen, 1, 1, cornerPaint);
    _drawCorner(canvas, Offset(rect.right, rect.top), cornerLen, -1, 1, cornerPaint);
    _drawCorner(canvas, Offset(rect.left, rect.bottom), cornerLen, 1, -1, cornerPaint);
    _drawCorner(canvas, Offset(rect.right, rect.bottom), cornerLen, -1, -1, cornerPaint);

    // Colored border accent
    canvas.drawRect(rect, accentPaint);

    // Center crosshair
    final Paint crossPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(center.dx - 8, center.dy),
      Offset(center.dx + 8, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 8),
      Offset(center.dx, center.dy + 8),
      crossPaint,
    );
    canvas.drawCircle(center, 2.0, Paint()..color = accentColor);

    // Scan line label
    final textPainter = TextPainter(
      text: TextSpan(
        text: isFrozen ? '[ FROZEN ]' : '[ SCANNING ]',
        style: TextStyle(
          color: isFrozen ? Colors.orangeAccent.withOpacity(0.8) : Colors.white.withOpacity(0.6),
          fontSize: 10,
          letterSpacing: 2,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, rect.bottom + 10),
    );
  }

  void _drawCorner(Canvas canvas, Offset point, double len, double dx, double dy, Paint paint) {
    canvas.drawLine(point, Offset(point.dx + len * dx, point.dy), paint);
    canvas.drawLine(point, Offset(point.dx, point.dy + len * dy), paint);
  }

  @override
  bool shouldRepaint(AdvancedReticlePainter old) =>
      old.accentColor != accentColor || old.isFrozen != isFrozen;
}
