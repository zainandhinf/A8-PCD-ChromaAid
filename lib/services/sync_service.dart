import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/hive_color_model.dart';
import 'mongo_repository.dart';

class SyncService {
  static Future<void> checkAndSync() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      return; 
    }

    final box = Hive.box<HiveColorModel>('colorsBox');
    final unsyncedColors = box.values.where((c) => !c.isSynced).toList();

    if (unsyncedColors.isEmpty) return;

    final success = await MongoRepository.syncData(unsyncedColors);
    
    if (success) {
      for (var color in unsyncedColors) {
        color.isSynced = true;
        color.save(); 
      }
    }
  }
}
