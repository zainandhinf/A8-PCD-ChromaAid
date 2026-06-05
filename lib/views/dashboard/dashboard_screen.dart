import 'package:flutter/material.dart';

import '../../models/color_scan_model.dart';
import '../../services/scan_storage_service.dart';
import '../scanner/scanner_screen.dart';
import 'scan_detail_screen.dart';

/// DashboardScreen: pusat data semua hasil scan ChromaAid.
///
/// Fitur:
///   - Statistik ringkasan (total scan, sesi, rata-rata warna)
///   - Filter per sesi percobaan
///   - Tampilan grid swatch warna
///   - Tampilan list detail (HEX, RGB, catatan, timestamp)
///   - Toggle grid/list
///   - Swipe-to-delete + edit catatan
///   - Tombol sync manual ke MongoDB
///   - Indikator status sync per entri
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  List<ColorScanModel> _allScans = [];
  List<ColorScanModel> _filtered = [];
  String _selectedSession = 'Semua';
  bool _isGridView = false;
  bool _isSyncing = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _load() {
    setState(() {
      _allScans = ScanStorageService.loadAll();
      _applyFilter();
    });
  }

  void _applyFilter() {
    if (_selectedSession == 'Semua') {
      _filtered = List.from(_allScans);
    } else {
      _filtered =
          _allScans.where((s) => s.session == _selectedSession).toList();
    }
  }

  List<String> get _sessions => ['Semua', ...ScanStorageService.sessions];

  // ── Sync Manual ───────────────────────────────────────────────────────────

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    final count = await ScanStorageService.syncAll();
    setState(() {
      _isSyncing = false;
      _load();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count > 0
                ? '$count data berhasil disync ke MongoDB'
                : 'Semua data sudah tersync',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1E1E1E),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _deleteScan(ColorScanModel scan) async {
    await ScanStorageService.delete(scan);
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data dihapus'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Edit Note ─────────────────────────────────────────────────────────────

  Future<void> _editNote(ColorScanModel scan) async {
    final ctrl = TextEditingController(text: scan.note);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title:
            const Text('Edit Catatan', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Tulis catatan...',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              await ScanStorageService.updateNote(scan, ctrl.text.trim());
              if (mounted) Navigator.pop(context);
              _load();
            },
            child: const Text('Simpan',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSummaryCards(),
          _buildSessionFilter(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildListView(),
                _buildGridView(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Navigasi ke ScannerScreen
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScannerScreen()),
          );
          // Setelah kembali dari ScannerScreen, refresh data otomatis
          _load();
        },
        backgroundColor: Colors.white, // Kontras dengan tema dark mode kamu
        foregroundColor: Colors.black,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text(
          'Scan Baru',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    final unsyncedCount = ScanStorageService.unsyncedCount;

    return AppBar(
      backgroundColor: const Color(0xFF1A1A1A),
      elevation: 0,
      title: const Text(
        'Dashboard ChromaAid',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      actions: [
        // Indikator unsynced
        if (unsyncedCount > 0)
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
              ),
              child: Text(
                '$unsyncedCount belum sync',
                style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),

        // Tombol sync
        IconButton(
          icon: _isSyncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.cloud_sync_outlined, color: Colors.white70),
          tooltip: 'Sync ke MongoDB',
          onPressed: _isSyncing ? null : _syncNow,
        ),
      ],
    );
  }

  // ── Summary Cards ─────────────────────────────────────────────────────────

  Widget _buildSummaryCards() {
    final totalScans = _allScans.length;
    final totalSessions = ScanStorageService.sessions.length;
    final syncedCount = _allScans.where((s) => s.synced).length;

    // Rata-rata warna dari semua scan yang ada
    Color avgColor = Colors.grey;
    if (_allScans.isNotEmpty) {
      final avgR =
          _allScans.map((s) => s.r).reduce((a, b) => a + b) ~/ _allScans.length;
      final avgG =
          _allScans.map((s) => s.g).reduce((a, b) => a + b) ~/ _allScans.length;
      final avgB =
          _allScans.map((s) => s.b).reduce((a, b) => a + b) ~/ _allScans.length;
      avgColor = Color.fromRGBO(avgR, avgG, avgB, 1);
    }

    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          _StatCard(
            label: 'Total Scan',
            value: '$totalScans',
            icon: Icons.colorize,
            iconColor: Colors.blueAccent,
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: 'Sesi',
            value: '$totalSessions',
            icon: Icons.folder_outlined,
            iconColor: Colors.purpleAccent,
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: 'Tersync',
            value: '$syncedCount/$totalScans',
            icon: Icons.cloud_done_outlined,
            iconColor: Colors.greenAccent,
          ),
          const SizedBox(width: 10),
          // Rata-rata warna (visual)
          Expanded(
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: avgColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: avgColor.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: avgColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Rata-rata',
                    style: TextStyle(color: Colors.white38, fontSize: 9),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Session Filter ────────────────────────────────────────────────────────

  Widget _buildSessionFilter() {
    return Container(
      height: 44,
      color: const Color(0xFF1A1A1A),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _sessions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s = _sessions[i];
          final isSelected = s == _selectedSession;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedSession = s;
              _applyFilter();
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected ? Colors.white : Colors.white24,
                ),
              ),
              child: Text(
                s,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white60,
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── TabBar ────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.list_alt, size: 16),
                const SizedBox(width: 6),
                Text('List (${_filtered.length})'),
              ],
            ),
          ),
          const Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.grid_view, size: 16),
                SizedBox(width: 6),
                Text('Swatch'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── List View ─────────────────────────────────────────────────────────────

  Widget _buildListView() {
    if (_filtered.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filtered.length,
      itemBuilder: (_, i) {
        final scan = _filtered[i];
        return Dismissible(
          key: ValueKey(scan.localId),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red.withOpacity(0.15),
            child: const Icon(Icons.delete, color: Colors.redAccent),
          ),
          confirmDismiss: (_) async {
            return await _confirmDelete(scan);
          },
          onDismissed: (_) => _deleteScan(scan),
          child: _ScanListItem(
            scan: scan,
            onTap: () => _openDetail(scan),
            onEditNote: () => _editNote(scan),
          ),
        );
      },
    );
  }

  // ── Grid / Swatch View ────────────────────────────────────────────────────

  Widget _buildGridView() {
    if (_filtered.isEmpty) return _buildEmptyState();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: _filtered.length,
      itemBuilder: (_, i) {
        final scan = _filtered[i];
        return GestureDetector(
          onTap: () => _openDetail(scan),
          child: _SwatchCell(scan: scan),
        );
      },
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.palette_outlined, size: 64, color: Colors.white12),
          const SizedBox(height: 16),
          Text(
            _selectedSession == 'Semua'
                ? 'Belum ada scan tersimpan'
                : 'Belum ada scan di "$_selectedSession"',
            style: const TextStyle(color: Colors.white38, fontSize: 15),
          ),
          const SizedBox(height: 8),
          const Text(
            'Buka Scanner dan tekan tombol simpan',
            style: TextStyle(color: Colors.white24, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Detail Screen ─────────────────────────────────────────────────────────

  Future<void> _openDetail(ColorScanModel scan) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => ScanDetailScreen(scan: scan),
      ),
    );
    // Refresh dashboard jika scan dihapus dari detail screen
    if (mounted) _load();
  }

  // ── Confirm Delete ────────────────────────────────────────────────────────

  Future<bool> _confirmDelete(ColorScanModel scan) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text('Hapus Scan',
                style: TextStyle(color: Colors.white)),
            content: Text(
              'Hapus data "${scan.hex}" dari ${scan.session}?',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus',
                    style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ) ??
        false;
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: iconColor.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Scan List Item ────────────────────────────────────────────────────────────

