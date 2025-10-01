import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web; // Import dart:ui_web for platformViewRegistry
import 'dart:html'; // Import dart:html for IFrameElement
import 'package:weatherpro/features/radar/presentation/widgets/numerical_forecast_view.dart' show BaseNumericalForecastView; // Import the base class

// 實作 BaseNumericalForecastView 給 Web 平台使用
class NumericalForecastViewImpl extends BaseNumericalForecastView {
  const NumericalForecastViewImpl({super.key, required super.shouldLoad});

  @override
  State<NumericalForecastViewImpl> createState() => _NumericalForecastViewImplState();
}

class _NumericalForecastViewImplState extends State<NumericalForecastViewImpl> {
  static const String _iframeViewType = 'windy-forecast-iframe';
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.shouldLoad && !_isLoaded) {
      _initializeAndLoadIFrame();
    }
  }

  @override
  void didUpdateWidget(covariant NumericalForecastViewImpl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldLoad && !_isLoaded) {
      _initializeAndLoadIFrame();
    }
  }

  void _initializeAndLoadIFrame() {
    // 這是針對 Web 平台使用 HtmlElementView 的解決方案，
    // 如果您在正式上線時只部署到原生平台 (Android/iOS)，請考慮註解掉這部分程式碼
    // 並使用針對原生平台的 WebViewWidget 相關邏輯，以確保 WebView 的原生行為。
    ui_web.platformViewRegistry.registerViewFactory(
      _iframeViewType,
      (int viewId) => IFrameElement()
        ..width = '100%'
        ..height = '100%'
        ..src = 'https://embed.windy.com/embed.html?type=map&location=coordinates&metricRain=default&metricTemp=default&metricWind=default&zoom=5&overlay=wind&product=ecmwf&level=surface&lat=24.972&lon=121.205'
        ..style.border = 'none'
        ..allowFullscreen = true,
    );
    setState(() {
      _isLoaded = true; // For web, assume loaded after iframe registration
    });
  }

  @override
  Widget build(BuildContext context) {
    // 這是針對 Web 平台使用 HtmlElementView 的解決方案，
    // 如果您在正式上線時只部署到原生平台 (Android/iOS)，請考慮註解掉這部分程式碼
    // 並使用針對原生平台的 WebViewWidget 相關邏輯，以確保 WebView 的原生行為。
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: const HtmlElementView(viewType: _iframeViewType),
    );
  }
}
