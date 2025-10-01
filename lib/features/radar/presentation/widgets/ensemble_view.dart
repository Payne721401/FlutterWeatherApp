import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../state/radar_state.dart';

class EnsembleView extends StatelessWidget {
  final RadarState radarState;

  const EnsembleView({super.key, required this.radarState});

  @override
  Widget build(BuildContext context) {
    if (radarState.isLoadingEnsembleImage) {
      return const Center(child: CupertinoActivityIndicator());
    }

    final imageData = radarState.ensembleImageData;
    if (imageData != null) {
      return Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              maxScale: 5.0, // Allow users to zoom in up to 5x
              child: Center(
                child: Image.memory(
                  imageData,
                  fit: BoxFit.contain, // Ensure the whole image is visible
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text('無法顯示颱風路徑圖片。'),
                    );
                  },
                ),
              ),
            ),
          ),
          _buildInfoPanel(context),
        ],
      );
    }

    // Default state if there's no image data and it's not loading
    return const Center(
      child: Text('目前無颱風路徑預報。'),
    );
  }

  Widget _buildInfoPanel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 12.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              CupertinoIcons.info_circle_fill,
              color: CupertinoColors.secondaryLabel,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '此颱風系集預報圖來源為 Google DeepMind FNV3，每日更新兩次（03:00、15:00）。',
                    style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '模型結果僅供參考，非正式氣象預報，且預報誤差會隨時間增加，請以中央氣象署或官方單位發布之資訊為準。',
                    style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
