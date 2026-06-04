import 'package:hive_flutter/hive_flutter.dart';
import '../models/hive_color_model.dart';

class ColorStorageService {
  static const String _boxName = 'colorsBox';
  Box<HiveColorModel>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<HiveColorModel>(_boxName);
  }

  Future<void> saveColor(HiveColorModel color) async {
    if (_box == null) await init();
    await _box!.add(color);
  }

  List<HiveColorModel> getAllColors() {
    if (_box == null) return [];
    return _box!.values.toList();
  }

  Future<void> updateColor(int index, HiveColorModel color) async {
    if (_box == null) await init();
    await _box!.putAt(index, color);
  }

  Future<void> deleteColor(int index) async {
    if (_box == null) await init();
    await _box!.deleteAt(index);
  }

  Box<HiveColorModel> get box => _box!;
}
