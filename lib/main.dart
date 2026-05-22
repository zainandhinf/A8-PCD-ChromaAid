import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/color_scan_model.dart';
import 'services/scan_storage_service.dart';
import 'views/onboarding/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientasi portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Load .env (MONGODB_URI, dll)
  await dotenv.load(fileName: '.env');

  // Inisialisasi Hive
  await Hive.initFlutter();

  // Daftarkan adapter ColorScanModel (typeId: 0)
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ColorScanModelAdapter());
  }

  // Buka box color_history
  await Hive.openBox<ColorScanModel>('color_history');

  // Mulai auto-sync saat koneksi kembali online
  ScanStorageService.listenToConnectivity();

  runApp(const ChromaAidApp());
}

class ChromaAidApp extends StatelessWidget {
  const ChromaAidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChromaAid',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.white70,
        ),
        useMaterial3: true,
      ),
      home: const OnboardingScreen(),
    );
  }
}
