import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../services/remote_config_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _bannerAdIsLoaded = false;

  bool _isDisposed = false;
  int _retryAttempt = 0;
  static const int _maxRetries = 3;

  // --- MODIFICATION START ---
  /*
  String _getAdUnitId() {
    if (kIsWeb) {
      throw UnsupportedError("Web platform is not fully supported for AdMob");
    } else if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/9214589741';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2435281174';
    } else {
      throw UnsupportedError("Unsupported platform for AdMob banner ad");
    }
  }
  */
  // --- MODIFICATION END ---

  bool get _shouldShowAd {
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }

  // --- MODIFICATION START ---
  @override
  void initState() {
    super.initState();
    // Ad loading is now triggered by didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shouldShowAd && _bannerAd == null) {
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
        adUnitId = remoteConfigService.bannerAdUnitIdAndroid;
      } else if (Platform.isIOS) {
        adUnitId = remoteConfigService.bannerAdUnitIdIos;
      } else {
        throw UnsupportedError("Unsupported platform for AdMob banner ad");
      }

      if (adUnitId.isEmpty) {
        log('BannerAd adUnitId is empty. Ad not loaded.', name: '_BannerAdWidgetState');
        return;
      }
    } catch (e) {
      log('Error getting ad unit ID: $e', name: '_BannerAdWidgetState');
      return;
    }
    // --- MODIFICATION END ---

    try {
      _bannerAd = BannerAd(
        adUnitId: adUnitId, // Use the dynamically fetched adUnitId
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!_isDisposed) {
              setState(() {
                _bannerAdIsLoaded = true;
                _retryAttempt = 0;
              });
            }
          },
          onAdFailedToLoad: (ad, err) {
            log('BannerAd failed to load: ${err.message}');
            ad.dispose();
            if (!_isDisposed) {
              setState(() {
                _bannerAd = null;
                _bannerAdIsLoaded = false;
              });
              if (_retryAttempt < _maxRetries) {
                _retryAttempt++;
                log('Retrying BannerAd load, attempt $_retryAttempt...');
                // --- MODIFICATION START ---
                // Pass the remoteConfigService to the retry call.
                Future.delayed(Duration(seconds: _retryAttempt * 2), () => _loadAd(remoteConfigService));
                // --- MODIFICATION END ---
              } else {
                log('Max BannerAd retries reached. Stopping attempts.');
                _retryAttempt = 0;
              }
            }
          },
          onAdOpened: (Ad ad) => log('BannerAd opened.'),
          onAdClosed: (Ad ad) => log('BannerAd closed.'),
          onAdImpression: (Ad ad) => log('BannerAd impression.'),
          onPaidEvent: (Ad ad, double valueMicros, PrecisionType precision, String currencyCode) =>
              log('BannerAd paidEvent: $valueMicros $precision $currencyCode'),
        ),
      );

      _bannerAd!.load();
    } catch (e) {
      log('Error creating banner ad: $e');
      if (!_isDisposed && _retryAttempt < _maxRetries) {
        _retryAttempt++;
        log('Retrying BannerAd load after error, attempt $_retryAttempt...');
        // --- MODIFICATION START ---
        Future.delayed(Duration(seconds: _retryAttempt * 2), () => _loadAd(remoteConfigService));
        // --- MODIFICATION END ---
      } else if (!_isDisposed) {
        log('Max BannerAd retries reached after error. Stopping attempts.');
        _retryAttempt = 0;
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The build method remains entirely unchanged.
    if (!_shouldShowAd) {
      return const SizedBox.shrink();
    }

    if (!_bannerAdIsLoaded || _bannerAd == null) {
      return Container(
        width: AdSize.banner.width.toDouble(),
        height: AdSize.banner.height.toDouble(),
        color: Colors.grey[200],
        child: const Center(
          child: Text(
            '廣告載入中...',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
