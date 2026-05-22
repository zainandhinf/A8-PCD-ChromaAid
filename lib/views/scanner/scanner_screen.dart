import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/pcd_service.dart';
import '../../services/ai_service.dart';
import '../../services/scan_storage_service.dart';
import '../../models/color_scan_model.dart';

/// ScannerScreen: live camera + PCD pipeline + save ke Hive/MongoDB.
///
/// Alur:
///   1. Kamera aktif → frame terus diproses PCD (real-time preview)
///   2. Pengguna menekan tombol simpan → dialog konfirmasi (note + sesi)
///   3. Data disimpan ke Hive (lokal) dan di-sync ke MongoDB di background
///   4. Tombol riwayat di AppBar → ke DashboardScreen
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  final PcdService _pcdService = PcdService();
  final AiService _aiService = AiService();

  bool _isProcessing = false;
  PcdResult? _currentResult;

  // State sesi aktif (bisa diubah dari dialog)
  String _activeSession = 'Percobaan 1';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupSystem();
  }

  Future<void> _setupSystem() async {
    await _aiService.initModel();
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() => _isCameraInitialized = true);

      _cameraController!.startImageStream((CameraImage image) async {
        if (_isProcessing) return;
        _isProcessing = true;

        final result = await _pcdService.extractColorFromFrame(image);
        if (mounted) setState(() => _currentResult = result);

        _isProcessing = false;
      });
    } catch (e) {
      debugPrint('Error inisialisasi kamera: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
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

  // ── Save Dialog ───────────────────────────────────────────────────────────

  Future<void> _showSaveDialog() async {
    if (_currentResult == null) return;
    final result = _currentResult!;

    final noteController = TextEditingController();
    String selectedSession = _activeSession;

    // Ambil daftar sesi yang sudah ada
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
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
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
                // Header
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
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Pilih sesi
                const Text(
                  'SESI PERCOBAAN',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...existingSessions.map((s) => GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedSession = s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: selectedSession == s
                                  ? Colors.white
                                  : Colors.white12,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              s,
                              style: TextStyle(
                                color: selectedSession == s
                                    ? Colors.black
                                    : Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )),
                    // Tombol tambah sesi baru
                    GestureDetector(
                      onTap: () async {
                        final newSession =
                            await _showNewSessionDialog();
                        if (newSession != null && newSession.isNotEmpty) {
                          setSheetState(() {
                            existingSessions.add(newSession);
                            selectedSession = newSession;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
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
                            Text('Sesi Baru',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Catatan opsional
                const Text(
                  'CATATAN (OPSIONAL)',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Cahaya matahari sore, objek plastik...',
                    hintStyle:
                        const TextStyle(color: Colors.white24, fontSize: 13),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Tombol Simpan
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

                      // Haptic + SnackBar konfirmasi
                      await HapticFeedback.mediumImpact();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(children: [
                              Icon(Icons.check_circle,
                                  color: Color(result.colorValue), size: 18),
                              const SizedBox(width: 10),
                              Text(
                                'Tersimpan ke "$selectedSession"',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ]),
                            backgroundColor: const Color(0xFF1E1E1E),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Simpan Hasil Scan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _showNewSessionDialog() async {
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
          decoration: const InputDecoration(
            hintText: 'Nama sesi...',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Buat',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _activeSession,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard_outlined, color: Colors.white70),
            tooltip: 'Dashboard',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DashboardPlaceholder(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: Camera Preview ──────────────────────────────────────
          if (_isCameraInitialized)
            CameraPreview(_cameraController!)
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white)),

          // ── Layer 2: Reticle ─────────────────────────────────────────────
          if (_isCameraInitialized) CustomPaint(painter: ReticlePainter()),

          // ── Layer 3: Color Info Panel ─────────────────────────────────────
          if (_currentResult != null)
            Positioned(
              bottom: 120,
              left: 20,
              right: 20,
              child: _ColorInfoPanel(result: _currentResult!),
            ),

          // ── Layer 4: Save Button ──────────────────────────────────────────
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _currentResult != null ? _showSaveDialog : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentResult != null
                        ? Color(_currentResult!.colorValue)
                        : Colors.white24,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: (_currentResult != null
                                ? Color(_currentResult!.colorValue)
                                : Colors.white)
                            .withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.save_alt_rounded,
                    color: _currentResult?.isLight == true
                        ? Colors.black87
                        : Colors.white,
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

// ── Color Info Panel ─────────────────────────────────────────────────────────

class _ColorInfoPanel extends StatelessWidget {
  final PcdResult result;
  const _ColorInfoPanel({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Color(result.colorValue).withValues(alpha: 0.2),
            blurRadius: 20,
          ),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        result.hex,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'R: ${result.r}  G: ${result.g}  B: ${result.b}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 2),
                const Text(
                  'PCD: WB → Contrast → Average Pooling 5×5',
                  style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reticle ───────────────────────────────────────────────────────────────────

class ReticlePainter extends CustomPainter {
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

    // Corner accents
    const cornerLen = 16.0;
    final corners = [
      [center - const Offset(rectSize / 2, rectSize / 2), true, true],
      [center - const Offset(-rectSize / 2, rectSize / 2), false, true],
      [center - const Offset(rectSize / 2, -rectSize / 2), true, false],
      [center - const Offset(-rectSize / 2, -rectSize / 2), false, false],
    ];

    final accentPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (final c in corners) {
      final Offset pos = c[0] as Offset;
      final bool goRight = c[1] as bool;
      final bool goDown = c[2] as bool;

      canvas.drawLine(pos,
          pos + Offset(goRight ? cornerLen : -cornerLen, 0), accentPaint);
      canvas.drawLine(pos,
          pos + Offset(0, goDown ? cornerLen : -cornerLen), accentPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Placeholder untuk navigasi — diganti dengan DashboardScreen yang asli.
class DashboardPlaceholder extends StatelessWidget {
  const DashboardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: const Center(child: Text('Import DashboardScreen di sini')),
    );
  }
}

// ── Tambahkan import ini di bagian atas file scanner_screen.dart ──────────────
// import '../dashboard/dashboard_screen.dart';
//
// Lalu ganti DashboardPlaceholder() dengan DashboardScreen() pada onPressed
// di _buildAppBar().
