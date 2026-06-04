import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/pcd_service.dart';
import '../../services/ai_service.dart';
import '../../services/coordinate_service.dart';
import '../../services/color_storage_service.dart';
import '../../services/session_service.dart';
import '../../models/hive_color_model.dart';
import '../../utils/color_utils.dart';
import '../history/color_history_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  final PcdService _pcdService = PcdService();
  final AiService _aiService = AiService();

  bool _isProcessing = false;
  DateTime _lastAiProcessedTime = DateTime.now();
  DateTime _lastPcdProcessedTime = DateTime.now();
  PcdResult? _currentResult;
  String _detectedObject = "Menganalisis...";
  String _activeSession = 'Sesi Utama';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _activeSession = SessionService().currentSession;
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

        setState(() {
          _isCameraInitialized = true;
        });

        _cameraController!.startImageStream((CameraImage image) async {
          if (_isProcessing) return;
          
          final now = DateTime.now();
          if (now.difference(_lastPcdProcessedTime).inMilliseconds < 333) return;
          
          _isProcessing = true;
          _lastPcdProcessedTime = now;

          final rgbResult = await _pcdService.extractColorFromFrame(image);
          
          final kini = DateTime.now();
          String? label;
          if (kini.difference(_lastAiProcessedTime).inMilliseconds > 1200) {
            label = await _aiService.runObjectDetection(image);
            _lastAiProcessedTime = kini;
          }

          if (mounted) {
            setState(() {
              _currentResult = rgbResult;
              if (label != null) _detectedObject = label;
            });
          }

          _isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint("Error inisialisasi sistem: $e");
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
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> showSaveDialog() async {
    if (_currentResult == null) return;
    final result = _currentResult!;
    final noteController = TextEditingController();
    String selectedSession = _activeSession;

    final existingSessions = SessionService().getAvailableSessions();
    if (!existingSessions.contains(selectedSession)) {
      existingSessions.add(selectedSession);
    }
    
    final colorName = ColorUtils.getNearestColorName(result.r, result.g, result.b);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(result.colorValue),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.hex,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          'RGB (${result.r}, ${result.g}, ${result.b})',
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'SESI PERCOBAAN',
                  style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...existingSessions.map((s) => GestureDetector(
                          onTap: () => setSheetState(() => selectedSession = s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: selectedSession == s ? Colors.white : Colors.white12,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              s,
                              style: TextStyle(
                                color: selectedSession == s ? Colors.black : Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'CATATAN (OPSIONAL)',
                  style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Cahaya matahari sore, objek plastik...',
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final scan = HiveColorModel(
                        hex: result.hex,
                        r: result.r,
                        g: result.g,
                        b: result.b,
                        nama: colorName,
                        tags: [_detectedObject],
                        catatan: noteController.text.trim(),
                        sesiId: selectedSession,
                        savedAt: DateTime.now(),
                      );
                      await ColorStorageService().saveColor(scan);

                      setState(() => _activeSession = selectedSession);
                      if (ctx.mounted) Navigator.pop(ctx);

                      await HapticFeedback.mediumImpact();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(children: [
                              Icon(Icons.check_circle, color: Color(result.colorValue), size: 18),
                              const SizedBox(width: 10),
                              Text('Tersimpan ke "$selectedSession"', style: const TextStyle(color: Colors.white)),
                            ]),
                            backgroundColor: const Color(0xFF1E1E1E),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    },
                    child: const Text('Simpan Hasil Scan', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard_outlined, color: Colors.white70),
            tooltip: 'Dashboard',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ColorHistoryScreen()));
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: Live Feed Kamera
          if (_isCameraInitialized) CameraPreview(_cameraController!) else const Center(child: CircularProgressIndicator(color: Colors.white)),
          
          // Layer 2: Overlay Garis Bidik (Reticle lama)
          if (_isCameraInitialized) CustomPaint(painter: ReticlePainterOld()),

          // Layer 3: Debug Status Panel (Tampilan lama prototype)
          if (_currentResult != null)
            Positioned(
              bottom: 120, // Naikan sedikit untuk save button
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color(_currentResult!.colorValue),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "AVERAGE POOLING (5x5)",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          "RGB: ${_currentResult!.r}, ${_currentResult!.g}, ${_currentResult!.b}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Tombol Save (Tetap dipertahankan agar bisa nyimpan)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _currentResult != null ? showSaveDialog : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentResult != null ? Color(_currentResult!.colorValue) : Colors.white24,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Icon(
                    Icons.save_alt_rounded,
                    color: _currentResult?.isLight == true ? Colors.black87 : Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReticlePainterOld extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    const rectSize = 100.0;

    canvas.drawRect(
      Rect.fromCenter(center: center, width: rectSize, height: rectSize),
      paint,
    );

    canvas.drawCircle(center, 3.0, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
