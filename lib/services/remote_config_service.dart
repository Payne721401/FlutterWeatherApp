import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'dart:developer';

/// A service class to manage Firebase Remote Config for feature flags and app parameters.
///
/// This class follows the Singleton pattern to ensure only one instance
/// is used throughout the app.
class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;

  // Private constructor
  RemoteConfigService._(this._remoteConfig);

  // Singleton instance
  static RemoteConfigService? _instance;

  /// Returns the singleton instance of [RemoteConfigService].
  ///
  /// Initializes the service if it hasn't been initialized yet.
  static Future<RemoteConfigService> getInstance() async {
    if (_instance == null) {
      final remoteConfig = FirebaseRemoteConfig.instance;
      
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        // MODIFICATION: Cache interval changed to 15 minutes for faster updates.
        minimumFetchInterval: const Duration(minutes: 15),
      ));

      // Set default values for all remote parameters.
      // This ensures the app works correctly even if fetching fails.
      await remoteConfig.setDefaults(const {
        // Feature Flags
        'feature_home_enabled': true,
        'feature_ai_assistant_enabled': true,
        'feature_radar_enabled': true,

        // App Parameters
        'AI_Model': 'gemini-pro',
        'AI_Img_Model_Gemini': 'gemini-1.5-flash-preview-0514',
        'radar_rainfall_url': '', // Default to empty, handled by the service
        'ensemble_img_url': '',

        // Usage Limit Parameters
        'ai_daily_message_limit_level_1': 5,
        'ai_daily_image_limit_level_1': 2, // --- ADDED ---
        'ai_check_factor': 37,

        // --- MODIFICATION START: Minimum version parameters ---
        'min_version_android': 1,
        'min_version_ios': 1,
        // --- MODIFICATION END ---

        // --- MODIFICATION START: Ad Unit ID parameters ---
        'ad_unit_id_interstitial_android': '',
        'ad_unit_id_interstitial_ios': '',
        'ad_unit_id_native_android': '',
        'ad_unit_id_native_ios': '',
        'ad_unit_id_banner_android': '',
        'ad_unit_id_banner_ios': '',
        // --- MODIFICATION END ---
      });
      
      _instance = RemoteConfigService._(remoteConfig);
      log('RemoteConfigService initialized.', name: 'RemoteConfigService');
    }
    return _instance!;
  }

  /// Fetches the latest remote config values from the Firebase server
  /// and activates them.
  Future<void> fetchAndActivate() async {
    try {
      await _remoteConfig.fetchAndActivate();
      log('Remote Config fetched and activated successfully.', name: 'RemoteConfigService');
      // Log the current state of all flags
      logStatus();
    } catch (e) {
      log('Failed to fetch remote config: $e', name: 'RemoteConfigService');
    }
  }

  // --- Feature Flag Getters ---

  bool get isHomeEnabled => _remoteConfig.getBool('feature_home_enabled');
  bool get isAiAssistantEnabled => _remoteConfig.getBool('feature_ai_assistant_enabled');
  bool get isRadarEnabled => _remoteConfig.getBool('feature_radar_enabled');

  // --- App Parameter Getters ---

  /// The name of the AI model to be used by the assistant.
  String get aiModelName => _remoteConfig.getString('AI_Model');

  // --- ADDED START ---
  /// The name of the AI model to be used to generate images.
  String get aiImageModelName => _remoteConfig.getString('AI_Img_Model_Gemini');
  // --- ADDED END ---
  
  /// The URL for the radar rainfall data file.
  String get radarRainfallUrl => _remoteConfig.getString('radar_rainfall_url');

  // --- Usage Limit Parameter Getters ---

  /// The daily message limit for level 1 users.
  int get aiDailyMessageLimitLevel1 => _remoteConfig.getInt('ai_daily_message_limit_level_1');

  // --- ADDED START ---
  /// The daily image generation limit for level 1 users.
  int get aiDailyImageLimitLevel1 => _remoteConfig.getInt('ai_daily_image_limit_level_1');
  // --- ADDED END ---

  /// The factor used for local logic obfuscation.
  int get aiCheckFactor => _remoteConfig.getInt('ai_check_factor');
  
  String get ensembleImgUrl => _remoteConfig.getString('ensemble_img_url');

  // --- MODIFICATION START: Getters for minimum version ---
  int get minVersionAndroid => _remoteConfig.getInt('min_version_android');
  int get minVersionIos => _remoteConfig.getInt('min_version_ios');
  // --- MODIFICATION END ---

  // --- MODIFICATION START: Getters for Ad Unit IDs ---
  String get interstitialAdUnitIdAndroid => _remoteConfig.getString('ad_unit_id_interstitial_android');
  String get interstitialAdUnitIdIos => _remoteConfig.getString('ad_unit_id_interstitial_ios');
  String get nativeAdUnitIdAndroid => _remoteConfig.getString('ad_unit_id_native_android');
  String get nativeAdUnitIdIos => _remoteConfig.getString('ad_unit_id_native_ios');
  String get bannerAdUnitIdAndroid => _remoteConfig.getString('ad_unit_id_banner_android');
  String get bannerAdUnitIdIos => _remoteConfig.getString('ad_unit_id_banner_ios');
  // --- MODIFICATION END ---

  /// Logs the current status of all feature flags.
  void logStatus() {
    log('Current Flags: [Home: $isHomeEnabled, AI: $isAiAssistantEnabled, Radar: $isRadarEnabled]', name: 'RemoteConfigService');
    log('Current Params: [AI Model: $aiModelName, Radar URL: $radarRainfallUrl]', name: 'RemoteConfigService');
  }
}
