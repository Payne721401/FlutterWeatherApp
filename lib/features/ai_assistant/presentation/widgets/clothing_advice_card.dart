import 'package:flutter/material.dart';

class ClothingAdviceCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const ClothingAdviceCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final String adviceText = data['advice_text'] ?? '無穿搭建議';
    final List<dynamic> items = data['items'] ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '穿搭建議',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              adviceText,
              style: TextStyle(fontSize: 16, color: Colors.grey[800]),
            ),
            const SizedBox(height: 10),
            if (items.isNotEmpty)
              Wrap(
                spacing: 8.0, // gap between adjacent chips
                runSpacing: 4.0, // gap between lines
                children: items.map((item) => Chip(
                  label: Text(item, style: const TextStyle(color: Colors.white)),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
