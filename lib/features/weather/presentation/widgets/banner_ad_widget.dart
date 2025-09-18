import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _bannerAdIsLoaded = false;

  bool _isDisposed = false;
  int _retryAttempt = 0; // Added retry counter
  static const int _maxRetries = 3; // Max retry attempts

  String _getAdUnitId() {
    if (kIsWeb) {
      // Web 平台支援有限，考慮返回 null 或顯示替代內容
      throw UnsupportedError("Web platform is not fully supported for AdMob");
    } else if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/9214589741'; // Android測試橫幅廣告單元ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2435281174'; // iOS測試橫幅廣告單元ID
    } else {
      throw UnsupportedError("Unsupported platform for AdMob banner ad");
    }
  }

  bool get _shouldShowAd {
    // 在 Web 平台不顯示廣告
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }

  @override
  void initState() {
    super.initState();
    if (_shouldShowAd) {
      _loadAd();
    }
  }

  void _loadAd() {
    if (_isDisposed) return;

    try {
      _bannerAd = BannerAd(
        adUnitId: _getAdUnitId(),
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!_isDisposed) {
              setState(() {
                _bannerAdIsLoaded = true;
                _retryAttempt = 0; // Reset retry counter on successful load
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
                log('Retrying BannerAd load, attempt $_retryAttempt of $_maxRetries...');
                Future.delayed(Duration(seconds: _retryAttempt * 2), () { // Exponential back-off for retry
                  _loadAd();
                });
              } else {
                log('Max BannerAd retries reached. Stopping attempts.');
                _retryAttempt = 0; // Reset for future attempts if triggered again
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
        log('Retrying BannerAd load after error, attempt $_retryAttempt of $_maxRetries...');
        Future.delayed(Duration(seconds: _retryAttempt * 2), () { // Exponential back-off for retry
          _loadAd();
        });
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
    // 如果不支援廣告的平台，顯示空白
    if (!_shouldShowAd) {
      return const SizedBox.shrink();
    }

    // 如果廣告尚未載入成功，顯示佔位符或空白
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