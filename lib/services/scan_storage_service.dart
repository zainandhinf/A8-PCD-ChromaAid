import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Box;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/color_scan_model.dart';

/// ScanStorageService: persistensi offline-first untuk hasil scan.
///
/// Arsitektur:
///   - Setiap scan langsung disimpan ke Hive (selalu berhasil, offline).
///   - Sync ke MongoDB Atlas dilakukan di background saat online.
///   - Jika koneksi putus, sync otomatis dilanjutkan saat online kembali.
///   - Tidak ada data yang hilang — offline data selalu aman di Hive.
class ScanStorageService {
  static const String _boxName = 'color_history';
  static const String _collection = 'color_scans';

  static Db? _db;
  static bool _dbConnected = false;

  // ── Hive Box ──────────────────────────────────────────────────────────────

  static Box<ColorScanModel> get _box =>
      Hive.box<ColorScanModel>(_boxName);

  // ── Public API ────────────────────────────────────────────────────────────

  /// Simpan hasil scan baru.
  /// Hive dulu (sync), MongoDB di background.
  static Future<void> save(ColorScanModel scan) async {
    await _box.add(scan);
    _syncInBackground();
  }

  /// Ambil semua scan, diurutkan dari terbaru.
  static List<ColorScanModel> loadAll() {
    final list = _box.values.toList();
    list.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    return list;
  }

  /// Ambil scan berdasarkan sesi tertentu.
  static List<ColorScanModel> loadBySession(String session) {
    return loadAll().where((s) => s.session == session).toList();
  }

  /// Semua nama sesi unik yang pernah dibuat.
  static List<String> get sessions {
    final all = _box.values.map((s) => s.session).toSet().toList();
    all.sort();
    return all;
  }

  /// Hapus satu entri (lokal + MongoDB).
  static Future<void> delete(ColorScanModel scan) async {
    // Hapus dari Hive
    final key = _box.keys.firstWhere(
      (k) => _box.get(k)?.localId == scan.localId,
      orElse: () => null,
    );
    if (key != null) await _box.delete(key);

    // Hapus dari MongoDB jika sudah sync
    if (scan.synced) {
      try {
        await _ensureConnected();
        final col = _db!.collection(_collection);
        await col.deleteOne({'localId': scan.localId});
      } catch (_) {} // Tidak blocking jika gagal
    }
  }

  /// Update catatan (note) pada entri yang sudah ada.
  static Future<void> updateNote(ColorScanModel scan, String newNote) async {
    scan.note = newNote;
    await scan.save();

    if (scan.synced && scan.mongoId != null) {
      try {
        await _ensureConnected();
        final col = _db!.collection(_collection);
        await col.updateOne(
          {'localId': scan.localId},
          {'\$set': {'note': newNote}},
        );
      } catch (_) {}
    }
  }

  /// Force sync semua data yang belum tersync.
  static Future<int> syncAll() async {
    final unsynced = _box.values.where((s) => !s.synced).toList();
    if (unsynced.isEmpty) return 0;

    int count = 0;
    try {
      await _ensureConnected();
      final col = _db!.collection(_collection);

      for (final scan in unsynced) {
        try {
          final existing = await col.findOne({'localId': scan.localId});
          if (existing == null) {
            final result = await col.insertOne(scan.toMap());
            scan.mongoId = result.id?.toString();
          } else {
            await col.replaceOne({'localId': scan.localId}, scan.toMap());
          }
          scan.synced = true;
          await scan.save();
          count++;
        } catch (_) {}
      }
    } catch (_) {}
    return count;
  }

  /// Dengarkan perubahan koneksi → auto sync saat online.
  static void listenToConnectivity() {
    Connectivity().onConnectivityChanged.listen((results) {
      if (_hasConnection(results)) {
        syncAll();
      }
    });
  }

  // ── Statistik untuk Dashboard ─────────────────────────────────────────────

  /// Jumlah total scan.
  static int get totalScans => _box.length;

  /// Jumlah scan yang belum tersync.
  static int get unsyncedCount =>
      _box.values.where((s) => !s.synced).length;

  /// Rata-rata RGB dari semua scan dalam sesi tertentu.
  static Map<String, double> averageRgb(String session) {
    final scans = loadBySession(session);
    if (scans.isEmpty) return {'r': 0, 'g': 0, 'b': 0};
    final avgR = scans.map((s) => s.r).reduce((a, b) => a + b) / scans.length;
    final avgG = scans.map((s) => s.g).reduce((a, b) => a + b) / scans.length;
    final avgB = scans.map((s) => s.b).reduce((a, b) => a + b) / scans.length;
    return {'r': avgR, 'g': avgG, 'b': avgB};
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static void _syncInBackground() {
    Connectivity().checkConnectivity().then((results) {
      if (_hasConnection(results)) syncAll();
    });
  }

  static bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  static Future<void> _ensureConnected() async {
    if (_dbConnected && _db != null) {
      try {
        await _db!.getCollectionNames();
        return;
      } catch (_) {
        _dbConnected = false;
        await _db?.close();
      }
    }

    final uri = dotenv.env['MONGODB_URI'];
    if (uri == null || uri.isEmpty) {
      throw Exception('MONGODB_URI tidak ditemukan di .env');
    }

    _db = await Db.create(uri);
    await _db!.open();
    _dbConnected = true;
  }
}
