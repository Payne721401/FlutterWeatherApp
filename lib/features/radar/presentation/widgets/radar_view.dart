// import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../state/radar_state.dart'; // Need state for data and callbacks
import 'playback_controls.dart'; // Import playback controls
import 'ai_analysis_panel.dart'; // Import AI panel
import 'radar_legend.dart'; // 防止溢出

class RadarView extends StatelessWidget {
  final RadarState radarState;

  const RadarView({super.key, required this.radarState});

  @override
  Widget build(BuildContext context) {
    final currentImageBytes = (radarState.radarImageBytes.isNotEmpty &&
                               radarState.currentRadarFrame >= 0 &&
                               radarState.currentRadarFrame < radarState.radarImageBytes.length)
                              ? radarState.radarImageBytes[radarState.currentRadarFrame]
                              : null;

    return SingleChildScrollView( // <-- HERE: Wrap the entire Column in SingleChildScrollView
      child: Column(
        children: [
          // --- START: Added Rain Alert Section ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0), // Adjust padding
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50, // Light blue background
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.blue.shade100)
              ),
              child: Row(
                children: [
                  Icon(Icons.cloudy_snowing, color: Colors.blue.shade700, size: 20), // Example icon
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      radarState.rainAlertMessage, // Use placeholder from state
                      style: TextStyle(color: Colors.blue.shade900, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // --- END: Added Rain Alert Section ---

          // Radar Image AspectRatio (flexible height, now not Expanded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0), // Adjusted padding
            child: AspectRatio(
              aspectRatio: 1.0, // Keeping 1:1 aspect ratio for the image container
              child: Container(
                clipBehavior: Clip.hardEdge, // Ensure children (like Positioned) don't overflow
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  color: Colors.grey[200], // Background for loading/error
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (radarState.isLoadingRadarImages)
                      const Center(child: CircularProgressIndicator()) // Centered indicator
                    else if (currentImageBytes != null)
                      // InteractiveViewer for zoom/pan
                      InteractiveViewer(
                        transformationController: radarState.transformationController, // Use controller from state
                        minScale: 0.5, // Example minimum scale
                        maxScale: 4.0, // Example maximum scale
                        child: Stack(
                          children: [
                            // The Radar Image itself
                            Image.memory(
                              currentImageBytes,
                              fit: BoxFit.contain,
                              width: double.infinity, // Ensure Stack fills InteractiveViewer space
                              height: double.infinity,
                              gaplessPlayback: true,
                              filterQuality: FilterQuality.medium,
                            ),
                            // User Location Marker positioned within the image coordinate system
                            if (radarState.currentPosition != null)
                              Builder( // Use builder to get correct context size for positioning
                                builder: (context) {
                                  final renderBox = context.findRenderObject() as RenderBox?;
                                  final size = renderBox?.size ?? const Size(double.infinity, double.infinity);
                                  final pixelPoint = radarState.convertLatLngToPixel(
                                    radarState.currentPosition!.latitude,
                                    radarState.currentPosition!.longitude,
                                  );
                                  // Adjust pixel calculation if convertLatLngToPixel size differs from widget size
                                  // This assumes convertLatLngToPixel uses the fixed radarImageWidth/Height constants
                                  if (pixelPoint != null && size.width > 0 && size.height > 0) {
                                    // Calculate position relative to the widget size
                                    final double relativeX = (pixelPoint.x / radarImageWidth) * size.width;
                                    final double relativeY = (pixelPoint.y / radarImageHeight) * size.height;
                                    // Ensure marker stays within bounds
                                    if (relativeX >= 0 && relativeX <= size.width && relativeY >= 0 && relativeY <= size.height){
                                        return Positioned(
                                          left: relativeX - 12, // Offset to center the pin icon
                                          top: relativeY - 24, // Offset to place pin tip at the location
                                          child: Icon(Icons.location_pin, color: Colors.red, size: 24),
                                        );
                                    }
                                  }
                                  return const SizedBox.shrink(); // Return empty if out of bounds or no size
                                }
                              ),
                          ]
                        ),
                      )
                    else
                      const Center(child: Text("無可用雷達圖片")),

                    // Legend positioned over everything (except maybe custom controls)
                    Positioned(
                      top: 5,
                      right: 5,
                      child: RadarLegend(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Playback Controls
          PlaybackControls(radarState: radarState),

          // --- START: Conditional AI Analysis Section ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: radarState.showAiAnalysis
                ? AiAnalysisPanel(onClose: () => radarState.toggleAiAnalysis(false)) // Pass close callback
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.auto_awesome_outlined),
                      label: const Text("AI 圖片分析"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        // You might want to define primary/onPrimary explicitly for themes
                        // backgroundColor: Theme.of(context).colorScheme.secondary, 
                        // foregroundColor: Theme.of(context).colorScheme.onSecondary,
                      ),
                      onPressed: () {
                        radarState.toggleAiAnalysis(true);
                        // Note: Actual analysis logic should be triggered here or within AiAnalysisPanel
                      },
                    ),
                  ),
          ),
          // --- END: Conditional AI Analysis Section ---
        ],
      ),
    );
  }
}
