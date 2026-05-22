import 'package:hive/hive.dart';

part 'color_scan_model.g.dart';

/// Model satu hasil scan warna dari ScannerScreen.
///
/// Setiap kali pengguna menekan tombol "Save" di scanner,
/// satu entri ColorScanModel dibuat dan disimpan ke Hive + MongoDB.
@HiveType(typeId: 0)
class ColorScanModel extends HiveObject {
  /// ID dari MongoDB (null jika belum sync)
  @HiveField(0)
  String? mongoId;

  /// ID lokal unik (timestamp + random) untuk deduplikasi
  @HiveField(1)
  String localId;

  /// Nilai RGB hasil PCD pipeline (Average Pooling 5×5)
  @HiveField(2)
  int r;

  @HiveField(3)
  int g;

  @HiveField(4)
  int b;

  /// Hex color string, e.g. "#FF5733"
  @HiveField(5)
  String hex;

  /// Nama warna terdekat hasil KNN (opsional, bisa kosong jika belum ada ML)
  @HiveField(6)
  String colorName;

  /// Catatan dari pengguna (opsional)
  @HiveField(7)
  String note;

  /// Timestamp ISO 8601
  @HiveField(8)
  String capturedAt;

  /// Status sync ke MongoDB
  @HiveField(9)
  bool synced;

  /// Sesi percobaan — pengelompokan manual (e.g. "Percobaan 1", "Lab Test A")
  @HiveField(10)
  String session;

  ColorScanModel({
    this.mongoId,
    required this.localId,
    required this.r,
    required this.g,
    required this.b,
    required this.hex,
    this.colorName = '',
    this.note = '',
    required this.capturedAt,
    this.synced = false,
    this.session = 'Default',
  });

  /// Buat dari nilai RGB saat ini
  factory ColorScanModel.fromRgb({
    required int r,
    required int g,
    required int b,
    String colorName = '',
    String note = '',
    String session = 'Default',
  }) {
    final hex =
        '#${r.toRadixString(16).padLeft(2, '0').toUpperCase()}'
        '${g.toRadixString(16).padLeft(2, '0').toUpperCase()}'
        '${b.toRadixString(16).padLeft(2, '0').toUpperCase()}';
    return ColorScanModel(
      localId: '${DateTime.now().millisecondsSinceEpoch}',
      r: r,
      g: g,
      b: b,
      hex: hex,
      colorName: colorName,
      note: note,
      capturedAt: DateTime.now().toIso8601String(),
      session: session,
    );
  }

  /// Untuk dikirim ke MongoDB
  Map<String, dynamic> toMap() => {
        'localId': localId,
        'r': r,
        'g': g,
        'b': b,
        'hex': hex,
        'colorName': colorName,
        'note': note,
        'capturedAt': capturedAt,
        'session': session,
      };

  factory ColorScanModel.fromMap(Map<String, dynamic> map) => ColorScanModel(
        mongoId: map['_id']?.toString(),
        localId: map['localId'] ?? '',
        r: (map['r'] as num).toInt(),
        g: (map['g'] as num).toInt(),
        b: (map['b'] as num).toInt(),
        hex: map['hex'] ?? '#000000',
        colorName: map['colorName'] ?? '',
        note: map['note'] ?? '',
        capturedAt: map['capturedAt'] ?? DateTime.now().toIso8601String(),
        synced: true,
        session: map['session'] ?? 'Default',
      );

  /// Flutter Color dari nilai RGB
  int get colorValue => (0xFF << 24) | (r << 16) | (g << 8) | b;

  /// Luminance sederhana untuk memilih warna teks
  bool get isLight => (0.299 * r + 0.587 * g + 0.114 * b) > 128;
}
