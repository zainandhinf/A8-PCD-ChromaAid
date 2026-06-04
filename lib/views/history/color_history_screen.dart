import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/hive_color_model.dart';
import '../../services/color_storage_service.dart';
import '../../services/session_service.dart';
import '../scanner/scanner_screen.dart';
import 'scan_detail_screen.dart'; // Jika ada

class ColorHistoryScreen extends StatefulWidget {
  const ColorHistoryScreen({super.key});

  @override
  State<ColorHistoryScreen> createState() => _ColorHistoryScreenState();
}

class _ColorHistoryScreenState extends State<ColorHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedSession = 'Semua';
  bool _isSyncing = false;
  late Box<HiveColorModel> _box;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _box = Hive.box<HiveColorModel>('colorsBox');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<HiveColorModel> _getFilteredScans() {
    final all = _box.values.toList();
    if (_selectedSession == 'Semua') {
      return all;
    }
    return all.where((s) => s.sesiId == _selectedSession).toList();
  }

  List<String> get _sessions {
    final s = _box.values.map((e) => e.sesiId).where((id) => id.isNotEmpty).toSet().toList();
    return ['Semua', ...s];
  }

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    await Future.delayed(const Duration(seconds: 1)); // Mock sync
    setState(() => _isSyncing = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sinkronisasi selesai', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF1E1E1E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _deleteScan(int key) async {
    await _box.delete(key);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data dihapus'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _editNote(int key, HiveColorModel scan) async {
    final ctrl = TextEditingController(text: scan.catatan);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Edit Catatan', style: TextStyle(color: Colors.white)),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              scan.catatan = ctrl.text.trim();
              await _box.put(key, scan);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: _buildAppBar(),
      body: ValueListenableBuilder(
        valueListenable: _box.listenable(),
        builder: (context, Box<HiveColorModel> box, _) {
          final filteredScans = _getFilteredScans();
          return Column(
            children: [
              _buildSummaryCards(box.values.toList()),
              _buildSessionFilter(),
              _buildTabBar(filteredScans.length),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildListView(filteredScans),
                    _buildGridView(filteredScans),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan Baru', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final unsyncedCount = _box.values.where((s) => !s.isSynced).length;

    return AppBar(
      backgroundColor: const Color(0xFF1A1A1A),
      elevation: 0,
      title: const Text(
        'Dashboard ChromaAid',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      actions: [
        if (unsyncedCount > 0)
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
              ),
              child: Text(
                '$unsyncedCount belum sync',
                style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        IconButton(
          icon: _isSyncing
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.cloud_sync_outlined, color: Colors.white70),
          tooltip: 'Sync ke MongoDB',
          onPressed: _isSyncing ? null : _syncNow,
        ),
      ],
    );
  }

  Widget _buildSummaryCards(List<HiveColorModel> allScans) {
    final totalScans = allScans.length;
    final totalSessions = _sessions.length - 1; // Minus 'Semua'
    final syncedCount = allScans.where((s) => s.isSynced).length;

    Color avgColor = Colors.grey;
    if (allScans.isNotEmpty) {
      final avgR = allScans.map((s) => s.r).reduce((a, b) => a + b) ~/ allScans.length;
      final avgG = allScans.map((s) => s.g).reduce((a, b) => a + b) ~/ allScans.length;
      final avgB = allScans.map((s) => s.b).reduce((a, b) => a + b) ~/ allScans.length;
      avgColor = Color.fromRGBO(avgR, avgG, avgB, 1);
    }

    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          _StatCard(label: 'Total Scan', value: '$totalScans', icon: Icons.colorize, iconColor: Colors.blueAccent),
          const SizedBox(width: 10),
          _StatCard(label: 'Sesi', value: '$totalSessions', icon: Icons.folder_outlined, iconColor: Colors.purpleAccent),
          const SizedBox(width: 10),
          _StatCard(label: 'Tersync', value: '$syncedCount/$totalScans', icon: Icons.cloud_done_outlined, iconColor: Colors.greenAccent),
          const SizedBox(width: 10),
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
                  Container(width: 28, height: 28, decoration: BoxDecoration(color: avgColor, shape: BoxShape.circle)),
                  const SizedBox(height: 4),
                  const Text('Rata-rata', style: TextStyle(color: Colors.white38, fontSize: 9)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
            onTap: () => setState(() => _selectedSession = s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? Colors.white : Colors.white24),
              ),
              child: Text(
                s,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white60,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar(int filteredCount) {
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
                Text('List ($filteredCount)'),
              ],
            ),
          ),
          const Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.grid_view, size: 16),
                const SizedBox(width: 6),
                Text('Swatch'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<HiveColorModel> filteredScans) {
    if (filteredScans.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filteredScans.length,
      itemBuilder: (_, i) {
        final scan = filteredScans[i];
        final key = scan.key as int;
        return Dismissible(
          key: ValueKey(key),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red.withOpacity(0.15),
            child: const Icon(Icons.delete, color: Colors.redAccent),
          ),
          confirmDismiss: (_) async => _confirmDelete(scan),
          onDismissed: (_) => _deleteScan(key),
          child: _ScanListItem(
            scan: scan,
            onTap: () {}, // Removed scan detail navigation as requested rollback is for dashboard UI.
            onEditNote: () => _editNote(key, scan),
          ),
        );
      },
    );
  }

  Widget _buildGridView(List<HiveColorModel> filteredScans) {
    if (filteredScans.isEmpty) return _buildEmptyState();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: filteredScans.length,
      itemBuilder: (_, i) {
        final scan = filteredScans[i];
        return GestureDetector(
          onTap: () {}, // Disabled detail screen click
          child: _SwatchCell(scan: scan),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.palette_outlined, size: 64, color: Colors.white12),
          const SizedBox(height: 16),
          Text(
            _selectedSession == 'Semua' ? 'Belum ada scan tersimpan' : 'Belum ada scan di "$_selectedSession"',
            style: const TextStyle(color: Colors.white38, fontSize: 15),
          ),
          const SizedBox(height: 8),
          const Text('Buka Scanner dan tekan tombol simpan', style: TextStyle(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(HiveColorModel scan) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text('Hapus Scan', style: TextStyle(color: Colors.white)),
            content: Text('Hapus data "${scan.hex}" dari ${scan.sesiId}?', style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.redAccent))),
            ],
          ),
        ) ??
        false;
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatCard({required this.label, required this.value, required this.icon, required this.iconColor});

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
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
          ],
        ),
      ),
    );
  }
}

