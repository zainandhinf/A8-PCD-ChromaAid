import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/hive_color_model.dart';
import '../../services/ai_service.dart';
import '../widgets/custom_bottom_nav.dart';

class SettingsScreen extends StatefulWidget {
  final AiService aiService;
  const SettingsScreen({super.key, required this.aiService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _aiThreshold = 0.85;
  String _colorMode = 'NORMAL';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _aiThreshold = prefs.getDouble('ai_threshold') ?? 0.85;
      _colorMode = prefs.getString('color_mode') ?? 'NORMAL';
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
        backgroundColor: const Color(0xFF101214),
        shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.red), borderRadius: BorderRadius.circular(0)),
        title: Text('PURGE HISTORY', style: GoogleFonts.spaceMono(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to purge all local storage data?', style: GoogleFonts.spaceMono(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL', style: GoogleFonts.spaceMono(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('CONFIRM', style: GoogleFonts.spaceMono(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final box = Hive.box<HiveColorModel>('colorsBox');
      await box.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101214),
      appBar: AppBar(
        title: Text('CHROMA_AID_V1.0', style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 14)),
        centerTitle: true,
        backgroundColor: const Color(0xFF101214),
        elevation: 0,
        leading: const Icon(Icons.wifi_tethering, color: Colors.white),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.settings, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SYSTEM CONFIG', style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Diagnostic and accessibility parameters.', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 24),
            
            // COLOR_MODE_OVERRIDE
            _buildSection(
              title: 'COLOR_MODE_OVERRIDE',
              child: Row(
                children: [
                  _buildToggleBtn('NORMAL'),
                  _buildToggleBtn('PROTAN'),
                  _buildToggleBtn('DEUTER'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // ANALYSIS_PARAMETERS
            _buildSection(
              title: 'ANALYSIS_PARAMETERS',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('AI_CONFIDENCE_THRESHOLD', style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 12)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: Colors.white12,
                        child: Text('${(_aiThreshold * 100).toInt()}%', style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2,
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6, disabledThumbRadius: 6),
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: _aiThreshold,
                      min: 0.1,
                      max: 1.0,
                      onChanged: _saveAiThreshold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('SAMPLE_AREA_MODE', style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('[ SMALL_POINT ]', style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      Text('AVERAGE_AREA', style: GoogleFonts.spaceMono(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // SYSTEM_DIAGNOSTICS
            _buildSection(
              title: 'SYSTEM_DIAGNOSTICS',
              child: Column(
                children: [
                  _buildDiagnosticRow('LOCAL_STORAGE', '12MB ALLOCATED'),
                  const SizedBox(height: 12),
                  _buildDiagnosticRow('CLOUD_UPLINK', '● MDB_ATLAS_SYNC'),
                  const SizedBox(height: 12),
                  _buildDiagnosticRow('FIRMWARE', 'v1.0.44b'),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // PURGE BUTTON
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: BorderSide(color: Colors.redAccent.withOpacity(0.5), width: 1),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  backgroundColor: Colors.redAccent.withOpacity(0.05),
                ),
                icon: const Icon(Icons.warning_amber_rounded, size: 18),
                label: Text('PURGE_ALL_HISTORY', style: GoogleFonts.spaceMono(letterSpacing: 2.0)),
                onPressed: _purgeHistory,
              ),
            ),
            const SizedBox(height: 80), // spacer for bottom nav
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 3, 
        onTap: (index) {
           if(index == 0) { Navigator.pop(context); } // Back to palette
        }
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white12)),
            ),
            child: Text(title, style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 12)),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(String mode) {
    bool isSelected = _colorMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => _saveColorMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            border: Border(right: BorderSide(color: Colors.white12, width: mode == 'DEUTER' ? 0 : 1)),
          ),
          child: Center(
            child: Text(
              mode,
              style: GoogleFonts.spaceMono(
                color: isSelected ? Colors.black : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiagnosticRow(String key, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(key, style: GoogleFonts.spaceMono(color: Colors.white54, fontSize: 12)),
        Text(value, style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
