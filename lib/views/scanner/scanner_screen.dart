import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../../services/pcd_service.dart';
import '../../services/ai_service.dart';
import '../../services/coordinate_service.dart';
import '../../services/scan_storage_service.dart';
import '../../models/color_scan_model.dart';
import '../history/color_history_screen.dart';
import 'reticle_painter.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  DateTime _lastPcdProcessedTime = DateTime.now();
  Size? _previewSize;

  final PcdService _pcdService = PcdService();
  final AiService _aiService = AiService();

  bool _isProcessing = false;
  PcdResult? _currentResult;
  String _detectedObject = "Memuat AI...";
  String _activeSession = 'Percobaan 1';

  // Timestamps untuk membatasi frekuensi AI agar tidak lag
  DateTime _lastAiProcessedTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupSystem();
  }

    Future<void> _setupSystem() async {
      if (_cameraController?.value.isInitialized ?? false) return;
      await _aiService.initModel();
      try {
        final cameras = await availableCameras();
        if (cameras.isEmpty) return;

        _cameraController = CameraController(
          cameras[0],
          ResolutionPreset.medium, // Resolusi aman & jernih
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (!mounted) return;

        setState(() {
          _isCameraInitialized = true;
          _previewSize = _cameraController!.value.previewSize;
        });

        _cameraController!.startImageStream((CameraImage image) async {
          if (_isProcessing) return;
          
          final kini = DateTime.now();
          // Throttling: batasi pemrosesan PCD maksimal ~3 frame per detik
          if (kini.difference(_lastPcdProcessedTime).inMilliseconds < 333) return;
          
          _isProcessing = true;
          _lastPcdProcessedTime = kini;

          try {
            // Cek apakah sudah waktunya menjalankan AI (misal setiap 1200ms)
            final bool shouldRunAi = kini.difference(_lastAiProcessedTime).inMilliseconds > 1200;

            // Kirim semua data dan flag ke background Isolate terpadu
            final backgroundResult = await compute(_executeHeavyTasksInBackground, {
              'image': image,
              'runAi': shouldRunAi,
            });

            if (shouldRunAi) {
              _lastAiProcessedTime = kini;
            }

            if (mounted) {
              setState(() {
                // Ambil hasil ekstraksi warna dari background
                _currentResult = backgroundResult['pcdResult'] as PcdResult?;
                
                // Jika AI berjalan, update labelnya. Jika tidak, gunakan label lama.
                if (shouldRunAi) {
                  _detectedObject = backgroundResult['aiLabel'] as String? ?? _detectedObject;
                }
              });
            }
          } catch (e) {
            debugPrint('Gagal memproses frame di Isolate Terpadu: $e');
          } finally {
            _isProcessing = false;
          }
        });
      } catch (e) {
        debugPrint('Error inisialisasi kamera: $e');
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

  // Meluncurkan bottom sheet untuk menyimpan hasil scan warna
  Future<void> showSaveDialog() async {
    if (_currentResult == null) return;
    final result = _currentResult!;
    final noteController = TextEditingController();
    String selectedSession = _activeSession;

    final existingSessions = ScanStorageService.sessions;
    if (!existingSessions.contains(selectedSession)) {
      existingSessions.add(selectedSession);
    }

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
                    GestureDetector(
                      onTap: () async {
                        final newSession = await showNewSessionDialog();
                        if (newSession != null && newSession.isNotEmpty) {
                          setSheetState(() {
                            existingSessions.add(newSession);
                            selectedSession = newSession;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, color: Colors.white54, size: 14),
                            SizedBox(width: 4),
                            Text('Sesi Baru', style: TextStyle(color: Colors.white54, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
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
                      final scan = ColorScanModel.fromRgb(
                        r: result.r,
                        g: result.g,
                        b: result.b,
                        note: noteController.text.trim(),
                        session: selectedSession,
                      );
                      await ScanStorageService.save(scan);

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

  // Dialog kecil untuk menambahkan kategori/nama sesi percobaan baru
  Future<String?> showNewSessionDialog() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Sesi Baru', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Nama sesi...', hintStyle: TextStyle(color: Colors.white38)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Buat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Offset _getReticleCenter(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    if (_cameraController == null || _previewSize == null) {
      return screenSize.center(Offset.zero);
    }

    return CoordinateService.mapSensorToScreen(
      sensorPoint: Offset(_previewSize!.width / 2, _previewSize!.height / 2),
      sensorSize: Size(_previewSize!.width, _previewSize!.height),
      widgetSize: screenSize,
      isFrontCamera: _cameraController!.description.lensDirection == CameraLensDirection.front,
    );
  }

  @override
  Widget build(BuildContext context) {
    final reticleCenter = _getReticleCenter(context);
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_activeSession, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
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
          if (_isCameraInitialized) CameraPreview(_cameraController!) else const Center(child: CircularProgressIndicator(color: Colors.white)),
          if (_isCameraInitialized) CustomPaint(size: Size.infinite, painter: ReticlePainter(center: reticleCenter)),
          if (_currentResult != null)
            Positioned(
              bottom: 120,
              left: 20,
              right: 20,
              child: ColorInfoPanel(result: _currentResult!, detectedObject: _detectedObject),
            ),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _currentResult != null ? showSaveDialog : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentResult != null ? Color(_currentResult!.colorValue) : Colors.white24,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: (_currentResult != null ? Color(_currentResult!.colorValue) : Colors.white).withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.save_alt_rounded,
                    color: _currentResult?.isLight == true ? Colors.black87 : Colors.white,
                    size: 28,
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

// ── Color Info Panel (Dipisah menjadi widget mandiri di luar kelas State) ──
class ColorInfoPanel extends StatelessWidget {
  final PcdResult result;
  final String detectedObject;
  
  const ColorInfoPanel({
    super.key, 
    required this.result, 
    required this.detectedObject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Color(result.colorValue).withValues(alpha: 0.2), 
            blurRadius: 20,
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Color(result.colorValue),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white38, width: 2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        result.hex,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'monospace', letterSpacing: 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('R: ${result.r}  G: ${result.g}  B: ${result.b}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text('Konteks AI: $detectedObject', style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('PCD: WB → Contrast → Average Pooling 5×5', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<Map<String, dynamic>> _executeHeavyTasksInBackground(Map<String, dynamic> params) async {
  final CameraImage image = params['image'] as CameraImage;
  final bool runAi = params['runAi'] as bool;

  // 1. Jalankan proses PCD (Ekstraksi Warna)
  final pcdService = PcdService();
  final pcdResult = await pcdService.extractColorFromFrame(image);

  String? aiLabel;
  // 2. Jalankan proses AI hanya jika flag runAi bernilai true
  if (runAi) {
    final aiService = AiService();
    // Pastikan initModel atau pemuatan interpreter TFLite aman dijalankan di Isolate ini
    await aiService.initModel(); 
    aiLabel = await aiService.runObjectDetection(image);
  }

  return {
    'pcdResult': pcdResult,
    'aiLabel': aiLabel,
  };
}
