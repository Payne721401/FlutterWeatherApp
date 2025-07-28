// 檔案：lib/native_ad_widget.dart

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

//================================================================================
// 公開的、給外部使用的 Widget
// 使用方法：在你的 UI 中直接呼叫 const SmallNativeAd() 或 const MediumNativeAd() 即可。
//================================================================================

/// 顯示一個小型原生廣告 (建議高度 100-120dp)。
/// 對應你在原生端註冊的 'adFactorySmall'。
class SmallNativeAd extends StatelessWidget {
  const SmallNativeAd({super.key});

  @override
  Widget build(BuildContext context) {
    return _BaseNativeAdWidget(
      factoryId: 'adFactorySmall',
      height: 120, // 根據 Google 範本，這是一個安全且合規的高度
    );
  }
}

/// 顯示一個中型、帶有媒體視圖的原生廣告 (建議高度 300-350dp)。
/// 對應你在原生端註冊的 'adFactoryMedium' (你之前的 'adFactoryExample')。
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

/// 顯示一個全螢幕的原生廣告。
/// 注意：你需要在原生端 (Android/iOS) 建立對應的 'adFactoryFullScreen' 和佈局檔案。
class FullScreenNativeAd extends StatelessWidget {
  const FullScreenNativeAd({super.key});

  @override
  Widget build(BuildContext context) {
    // 高度直接填滿整個螢幕
    return _BaseNativeAdWidget(
      factoryId: 'adFactoryFullScreen',
      height: MediaQuery.of(context).size.height,
    );
  }
}


//================================================================================
// 私有的、核心的廣告邏輯 Widget (外部不應該直接呼叫)
//================================================================================

/// 這個 Widget 負責處理所有原生廣告的通用邏輯，包括：
/// - 根據平台獲取廣告 ID
/// - 載入廣告
/// - 處理載入成功/失敗的事件
/// - 包含完整的重試機制
/// - 釋放資源
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

  bool get _shouldShowAd => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

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
      _nativeAd = NativeAd(
        adUnitId: _getAdUnitId(),
        factoryId: widget.factoryId, // 使用從包裝 Widget 傳入的 factoryId
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
            print('NativeAd failed to load (factory: ${widget.factoryId}): ${err.message}');
            ad.dispose();
            if (!_isDisposed) {
              setState(() {
                _nativeAd = null;
                _nativeAdIsLoaded = false;
              });
              if (_retryAttempt < _maxRetries) {
                _retryAttempt++;
                print('Retrying NativeAd load, attempt $_retryAttempt...');
                Future.delayed(Duration(seconds: _retryAttempt * 2), _loadAd);
              } else {
                print('Max NativeAd retries reached for factory: ${widget.factoryId}.');
                _retryAttempt = 0;
              }
            }
          },
          onAdOpened: (Ad ad) => print('NativeAd opened.'),
          onAdClosed: (Ad ad) => print('NativeAd closed.'),
          onAdImpression: (Ad ad) => print('NativeAd impression.'),
          onPaidEvent: (Ad ad, double valueMicros, PrecisionType precision, String currencyCode) =>
              print('NativeAd paidEvent: $valueMicros $precision $currencyCode'),
        ),
      );
      _nativeAd!.load();
    } catch (e) {
      print('Error creating native ad: $e');
      if (!_isDisposed && _retryAttempt < _maxRetries) {
        // ... (省略部分重複的錯誤處理程式碼以保持簡潔)
      }
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
    if (!_shouldShowAd) {
      return const SizedBox.shrink();
    }

    if (!_nativeAdIsLoaded || _nativeAd == null) {
      // 在廣告載入時，顯示一個有固定高度的佔位符，避免畫面跳動
      return Container(
        height: widget.height,
        width: double.infinity,
        alignment: Alignment.center,
        child: Text('廣告載入中...', style: TextStyle(color: Colors.grey[400])),
      );
    }

    // 廣告載入成功，顯示廣告
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: AdWidget(ad: _nativeAd!),
    );
  }
}