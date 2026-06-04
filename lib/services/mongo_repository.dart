import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/hive_color_model.dart';

class MongoRepository {
  static String get _baseUrl => dotenv.env['MONGO_DB_URI'] ?? '';

  static Future<bool> syncData(List<HiveColorModel> unsyncedData) async {
    if (_baseUrl.isEmpty) return false;
    
    try {
      final payload = unsyncedData.map((color) => {
        'hex': color.hex,
        'r': color.r,
        'g': color.g,
        'b': color.b,
        'nama': color.nama,
        'tags': color.tags,
        'catatan': color.catatan,
        'sesiId': color.sesiId,
        'savedAt': color.savedAt.toIso8601String(),
      }).toList();

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'data': payload}),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Mongo Sync Error: $e');
      return false;
    }
  }
}
