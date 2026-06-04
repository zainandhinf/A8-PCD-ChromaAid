import 'package:hive/hive.dart';

part 'hive_color_model.g.dart';

@HiveType(typeId: 0)
class HiveColorModel extends HiveObject {
  @HiveField(0)
  String hex;

  @HiveField(1)
  int r;

  @HiveField(2)
  int g;

  @HiveField(3)
  int b;

  @HiveField(4)
  String nama;

  @HiveField(5)
  List<String> tags;

  @HiveField(6)
  String catatan;

  @HiveField(7)
  String sesiId;

  @HiveField(8)
  DateTime savedAt;

  @HiveField(9)
  bool isSynced;

  HiveColorModel({
    required this.hex,
    required this.r,
    required this.g,
    required this.b,
    required this.nama,
    required this.tags,
    required this.catatan,
    required this.sesiId,
    required this.savedAt,
    this.isSynced = false,
  });
}
