import 'package:flutter/material.dart';

class UvIndexCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const UvIndexCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final num? rawUvIndex = data['uv_index'];
    final int uvIndex = rawUvIndex?.toInt() ?? 0;
    final String uvDescription = data['uv_description'] ?? '未知';
    final String uvAdvice = data['uv_advice'] ?? '無建議';

    Color cardColor = Colors.grey.shade200;
    Color uvColor = Colors.black;

    if (uvIndex >= 0 && uvIndex <= 2) {
      uvColor = Colors.green;
    } else if (uvIndex >= 3 && uvIndex <= 5) {
      uvColor = Colors.yellow.shade700;
    } else if (uvIndex >= 6 && uvIndex <= 7) {
      uvColor = Colors.orange.shade700;
    } else if (uvIndex >= 8 && uvIndex <= 10) {
      uvColor = Colors.red.shade700;
    } else if (uvIndex >= 11) {
      uvColor = Colors.purple.shade700;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '紫外線指數',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: uvColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                uvIndex.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              uvDescription,
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                uvAdvice,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[800]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
