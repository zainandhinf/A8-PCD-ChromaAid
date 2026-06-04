import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../models/hive_color_model.dart';
import '../widgets/custom_bottom_nav.dart';
import '../settings/settings_screen.dart';
import '../../services/ai_service.dart';

class ColorHistoryScreen extends StatefulWidget {
  const ColorHistoryScreen({super.key});

  @override
  State<ColorHistoryScreen> createState() => _ColorHistoryScreenState();
}

class _ColorHistoryScreenState extends State<ColorHistoryScreen> {
  String _selectedFilter = 'ALL';
  final List<String> _filters = ['ALL', 'Warm', 'Cold', 'Neutral', 'Nature'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101214), // Deep tech dark
      appBar: AppBar(
        title: Text('My Palette', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
        backgroundColor: const Color(0xFF101214),
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done_outlined, color: Colors.white54, size: 16),
                  const SizedBox(width: 4),
                  Text('Synced', style: GoogleFonts.spaceMono(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(aiService: AiService()))),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              style: GoogleFonts.spaceMono(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search colors...',
                hintStyle: GoogleFonts.spaceMono(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _filters.map((f) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedFilter = f),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _selectedFilter == f ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _selectedFilter == f ? Colors.white : Colors.white24),
                    ),
                    child: Text(
                      f,
                      style: GoogleFonts.spaceMono(
                        color: _selectedFilter == f ? Colors.black : Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )).toList(),
            ),
          ),
          
          // Grid
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<HiveColorModel>('colorsBox').listenable(),
              builder: (context, Box<HiveColorModel> box, _) {
                if (box.values.isEmpty) {
                  return Center(child: Text("Library Empty", style: GoogleFonts.spaceMono(color: Colors.white54)));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: box.values.length,
                  itemBuilder: (context, index) {
                    final item = box.getAt(index)!;
                    return _buildColorCard(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () {
          Navigator.pop(context); // Go back to Scanner
        },
        child: const Icon(Icons.camera_alt_outlined, color: Colors.black),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 0, 
        onTap: (index) {
          if (index == 2) {
             // Already on palette
          }
        }
      ),
    );
  }

  Widget _buildColorCard(HiveColorModel item) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: Color.fromRGBO(item.r, item.g, item.b, 1.0),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.nama, 
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'HEX: ${item.hex}',
                    style: GoogleFonts.spaceMono(color: Colors.white54, fontSize: 10),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.sesiId.isNotEmpty ? item.sesiId : "Nature",
                        style: GoogleFonts.spaceMono(color: Colors.white70, fontSize: 10),
                      ),
                      Text(
                        DateFormat('MMM dd').format(item.savedAt),
                        style: GoogleFonts.spaceMono(color: Colors.white54, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