class _ScanListItem extends StatelessWidget {
  final ColorScanModel scan;
  final VoidCallback onTap;
  final VoidCallback onEditNote;

  const _ScanListItem({
    required this.scan,
    required this.onTap,
    required this.onEditNote,
  });

  String _relativeTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
      if (diff.inHours < 24) return '${diff.inHours}j lalu';
      if (diff.inDays < 7) return '${diff.inDays}h lalu';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(scan.colorValue);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            // Color swatch
            Container(
              width: 60,
              height: 72,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
              child: Center(
                child: Text(
                  scan.hex.substring(1, 4),
                  style: TextStyle(
                    color: scan.isLight
                        ? Colors.black54
                        : Colors.white54,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          scan.hex.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Sync badge
                        Icon(
                          scan.synced
                              ? Icons.cloud_done_outlined
                              : Icons.cloud_upload_outlined,
                          size: 13,
                          color: scan.synced
                              ? Colors.greenAccent
                              : Colors.orangeAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'RGB (${scan.r}, ${scan.g}, ${scan.b})',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                    if (scan.note.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        scan.note,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Meta: sesi + waktu
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      scan.session,
                      style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _relativeTime(scan.capturedAt),
                    style: const TextStyle(
                        color: Colors.white24, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Swatch Cell ───────────────────────────────────────────────────────────────

class _SwatchCell extends StatelessWidget {
  final ColorScanModel scan;
  const _SwatchCell({required this.scan});

  @override
  Widget build(BuildContext context) {
    final color = Color(scan.colorValue);
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Stack(
        children: [
          // Hex kecil di bawah
          Positioned(
            bottom: 6,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  scan.hex,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
          // Sync dot
          Positioned(
            top: 5,
            right: 5,
            child: Icon(
              scan.synced
                  ? Icons.cloud_done
                  : Icons.cloud_upload,
              size: 10,
              color: scan.synced
                  ? Colors.greenAccent.withOpacity(0.8)
                  : Colors.orangeAccent.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
