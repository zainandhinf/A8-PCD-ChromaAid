import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/hive_color_model.dart';
import '../scanner/scanner_screen.dart';
import 'scan_detail_screen.dart';

class ColorHistoryScreen extends StatefulWidget {
  const ColorHistoryScreen({super.key});

  @override
  State<ColorHistoryScreen> createState() => _ColorHistoryScreenState();
}

class _ColorHistoryScreenState extends State<ColorHistoryScreen> {
  String _selectedFilter = 'ALL';
  final List<String> _filters = ['ALL', 'WARM', 'COOL', 'NEUTRAL'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('My Palette', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          // Indicator for Sync will be added here in Sprint 4
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.white),
            onPressed: () {
              // Sync logic
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: ValueListenableBuilder<Box<HiveColorModel>>(
              valueListenable: Hive.box<HiveColorModel>('colorsBox').listenable(),
              builder: (context, box, _) {
                if (box.values.isEmpty) {
                  return const Center(
                    child: Text('Belum ada warna tersimpan',
                        style: TextStyle(color: Colors.white54)),
                  );
                }

                // Apply Filter
                final filteredColors = box.values.where((color) {
                  if (_selectedFilter == 'ALL') return true;
                  return color.tags.contains(_selectedFilter);
                }).toList();

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: filteredColors.length,
                  itemBuilder: (context, index) {
                    final colorData = filteredColors[index];
                    final color = Color.fromRGBO(
                        colorData.r, colorData.g, colorData.b, 1.0);

                    return GestureDetector(
                      onTap: () {
                        // Nanti diarahkan ke detail
                      },
                      onLongPress: () => _showDeleteDialog(colorData),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  colorData.hex,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScannerScreen()),
          );
        },
        backgroundColor: Colors.white,
        child: const Icon(Icons.camera_alt, color: Colors.black),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return FilterChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedFilter = filter;
              });
            },
            selectedColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
            ),
            backgroundColor: const Color(0xFF2C2C2C),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(HiveColorModel color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Hapus Warna', style: TextStyle(color: Colors.white)),
        content: Text('Anda yakin ingin menghapus warna ${color.hex}?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              color.delete();
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
