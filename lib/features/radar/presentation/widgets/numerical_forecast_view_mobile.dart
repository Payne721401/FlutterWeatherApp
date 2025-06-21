import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:myapp/features/radar/presentation/widgets/numerical_forecast_view.dart' show BaseNumericalForecastView; // Import the base class

// 實作 BaseNumericalForecastView 給移動平台使用
class NumericalForecastViewImpl extends BaseNumericalForecastView {
  const NumericalForecastViewImpl({super.key, required super.shouldLoad});

  @override
  State<NumericalForecastViewImpl> createState() => _NumericalForecastViewImplState();
}

class _NumericalForecastViewImplState extends State<NumericalForecastViewImpl> {
  WebViewController? _controller;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.shouldLoad && !_isLoaded) {
      _initializeAndLoadWebView();
    }
  }

  @override
  void didUpdateWidget(covariant NumericalForecastViewImpl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldLoad && !_isLoaded) {
      _initializeAndLoadWebView();
    }
  }

  void _initializeAndLoadWebView() {
    final WebViewController controller = WebViewController();
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);

    _controller = controller
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            setState(() {
              _isLoaded = true;
            });
          },
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://embed.windy.com/')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://embed.windy.com/embed.html?type=map&location=coordinates&metricRain=default&metricTemp=default&metricWind=default&zoom=5&overlay=wind&product=ecmwf&level=surface&lat=24.972&lon=121.205'));
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: WebViewWidget(controller: _controller!),
    );
  }
}
