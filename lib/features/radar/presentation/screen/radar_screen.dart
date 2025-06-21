import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:webview_flutter/webview_flutter.dart'; // Import webview_flutter

import '../../data/models/map_layer_type.dart';
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
  // Removed WebViewController declaration from here

  @override
  void initState() {
    super.initState();
    // Removed WebViewController initialization from here
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RadarState(),
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
                  onPressed: radarState.isFetchingLocation
                        ? null
                        : radarState.centerOnUserLocation,
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: Column( // Keep Column, but ensure its flexible child is Expanded
              children: [ // Removed SingleChildScrollView from here, it should be in individual views
                LayerToggleButtons(
                  selectedView: radarState.selectedView,
                  onSelected: radarState.setSelectedView,
                ),

                // Warning message for Numerical Forecast
                if (radarState.selectedView == MapLayerType.numericalForecast)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      '數值預報誤差會隨時間逐漸擴大，請謹慎參考',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Loading indicator for either view
                if (radarState.selectedView != MapLayerType.numericalForecast && (radarState.isLoadingRadarImages || radarState.isLoadingQpfImages))
                  const LinearProgressIndicator(),

                // Location Info Section / Rain Alert
                if (radarState.isFetchingLocation)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(strokeWidth: 2), SizedBox(width: 10), Text("正在取得位置...")])
                  )
                else if (radarState.locationError != null && radarState.selectedView != MapLayerType.numericalForecast)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(radarState.locationError!, style: const TextStyle(color: Colors.red)),
                  ),

                Expanded( // <-- HERE: Wrap the Builder in Expanded
                  child: Builder(
                    builder: (context) {
                      if (radarState.selectedView == MapLayerType.radarEcho) {
                        return RadarView(radarState: radarState);
                      } else if (radarState.selectedView == MapLayerType.qpf) {
                        return QpfView(radarState: radarState);
                      } else {
                        // Pass a flag to NumericalForecastView instead of the controller
                        return NumericalForecastView(shouldLoad: radarState.selectedView == MapLayerType.numericalForecast);
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
