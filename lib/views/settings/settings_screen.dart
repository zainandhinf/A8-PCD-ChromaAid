import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/hive_color_model.dart';
import '../../services/ai_service.dart';

class SettingsScreen extends StatefulWidget {
  final AiService aiService;
  const SettingsScreen({super.key, required this.aiService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _aiThreshold = 0.45;
  String _colorMode = 'Normal';
  final List<String> _colorModes = ['Normal', 'Protanopia', 'Deuteranopia'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _aiThreshold = prefs.getDouble('ai_threshold') ?? 0.45;
      _colorMode = prefs.getString('color_mode') ?? 'Normal';
    });
  }

  Future<void> _saveAiThreshold(double value) async {
    setState(() => _aiThreshold = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('ai_threshold', value);
    widget.aiService.updateThreshold(value);
  }

  Future<void> _saveColorMode(String mode) async {
    setState(() => _colorMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('color_mode', mode);
  }

  Future<void> _purgeHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Purge History', style: TextStyle(color: Colors.redAccent)),
        content: const Text('Apakah Anda yakin ingin menghapus SEMUA riwayat warna? Tindakan ini tidak dapat dibatalkan.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('HAPUS SEMUA', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final box = Hive.box<HiveColorModel>('colorsBox');
      await box.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Riwayat berhasil dihapus total.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Pengaturan', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Kecerdasan Buatan (Edge AI)', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sensitivitas AI (Threshold)', style: TextStyle(color: Colors.white)),
                    Text(_aiThreshold.toStringAsFixed(2), style: const TextStyle(color: Colors.orangeAccent)),
                  ],
                ),
                Slider(
                  value: _aiThreshold,
                  min: 0.1,
                  max: 1.0,
                  divisions: 90,
                  activeColor: Colors.orangeAccent,
                  onChanged: _saveAiThreshold,
                ),
                const Text('Nilai yang lebih rendah membuat AI lebih mudah mendeteksi objek namun rentan salah tebak.', style: TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text('Aksesibilitas', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: const Color(0xFF2C2C2C),
                value: _colorMode,
                isExpanded: true,
                style: const TextStyle(color: Colors.white),
                items: _colorModes.map((String mode) {
                  return DropdownMenuItem<String>(
                    value: mode,
                    child: Text('Simulasi Buta Warna: $mode'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) _saveColorMode(val);
                },
              ),
            ),
          ),
          const SizedBox(height: 40),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.1),
              foregroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.delete_forever),
            label: const Text('PURGE HISTORY', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: _purgeHistory,
          ),
        ],
      ),
    );
  }
}
