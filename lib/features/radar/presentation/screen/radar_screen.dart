import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/map_layer_type.dart';
import '../../data/services/radar_forecast_service.dart';
import '../state/radar_state.dart';
import '../widgets/layer_toggle_buttons.dart';
import '../widgets/radar_view.dart';
import '../widgets/qpf_view.dart';
import '../widgets/numerical_forecast_view.dart';

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {

  @override
  Widget build(BuildContext context) {
    final radarForecastService = Provider.of<RadarForecastService>(context, listen: false);

    return ChangeNotifierProvider(
      create: (_) => RadarState(forecastService: radarForecastService),
      child: Consumer<RadarState>(
        builder: (context, radarState, child) {
          final bool isRefreshingActiveView =
              (radarState.selectedView == MapLayerType.radarEcho && radarState.isLoadingRadarImages) ||
              (radarState.selectedView == MapLayerType.qpf && radarState.isLoadingQpfImages);

          return Scaffold(
            appBar: AppBar(
              title: const Text('降雨雷達', style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 1,
              automaticallyImplyLeading: false,
              actions: [
                if (radarState.selectedView != MapLayerType.numericalForecast)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip:
                        radarState.selectedView == MapLayerType.radarEcho
                            ? '重新載入雷達圖資'
                            : '重新載入定量降水預報',
                    onPressed: isRefreshingActiveView
                        ? null
                        : () {
                            if (radarState.selectedView == MapLayerType.radarEcho) {
                              radarState.refreshRadarImages();
                            } else {
                              radarState.refreshQpfImages();
                            }
                          },
                  ),
                IconButton(
                  icon: const Icon(Icons.my_location),
                  tooltip: '我的位置',
                  onPressed: radarState.isFetchingLocation ? null : radarState.determinePosition,
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: Column(
              children: [
                LayerToggleButtons(
                  selectedView: radarState.selectedView,
                  onSelected: radarState.setSelectedView,
                ),

                // RESTORED: The warning message for the Numerical Forecast view.
                if (radarState.selectedView == MapLayerType.numericalForecast)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      '數值預報誤差會隨時間逐漸擴大，請謹慎參考',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // REMOVED: The rainfall forecast message is no longer here.
                // It will be moved to radar_view.dart.

                if (radarState.selectedView != MapLayerType.numericalForecast && (radarState.isLoadingRadarImages || radarState.isLoadingQpfImages))
                  const LinearProgressIndicator(),

                Expanded(
                  child: Builder(
                    builder: (context) {
                      switch (radarState.selectedView) {
                        case MapLayerType.radarEcho:
                          return RadarView(radarState: radarState);
                        case MapLayerType.qpf:
                          return QpfView(radarState: radarState);
                        case MapLayerType.numericalForecast:
                          return NumericalForecastView(shouldLoad: true);
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
