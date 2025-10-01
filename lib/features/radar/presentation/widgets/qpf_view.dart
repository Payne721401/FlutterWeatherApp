import 'package:flutter/material.dart';
import 'dart:developer';
import '../state/radar_state.dart'; // Need state for data and page controller

class QpfView extends StatelessWidget {
  final RadarState radarState;

  const QpfView({super.key, required this.radarState});

  @override
  Widget build(BuildContext context) {
    return PageView.builder( // PageView handles horizontal scrolling
      controller: radarState.qpfPageController, // Use controller from state
      itemCount: radarState.qpfImageUrls.length,
      onPageChanged: (index) {
        radarState.setQpfPage(index);
      },
      itemBuilder: (context, index) {
        return SingleChildScrollView( // <-- HERE: Wrap each page's content in SingleChildScrollView
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0), // Changed horizontal padding to 16.0
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  radarState.getQpfLabel(index), // Get label from state
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 10),
                // Removed Expanded here, image will take natural size or constrained by parent
                Image.network(
                  radarState.qpfImageUrls[index], // Get URL from state
                  fit: BoxFit.contain, // Use BoxFit.contain to respect aspect ratio
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                    ));
                  },
                  errorBuilder: (context, error, stackTrace) {
                    log("Error loading QPF image ${radarState.qpfImageUrls[index]}: $error");
                    return const Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 40),
                        SizedBox(height: 8),
                        Text('無法載入預報圖', style: TextStyle(color: Colors.red)),
                      ],
                    ));
                  },
                ),
                const SizedBox(height: 10),
                // Page indicator - Use the state variable for color
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(radarState.qpfImageUrls.length, (i) =>
                    Container(
                      width: 8, height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // Use the state variable directly for color
                        color: i == radarState.currentQpfPage ? Colors.blueAccent : Colors.grey[400],
                      ),
                    )
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
