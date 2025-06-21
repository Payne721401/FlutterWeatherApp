import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb; // 新增這行

class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _nativeAdIsLoaded = false;

  // TODO: replace this test ad unit with your own ad unit.
  final String _adUnitId = kIsWeb
      ? 'ca-app-pub-3940256099942544/2247696110' // Web測試原生廣告單元ID (通常與Android相同或通用)
      : Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/2247696110' // Android測試原生廣告單元ID
          : 'ca-app-pub-3940256099942544/3986624511'; // iOS測試原生廣告單元ID

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _nativeAd = NativeAd(
        adUnitId: _adUnitId,
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            print('$NativeAd loaded.');
            setState(() {
              _nativeAd = ad as NativeAd;
              _nativeAdIsLoaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {
            // Dispose the ad here to free resources.
            print('$NativeAd failedToLoad: $error');
            ad.dispose();
          },
          onAdClicked: (ad) {},
          onAdImpression: (ad) {},
          onAdClosed: (ad) {},
          onAdOpened: (ad) {},
          onPaidEvent: (ad, valueMicros, precision, currencyCode) {},
        ),
        request: const AdRequest(),
        nativeTemplateStyle: NativeTemplateStyle(
            templateType: TemplateType.small, // 將尺寸設定為 small
            mainBackgroundColor: Colors.grey[200], // 調整背景色以符合現有佈局
            cornerRadius: 8.0,
            callToActionTextStyle: NativeTemplateTextStyle(
                textColor: Colors.white,
                backgroundColor: Colors.blue,
                style: NativeTemplateFontStyle.normal,
                size: 14.0),
            primaryTextStyle: NativeTemplateTextStyle(
                textColor: Colors.black,
                backgroundColor: Colors.transparent,
                style: NativeTemplateFontStyle.bold,
                size: 16.0),
            secondaryTextStyle: NativeTemplateTextStyle(
                textColor: Colors.grey[700],
                backgroundColor: Colors.transparent,
                style: NativeTemplateFontStyle.normal,
                size: 12.0),
            tertiaryTextStyle: NativeTemplateTextStyle(
                textColor: Colors.grey[500],
                backgroundColor: Colors.transparent,
                style: NativeTemplateFontStyle.normal,
                size: 10.0)))
      ..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_nativeAdIsLoaded || _nativeAd == null) {
      return const SizedBox.shrink(); // 如果廣告尚未載入，則顯示一個空的 SizedBox
    }

    return Container(
      // Container decoration is now primarily for padding/margin, as styling is handled by nativeTemplateStyle
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      padding: const EdgeInsets.all(8.0),
      child: AdWidget(ad: _nativeAd!),
    );
  }
}
