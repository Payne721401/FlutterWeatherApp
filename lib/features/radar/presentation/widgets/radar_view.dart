import 'dart:typed_data';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../state/radar_state.dart';
import 'playback_controls.dart';
import 'ai_analysis_panel.dart';
import 'radar_legend.dart';

// --- CONSTANTS ---
const double radarImageWidth = 3600.0;
const double radarImageHeight = 3600.0;

/// The main view for the radar, responsible for assembling the different layers
/// and control panels. This widget itself does not listen to granular changes,
/// but passes the state down to its children.
/// The actual dynamic updates are handled by more specific, memoized child widgets
/// (_RadarImageLayer, _LocationPinLayer) using Provider's `Selector` for performance.
class RadarView extends StatelessWidget {
  final RadarState radarState;

  const RadarView({super.key, required this.radarState});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Rainfall forecast message - this is rebuilt on any state change, which is acceptable.
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0),
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
                // By using a LayoutBuilder here, we get the final size of the canvas first.
                child: LayoutBuilder(builder: (context, constraints) {
                  final size = constraints.biggest;
                  if (size.isEmpty) {
                    return const SizedBox.shrink(); // Avoid calculations if size is zero.
                  }

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // Dynamic Layer: Radar image itself.
                      const _RadarImageLayer(),

                      // Dynamic Layer: Location pin. This is now a direct child of Stack.
                      Selector<RadarState, Position?>(
                        selector: (_, state) => state.currentPosition,
                        builder: (context, currentPosition, child) {
                          if (currentPosition == null) {
                            return const SizedBox.shrink();
                          }

                          // Calculations are done here, using the `size` from the parent LayoutBuilder.
                          final radarState = context.read<RadarState>();
                          final pixelPoint = radarState.convertLatLngToPixel(
                            currentPosition.latitude,
                            currentPosition.longitude,
                          );

                          if (pixelPoint != null) {
                            final double relativeX = (pixelPoint.x / radarImageWidth) * size.width;
                            final double relativeY = (pixelPoint.y / radarImageHeight) * size.height;

                            if (relativeX.isFinite && relativeY.isFinite) {
                              // This Positioned widget is now a direct child of the Stack,
                              // so its coordinates will be respected.
                              return Positioned(
                                left: relativeX - 12,
                                top: relativeY - 24,
                                child: const Icon(Icons.location_pin, color: Colors.red, size: 24),
                              );
                            }
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      // Static Layer: Radar legend.
                      const Positioned(
                        top: 5,
                        right: 5,
                        child: RadarLegend(),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),

          // --- Controls and Panels ---
          PlaybackControls(radarState: radarState),

          // --- AI Analysis Section (Commented Out as Requested) ---
          /*
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
                      onPressed: () => radarState.toggleAiAnalysis(true),
                    ),
                  ),
          ),
          */
        ],
      ),
    );
  }
}

/// A private, performance-optimized widget that only listens to changes
/// relevant to displaying the radar image (loading state, image data, and current frame).
class _RadarImageLayer extends StatelessWidget {
  const _RadarImageLayer();

  @override
  Widget build(BuildContext context) {
    final (isLoading, imageBytes, currentFrame) =
        context.select<RadarState, (bool, List<Uint8List?>, int)>(
      (state) => (state.isLoadingRadarImages, state.radarImageBytes, state.currentRadarFrame),
    );

    final currentImageBytes = (imageBytes.isNotEmpty && currentFrame >= 0 && currentFrame < imageBytes.length)
        ? imageBytes[currentFrame]
        : null;

    final screenWidth = MediaQuery.of(context).size.width;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final int cacheWidth = (screenWidth * devicePixelRatio).round().clamp(0, 2048);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (currentImageBytes != null) {
      return Image.memory(
        currentImageBytes,
        key: ValueKey('radar_$currentFrame'),
        cacheWidth: cacheWidth,
        fit: BoxFit.fill,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      );
    }

    return const Center(child: Text("無可用雷達圖片"));
  }
}
