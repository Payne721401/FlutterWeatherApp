import 'package:flutter/material.dart';
import '../../data/models/map_layer_type.dart'; // Corrected path

class LayerToggleButtons extends StatelessWidget {
  final MapLayerType selectedView;
  final ValueChanged<MapLayerType> onSelected;

  const LayerToggleButtons({
    super.key,
    required this.selectedView,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: ToggleButtons(
          isSelected: [
            selectedView == MapLayerType.radarEcho,
            selectedView == MapLayerType.qpf,
            selectedView == MapLayerType.numericalForecast,
          ],
          onPressed: (int index) {
            onSelected(MapLayerType.values[index]);
          },
          borderRadius: BorderRadius.circular(20.0),
          selectedBorderColor: Theme.of(context).primaryColor,
          selectedColor: Colors.white,
          fillColor: Theme.of(context).primaryColor,
          color: Colors.black54,
          constraints: BoxConstraints(minWidth: (MediaQuery.of(context).size.width - 50) / 3, minHeight: 40.0),
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('雷達回波'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('定量降水預報'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('數值預報'),
            ),
          ],
        ),
      ),
    );
  }
}
