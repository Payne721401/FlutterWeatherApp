import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../data/models/map_layer_type.dart';

/// A custom segmented control widget that mimics the modern iOS style,
/// featuring a sliding "pill" indicator and smooth animations.
/// This was rebuilt to provide full visual control where the native
/// CupertinoSegmentedControl falls short.
class LayerToggleButtons extends StatelessWidget {
  final MapLayerType selectedView;
  final ValueChanged<MapLayerType> onSelected;

  const LayerToggleButtons({
    super.key,
    required this.selectedView,
    required this.onSelected,
  });

  String _getLabelForType(MapLayerType type) {
    switch (type) {
      case MapLayerType.radarEcho:
        return '雷達回波';
      case MapLayerType.qpf:
        return '降雨預報';
      case MapLayerType.numericalForecast:
        return '風場動畫';
      case MapLayerType.ensemble:
        return '颱風路徑';
    }
  }

  @override
  Widget build(BuildContext context) {
    const double height = 36.0;
    const double horizontalPadding = 16.0;
    final int itemCount = MapLayerType.values.length;
    final int selectedIndex = selectedView.index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: horizontalPadding),
      // --- MODIFICATION START ---
      // Use LayoutBuilder to get the precise available width for calculation,
      // which prevents floating point errors and overflow issues.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double itemWidth = constraints.maxWidth / itemCount;

          return Center(
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey5,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    left: itemWidth * selectedIndex,
                    child: Container(
                      // The pill's width is calculated based on the precise itemWidth.
                      width: itemWidth,
                      height: height - 4,
                      margin: const EdgeInsets.all(2.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: MapLayerType.values.map((type) {
                      final index = type.index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => onSelected(type),
                          behavior: HitTestBehavior.opaque,
                          child: Center(
                            child: Text(
                              _getLabelForType(type),
                              style: TextStyle(
                                color: selectedIndex == index
                                    ? Colors.black
                                    : Colors.black87,
                                fontWeight: selectedIndex == index
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      // --- MODIFICATION END ---
    );
  }
}
