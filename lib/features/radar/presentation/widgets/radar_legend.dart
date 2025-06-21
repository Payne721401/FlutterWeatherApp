import 'package:flutter/material.dart';

class RadarLegend extends StatelessWidget {
  const RadarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      color: Colors.white.withOpacity(0.85),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendItem(Colors.lightGreen, '小雨'),
            _buildLegendItem(Colors.yellow, '中雨'),
            _buildLegendItem(Colors.orange, '大雨'),
            _buildLegendItem(Colors.red, '暴雨'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, color: color, margin: const EdgeInsets.only(right: 6)),
          Text(text, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}
