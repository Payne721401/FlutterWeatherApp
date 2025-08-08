import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../services/remote_config_service.dart';

import '../features/weather/presentation/widgets/weather_card.dart';

//================================================================================
// 公開的、給外部使用的 Widget
// ... (The rest of the public widgets are unchanged)
//================================================================================

class SmallNativeAd extends StatelessWidget {
  const SmallNativeAd({super.key});

  @override
  Widget build(BuildContext context) {
    return _BaseNativeAdWidget(
      factoryId: 'adFactorySmall',
      height: 100,
    );
  }
}

class MediumNativeAd extends StatelessWidget {
  const MediumNativeAd({super.key});

  @override
  Widget build(BuildContext context) {
    return _BaseNativeAdWidget(
      factoryId: 'adFactoryMedium',
      height: 320,
    );
  }
}

class FullScreenNativeAd extends StatelessWidget {
  const FullScreenNativeAd({super.key});

  @override
  Widget build(BuildContext context) {
    return _BaseNativeAdWidget(
      factoryId: 'adFactoryFullScreen',
      height: MediaQuery.of(context).size.height,
    );
  }
}


//================================================================================
// 私有的、核心的廣告邏輯 Widget (外部不應該直接呼叫)
//================================================================================

class _BaseNativeAdWidget extends StatefulWidget {
  final String factoryId;
  final double height;

  const _BaseNativeAdWidget({
    required this.factoryId,
    required this.height,
  });

  @override
  State<_BaseNativeAdWidget> createState() => _BaseNativeAdWidgetState();
}

class _BaseNativeAdWidgetState extends State<_BaseNativeAdWidget> {
  NativeAd? _nativeAd;
  bool _nativeAdIsLoaded = false;
  bool _isDisposed = false;
  int _retryAttempt = 0;
  static const int _maxRetries = 3;

  // --- MODIFICATION START ---
  /*
  String _getAdUnitId() {
    if (kIsWeb) {
      throw UnsupportedError("Web platform is not supported for Native Ads");
    } else if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/2247696110';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/3986624511';
    } else {
      throw UnsupportedError("Unsupported platform for AdMob native ad");
    }
  }
  */
  // --- MODIFICATION END ---

  bool get _shouldShowAd => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // --- MODIFICATION START ---
  @override
  void initState() {
    super.initState();
    // Ad loading is now triggered by didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // We load the ad here to safely access the provider context.
    // We also check if the ad is already loaded to prevent reloading on every widget rebuild.
    if (_shouldShowAd && _nativeAd == null) {
      final remoteConfigService = context.read<RemoteConfigService>();
      _loadAd(remoteConfigService);
    }
  }

  void _loadAd(RemoteConfigService remoteConfigService) {
  // --- MODIFICATION END ---
    if (_isDisposed) return;

    // --- MODIFICATION START ---
    final String adUnitId;
    try {
      if (Platform.isAndroid) {
        adUnitId = remoteConfigService.nativeAdUnitIdAndroid;
      } else if (Platform.isIOS) {
        adUnitId = remoteConfigService.nativeAdUnitIdIos;
      } else {
        throw UnsupportedError("Unsupported platform for AdMob native ad");
      }

      if (adUnitId.isEmpty) {
        log('NativeAd adUnitId is empty. Ad not loaded.', name: '_BaseNativeAdWidgetState');
        return;
      }
    } catch (e) {
      log('Error getting ad unit ID: $e', name: '_BaseNativeAdWidgetState');
      return;
    }
    // --- MODIFICATION END ---

    try {
      _nativeAd = NativeAd(
        // --- MODIFICATION START ---
        adUnitId: adUnitId, // Use the dynamically fetched adUnitId
        // --- MODIFICATION END ---
        factoryId: widget.factoryId,
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            if (!_isDisposed) {
              setState(() {
                _nativeAdIsLoaded = true;
                _retryAttempt = 0;
              });
            }
          },
          onAdFailedToLoad: (ad, err) {
            log('NativeAd failed to load (factory: ${widget.factoryId}): ${err.message}');
            ad.dispose();
            if (!_isDisposed) {
              setState(() {
                _nativeAd = null;
                _nativeAdIsLoaded = false;
              });
              if (_retryAttempt < _maxRetries) {
                _retryAttempt++;
                log('Retrying NativeAd load, attempt $_retryAttempt...');
                // --- MODIFICATION START ---
                // Pass the remoteConfigService to the retry call.
                Future.delayed(Duration(seconds: _retryAttempt * 2), () => _loadAd(remoteConfigService));
                // --- MODIFICATION END ---
              } else {
                log('Max NativeAd retries reached for factory: ${widget.factoryId}.');
                _retryAttempt = 0;
              }
            }
          },
          onAdOpened: (Ad ad) => log('NativeAd opened.'),
          onAdClosed: (Ad ad) => log('NativeAd closed.'),
          onAdImpression: (Ad ad) => log('NativeAd impression.'),
          onPaidEvent: (Ad ad, double valueMicros, PrecisionType precision, String currencyCode) =>
              log('NativeAd paidEvent: $valueMicros $precision $currencyCode'),
        ),
      );
      _nativeAd!.load();
    } catch (e) {
      log('Error creating native ad: $e');
      // Error handling for native ad creation itself remains unchanged.
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The build method remains entirely unchanged.
    if (!_shouldShowAd) {
      return const SizedBox.shrink();
    }

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16.0),
    );

    if (!_nativeAdIsLoaded || _nativeAd == null) {
      return WeatherCard(
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: Center(
            child: Text('廣告載入中...', style: TextStyle(color: Colors.grey[500])),
          ),
        ),
      );
    }

    return WeatherCard(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: double.infinity,
        height: widget.height,
        child: AdWidget(ad: _nativeAd!),
      ),
    );
  }
}
