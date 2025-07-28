import 'package:flutter/material.dart';

import '../state/radar_state.dart';
import 'playback_controls.dart';
import 'ai_analysis_panel.dart';
import 'radar_legend.dart';

const double radarImageWidth = 3600.0;
const double radarImageHeight = 3600.0;

class RadarView extends StatelessWidget {
  final RadarState radarState;

  const RadarView({super.key, required this.radarState});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final int cacheWidth = (screenWidth * devicePixelRatio).round().clamp(0, 2048);

    final currentImageBytes = (radarState.radarImageBytes.isNotEmpty &&
                               radarState.currentRadarFrame >= 0 &&
                               radarState.currentRadarFrame < radarState.radarImageBytes.length)
                              ? radarState.radarImageBytes[radarState.currentRadarFrame]
                              : null;

    return SingleChildScrollView(
      child: Column(
        children: [
          // MOVED: The rainfall forecast message is now part of RadarView
          // so it only shows on the "Radar Echo" tab.
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0), // Adjust padding as needed
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloudy_snowing, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      radarState.rainfallForecastMessage,
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Radar Image Display ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  color: Colors.grey.shade200,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (radarState.isLoadingRadarImages)
                      const Center(child: CircularProgressIndicator())
                    else if (currentImageBytes != null)
                      Image.memory(
                        currentImageBytes,
                        key: ValueKey('radar_${radarState.currentRadarFrame}'),
                        cacheWidth: cacheWidth,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        filterQuality: FilterQuality.medium,
                      )
                    else
                      const Center(child: Text("無可用雷達圖片")),

                    // --- Location Pin ---
                    if (radarState.currentPosition != null)
                      Builder(
                        builder: (context) {
                          final renderBox = context.findRenderObject() as RenderBox?;
                          if (renderBox == null || !renderBox.hasSize || renderBox.size.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          final size = renderBox.size;

                          final pixelPoint = radarState.convertLatLngToPixel(
                            radarState.currentPosition!.latitude,
                            radarState.currentPosition!.longitude,
                          );

                          if (pixelPoint != null) {
                            final double relativeX = (pixelPoint.x / radarImageWidth) * size.width;
                            final double relativeY = (pixelPoint.y / radarImageHeight) * size.height;
                            
                            if (relativeX.isFinite && relativeY.isFinite) {
                              return Positioned(
                                left: relativeX - 12,
                                top: relativeY - 24,
                                child: Icon(Icons.location_pin, color: Colors.red, size: 24),
                              );
                            }
                          }
                          return const SizedBox.shrink();
                        }
                      ),

                    // --- Legend ---
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

          // --- AI Analysis Section ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: radarState.showAiAnalysis
                ? AiAnalysisPanel(onClose: () => radarState.toggleAiAnalysis(false))
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.auto_awesome_outlined),
                      label: const Text("AI 圖片分析"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                      ),
                      onPressed: () {
                        radarState.toggleAiAnalysis(true);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
