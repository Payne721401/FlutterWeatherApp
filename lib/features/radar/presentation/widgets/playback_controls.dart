import 'package:flutter/material.dart';
import '../state/radar_state.dart';

class PlaybackControls extends StatelessWidget {
  final RadarState radarState;

  const PlaybackControls({super.key, required this.radarState});

  @override
  Widget build(BuildContext context) {
    final int validFrameCount = radarState.radarImageBytes.where((bytes) => bytes != null).length;
    final bool canPlay = validFrameCount > 1;
    final double sliderMax = radarState.radarImageBytes.isNotEmpty ? radarState.radarImageBytes.length - 1.0 : 0.0;
    final int lastValidFrameIndex = radarState.radarImageBytes.lastIndexWhere((bytes) => bytes != null);
    final int firstValidFrameIndex = radarState.radarImageBytes.indexWhere((bytes) => bytes != null); // Find first valid index for label

    return Card(
      margin: const EdgeInsets.only(left: 15, right: 15, bottom: 15, top: 5),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildControlButton(context, Icons.skip_previous, canPlay ? () => radarState.stepFrame(-1) : null),
                _buildControlButton(
                  context,
                  radarState.isPlaying ? Icons.pause : Icons.play_arrow,
                  canPlay ? (radarState.isPlaying ? radarState.stopAnimation : radarState.startAnimation) : null,
                  isLarge: true,
                  color: canPlay ? Colors.blueAccent : Colors.grey
                ),
                _buildControlButton(context, Icons.skip_next, canPlay ? () => radarState.stepFrame(1) : null),
              ],
            ),
            const SizedBox(height: 10),
            Slider(
              value: radarState.sliderValue,
              min: 0,
              max: sliderMax,
              divisions: radarState.radarImageBytes.length > 1 ? radarState.radarImageBytes.length - 1 : null,
              label: radarState.getFrameTimestampLabel(radarState.currentRadarFrame),
              onChanged: canPlay ? radarState.onSliderChanged : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    firstValidFrameIndex != -1 ? radarState.getFrameTimestampLabel(firstValidFrameIndex) : "---",
                    style: TextStyle(fontSize: 10, color: firstValidFrameIndex != -1 ? Colors.black54 : Colors.grey)
                  ),
                  const Text("現在", style: TextStyle(fontSize: 10, color: Colors.black)), // Label for the last frame
                  Text(
                    lastValidFrameIndex != -1 ? radarState.getFrameTimestampLabel(lastValidFrameIndex) : "---",
                     style: TextStyle(fontSize: 10, color: lastValidFrameIndex != -1 ? Colors.black54 : Colors.grey )
                  ),
                ],
              ),
            )
          ],
        ),
      )
    );
  }

  Widget _buildControlButton(BuildContext context, IconData icon, VoidCallback? onPressed, {bool isLarge = false, Color? color}) {
    final double size = isLarge ? 48 : 36;
    final bool enabled = onPressed != null;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isLarge
               ? (enabled ? color ?? Colors.blueAccent : Colors.grey[400])
               : (enabled ? Colors.grey[200] : Colors.grey[300]),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon),
        iconSize: isLarge ? 30 : 20,
        color: isLarge
               ? Colors.white
               : (enabled ? Colors.black54 : Colors.grey[500]),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: enabled ? null : "無足夠圖片",
      ),
    );
  }
}
