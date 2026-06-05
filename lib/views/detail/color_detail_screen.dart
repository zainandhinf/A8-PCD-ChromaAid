import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../services/style_recommendation.dart';
import '../../services/skin_utils.dart';

class ColorDetailScreen extends StatefulWidget {
  final int r;
  final int g;
  final int b;
  final String hexCode;
  final String sesiId;
  final String savedAt;
  final String initialCatatan;

  const ColorDetailScreen({
    super.key,
    required this.r,
    required this.g,
    required this.b,
    required this.hexCode,
    required this.sesiId,
    required this.savedAt,
    this.initialCatatan = '',
  });

  @override
  State<ColorDetailScreen> createState() => _ColorDetailScreenState();
}

class _ColorDetailScreenState extends State<ColorDetailScreen> {
  String _activeTab = 'auto'; // 'auto', 'skin', 'pakaian'
  late TextEditingController _catatanController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _catatanController = TextEditingController(text: widget.initialCatatan);
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  Widget _buildTabButton(String label, String key) {
    final isActive = _activeTab == key;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = key;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white24 : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isActive ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white60,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(RecommendedColor rec) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: rec.color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            rec.label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Color.fromRGBO(widget.r, widget.g, widget.b, 1);
    final isSkinTone = SkinUtils.isSkinTone(widget.r, widget.g, widget.b);

    List<RecommendedColor> recommendations = [];
    if (_activeTab == 'auto') {
      recommendations = StyleRecommendation.getAutoRecommend(widget.r, widget.g, widget.b);
    } else if (_activeTab == 'skin') {
      recommendations = StyleRecommendation.getSkinRecommend(widget.r, widget.g, widget.b);
    } else if (_activeTab == 'pakaian') {
      recommendations = StyleRecommendation.getClothingRecommend(widget.r, widget.g, widget.b);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: background warna penuh
            Container(
              height: 160,
              color: bgColor,
              child: Center(
                child: Text(
                  '#${widget.hexCode.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kartu info hex/rgb
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text("HEX", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('#${widget.hexCode.toUpperCase()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text("RGB", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('${widget.r}, ${widget.g}, ${widget.b}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text("SKIN TONE?", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(isSkinTone ? 'Yes' : 'No', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Kartu detail sesi/waktu/catatan
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Sesi: ${widget.sesiId}", style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text("Waktu: ${widget.savedAt}", style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Catatan:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: Icon(_isEditing ? Icons.check : Icons.edit, color: Colors.white54, size: 20),
                              onPressed: () {
                                if (_isEditing) {
                                  HapticFeedback.lightImpact();
                                }
                                setState(() => _isEditing = !_isEditing);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          enabled: _isEditing,
                          controller: _catatanController,
                          style: TextStyle(color: _isEditing ? Colors.white : Colors.white70),
                          decoration: InputDecoration(
                            hintText: "Tambahkan catatan...",
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: _isEditing ? Colors.black45 : Colors.black26,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section "Warna ini adalah..."
                  const Text(
                    "Warna ini adalah...",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Tab buttons
                  Row(
                    children: [
                      _buildTabButton('🤖 Auto Detect', 'auto'),
                      _buildTabButton('🧴 Warna Kulit', 'skin'),
                      _buildTabButton('👕 Pakaian', 'pakaian'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Render swatch rekomendasi dalam horizontal scroll
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: recommendations.map((rec) => _buildRecommendationCard(rec)).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
