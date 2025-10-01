import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/map_layer_type.dart';
import '../state/radar_state.dart';
import '../widgets/layer_toggle_buttons.dart';
import '../widgets/radar_view.dart';
import '../widgets/qpf_view.dart';
import '../widgets/numerical_forecast_view.dart';
import '../widgets/ensemble_view.dart';

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  @override
  Widget build(BuildContext context) {
    final radarState = context.watch<RadarState>();

    final bool isRefreshingActiveView =
        (radarState.selectedView == MapLayerType.radarEcho &&
            radarState.isLoadingRadarImages) ||
        (radarState.selectedView == MapLayerType.qpf &&
            radarState.isLoadingQpfImages) ||
        (radarState.selectedView == MapLayerType.ensemble &&
            radarState.isLoadingEnsembleImage);

    return Scaffold(
      appBar: CupertinoNavigationBar(
        automaticallyImplyLeading: false,
        middle: const Text('降雨雷達', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: const EdgeInsets.all(4.0),
              onPressed: null, // This button is invisible and not interactive
              child: Opacity(opacity: 0, child: Icon(CupertinoIcons.refresh)),
            ),
            // CupertinoButton(
            //   padding: const EdgeInsets.all(4.0),
            //   onPressed: null, // This button is invisible and not interactive
            //   child: Opacity(opacity: 0, child: Icon(CupertinoIcons.location_fill)),
            // ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (radarState.selectedView !=
                MapLayerType.numericalForecast)
              CupertinoButton(
                padding: const EdgeInsets.all(4.0),
                onPressed: isRefreshingActiveView
                    ? null
                    : () {
                        if (radarState.selectedView ==
                            MapLayerType.radarEcho) {
                          radarState.refreshRadarImages();
                        } else if (radarState.selectedView == MapLayerType.qpf) {
                          radarState.refreshQpfImages();
                        } else if (radarState.selectedView == MapLayerType.ensemble) {
                          radarState.refreshEnsembleImage();
                        }
                      },
                child: Icon(
                  CupertinoIcons.refresh,
                  color: isRefreshingActiveView
                      ? CupertinoColors.placeholderText
                      : Colors.black,
                ),
              ),
            // CupertinoButton(
            //   padding: const EdgeInsets.all(4.0),
            //   onPressed: radarState.isFetchingLocation
            //       ? null
            //       : radarState.determinePosition,
            //   child: Icon(
            //     CupertinoIcons.location_fill,
            //     color: radarState.isFetchingLocation
            //         ? CupertinoColors.placeholderText
            //         : CupertinoColors.black,
            //   ),
            // ),
          ],
        ),
        backgroundColor: CupertinoColors.white,
        border: const Border(
          bottom: BorderSide(
            color: CupertinoColors.systemGrey4,
            width: 0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          LayerToggleButtons(
            selectedView: radarState.selectedView,
            onSelected: radarState.setSelectedView,
          ),
          if (radarState.selectedView == MapLayerType.numericalForecast)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                '數值預報誤差會隨時間逐漸擴大，請謹慎參考',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          if (radarState.selectedView !=
                  MapLayerType.numericalForecast &&
              (radarState.isLoadingRadarImages ||
                  radarState.isLoadingQpfImages ||
                  radarState.isLoadingEnsembleImage))
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
                  case MapLayerType.ensemble:
                    return EnsembleView(radarState: radarState);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