class _ScanListItem extends StatelessWidget {
  final HiveColorModel scan;
  final VoidCallback onTap;
  final VoidCallback onEditNote;

  const _ScanListItem({required this.scan, required this.onTap, required this.onEditNote});

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    if (diff.inDays < 7) return '${diff.inDays}h lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final color = Color.fromRGBO(scan.r, scan.g, scan.b, 1.0);
    final isLight = (0.299 * scan.r + 0.587 * scan.g + 0.114 * scan.b) > 128;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onEditNote, // Added long press to edit note
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 72,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)),
              ),
              child: Center(
                child: Text(
                  scan.hex.substring(1, 4),
                  style: TextStyle(color: isLight ? Colors.black54 : Colors.white54, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(scan.hex.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'monospace')),
                        const SizedBox(width: 8),
                        Icon(scan.isSynced ? Icons.cloud_done_outlined : Icons.cloud_upload_outlined, size: 13, color: scan.isSynced ? Colors.greenAccent : Colors.orangeAccent),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text('RGB (${scan.r}, ${scan.g}, ${scan.b})', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    if (scan.catatan.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(scan.catatan, style: const TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                    child: Text(scan.sesiId, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 6),
                  Text(_relativeTime(scan.savedAt), style: const TextStyle(color: Colors.white24, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwatchCell extends StatelessWidget {
  final HiveColorModel scan;
  const _SwatchCell({required this.scan});

  @override
  Widget build(BuildContext context) {
    final color = Color.fromRGBO(scan.r, scan.g, scan.b, 1.0);
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 6,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(4)),
                child: Text(scan.hex, style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
              ),
            ),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: Icon(
              scan.isSynced ? Icons.cloud_done : Icons.cloud_upload,
              size: 10,
              color: scan.isSynced ? Colors.greenAccent.withOpacity(0.8) : Colors.orangeAccent.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
