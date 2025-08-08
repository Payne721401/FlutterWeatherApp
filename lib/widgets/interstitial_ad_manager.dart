import 'dart:developer';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/remote_config_service.dart';
import 'dart:io' show Platform;

class InterstitialAdManager {
  InterstitialAdManager._privateConstructor();

  static final InterstitialAdManager _instance = InterstitialAdManager._privateConstructor();

  static InterstitialAdManager get instance => _instance;

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  DateTime _lastAdShowTime = DateTime.now();
  final Duration _adFrequency = const Duration(minutes: 3);

  RemoteConfigService? _remoteConfigService;

  /*
  String get _adUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Android Test ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // iOS Test ID
    } else {
      throw UnsupportedError("Unsupported platform for interstitial ads");
    }
  }
  */

  void loadAd({required RemoteConfigService remoteConfigService}) {
    _remoteConfigService = remoteConfigService;

    if (_isAdLoaded || _interstitialAd != null) {
      log('[InterstitialAdManager] Ad already loaded or loading.');
      return;
    }

    final String adUnitId;
    if (Platform.isAndroid) {
      adUnitId = _remoteConfigService!.interstitialAdUnitIdAndroid;
    } else if (Platform.isIOS) {
      adUnitId = _remoteConfigService!.interstitialAdUnitIdIos;
    } else {
      log("[InterstitialAdManager] Unsupported platform. Ad not loaded.");
      return;
    }

    if (adUnitId.isEmpty) {
      log("[InterstitialAdManager] Ad Unit ID from Remote Config is empty. Ad not loaded.");
      return;
    }

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          log('[InterstitialAdManager] Ad loaded successfully.');
          _interstitialAd = ad;
          _isAdLoaded = true;
          _setFullScreenContentCallback();
        },
        onAdFailedToLoad: (error) {
          log('[InterstitialAdManager] Ad failed to load: $error');
          _interstitialAd = null;
          _isAdLoaded = false;
        },
      ),
    );
  }

  void _setFullScreenContentCallback() {
    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => log('[InterstitialAdManager] Ad showed full screen.'),
      onAdDismissedFullScreenContent: (ad) {
        log('[InterstitialAdManager] Ad dismissed.');
        _cleanupAd();
        if (_remoteConfigService != null) {
          loadAd(remoteConfigService: _remoteConfigService!);
        } else {
          log('[InterstitialAdManager] RemoteConfigService not available to preload next ad.');
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        log('[InterstitialAdManager] Ad failed to show full screen: $error');
        _cleanupAd();
        if (_remoteConfigService != null) {
          loadAd(remoteConfigService: _remoteConfigService!);
        } else {
          log('[InterstitialAdManager] RemoteConfigService not available to preload next ad.');
        }
      },
    );
  }

  void showAd({required RemoteConfigService remoteConfigService}) {
    if (!_isAdLoaded || _interstitialAd == null) {
      log('[InterstitialAdManager] Ad is not ready to be shown.');
      loadAd(remoteConfigService: remoteConfigService);
      return;
    }

    if (_isFrequencyCapped()) {
      log('[InterstitialAdManager] Ad show attempt is frequency capped.');
      return;
    }

    _interstitialAd!.show();
    _lastAdShowTime = DateTime.now();
  }

  bool _isFrequencyCapped() {
    final timeSinceLastAd = DateTime.now().difference(_lastAdShowTime);
    return timeSinceLastAd < _adFrequency;
  }

  void _cleanupAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdLoaded = false;
  }

  void dispose() {
    _cleanupAd();
  }
}
