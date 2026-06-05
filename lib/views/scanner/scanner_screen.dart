import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../services/pcd_service.dart';
import '../../services/ai_service.dart';
import 'reticle_painter.dart';
import '../detail/color_detail_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  // 1. Panggil class Service yang sudah dibuat
  final PcdService _pcdService = PcdService();
  final AiService _aiService = AiService();

  bool _isProcessing = false;
  String _currentSession = 'Tanpa Sesi';

  // Wadah untuk menyimpan hasil ekstraksi warna
  Map<String, dynamic>? _currentColor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSessionDialog();
    });
    _setupSystem();
  }

  Future<void> _showSessionDialog() async {
    String sesiName = 'Tanpa Sesi';
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white10),
        ),
        title: const Text(
          'Mulai Sesi Baru',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Beri nama objek atau ruangan yang sedang Anda scan.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Contoh: Pakaian Kerja, Ruang Tamu...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.black45,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (v) => sesiName = v,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context, sesiName.trim().isEmpty ? 'Tanpa Sesi' : sesiName);
              },
              child: const Text(
                'Mulai Scanning',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        _currentSession = result;
      });
    }
  }

  // Fungsi gabungan untuk menyalakan AI dan Kamera
  Future<void> _setupSystem() async {
    // Muat model Edge AI ke memori terlebih dahulu
    await _aiService.initModel();

    // Inisialisasi Kamera
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras[0],
          ResolutionPreset.medium, // Resolusi medium agar frame ringan diproses
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (!mounted) return;

        setState(() {
          _isCameraInitialized = true;
        });

        // 2. MENGALIRKAN FRAME KAMERA KE MESIN PCD
        _cameraController!.startImageStream((CameraImage image) async {
          // Jika frame sebelumnya masih diproses, buang frame yang baru masuk
          if (_isProcessing) return;
          _isProcessing = true;

          // Eksekusi Average Pooling di Isolate terpisah
          final rgbResult = await _pcdService.extractColorFromFrame(image);

          // Perbarui UI dengan hasil warna terbaru
          setState(() {
            _currentColor = rgbResult;
          });

          // Buka kunci agar frame berikutnya bisa diproses
          _isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint("Error inisialisasi sistem: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _cameraController?.stopImageStream();
      _cameraController?.dispose();
      _isCameraInitialized = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: Live Feed Kamera
          if (_isCameraInitialized)
            CameraPreview(_cameraController!)
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // Layer 2: Overlay Garis Bidik (Reticle)
          if (_isCameraInitialized) Positioned.fill(child: CustomPaint(painter: AdvancedReticlePainter())),

          // Layer 3: Debug Status Panel (Membuktikan PCD Bekerja)
          if (_currentColor != null)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  final r = _currentColor!['r'] as int;
                  final g = _currentColor!['g'] as int;
                  final b = _currentColor!['b'] as int;
                  final hex = '${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, anim, __) => ColorDetailScreen(
                        r: r,
                        g: g,
                        b: b,
                        hexCode: hex,
                        sesiId: _currentSession,
                        savedAt: DateTime.now().toString().substring(0, 16),
                      ),
                      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  );
                },
                child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    // Lingkaran warna dinamis
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(
                          _currentColor!['r'],
                          _currentColor!['g'],
                          _currentColor!['b'],
                          1,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Teks nilai RGB
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
                          "RGB: ${_currentColor!['r']}, ${_currentColor!['g']}, ${_currentColor!['b']}",
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
          ),
        ],
      ),
    );
  }
}
