import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/hive_color_model.dart';
import 'services/color_storage_service.dart';
import 'views/onboarding/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientasi portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Load .env (MONGODB_URI, dll)
  await dotenv.load(fileName: '.env');

  // Inisialisasi Hive
  await Hive.initFlutter();

  // Daftarkan adapter
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(HiveColorModelAdapter());
  }

  // Buka box
  await Hive.openBox<HiveColorModel>('colorsBox');

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
