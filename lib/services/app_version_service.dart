import 'dart:io' show Platform;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:developer';

import 'remote_config_service.dart';

/// A service class to manage app versioning and first-launch logic.
///
/// This singleton service provides information about the app's version
/// and build number, checks if a mandatory update is required, and
/// determines if it's the user's first time launching the app.
class AppVersionService {
  // --- Singleton Setup ---
  static final AppVersionService _instance = AppVersionService._internal();
  factory AppVersionService() => _instance;
  AppVersionService._internal();

  PackageInfo? _packageInfo;
  SharedPreferences? _prefs;

  /// Initializes the service by loading package info and shared preferences.
  /// This should be called once at app startup.
  Future<void> initialize() async {
    _packageInfo = await PackageInfo.fromPlatform();
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Getters for Version Info ---

  /// The app's version name (e.g., "1.0.1"). Returns 'N/A' if not available.
  String get appVersion => _packageInfo?.version ?? 'N/A';

  /// The app's build number (e.g., "2"). Returns 'N/A' if not available.
  String get buildNumber => _packageInfo?.buildNumber ?? 'N/A';

  // --- Update Check Logic ---

  /// Checks if a mandatory update is required by comparing the current build number
  /// with the minimum version specified in Remote Config.
  bool isUpdateRequired(RemoteConfigService remoteConfig) {
    if (kIsWeb || _packageInfo == null) return false;

    final currentBuildNumber = int.tryParse(buildNumber) ?? 0;
    if (currentBuildNumber == 0) return false; // Failsafe

    int minRequiredVersion;
    if (Platform.isAndroid) {
      minRequiredVersion = remoteConfig.minVersionAndroid;
    } else if (Platform.isIOS) {
      minRequiredVersion = remoteConfig.minVersionIos;
    } else {
      return false; // Unsupported platform
    }

    // DEBUGGING: Print the values being compared
    log('Version Check -> Current Build: $currentBuildNumber, Required Build: $minRequiredVersion', name: 'AppVersionService');

    return currentBuildNumber < minRequiredVersion;
  }

  // --- First Launch (Beta Warning) Logic ---

  static const String _betaWarningFlag = 'has_seen_beta_warning';

  /// Checks if this is the first time the app is being launched.
  /// This is used to determine if the beta warning should be shown.
  bool isFirstLaunch() {
    return _prefs?.getBool(_betaWarningFlag) ?? true;
  }

  /// Marks the beta warning as seen. This should be called after the
  /// warning dialog is shown to the user.
  Future<void> markBetaWarningAsSeen() async {
    await _prefs?.setBool(_betaWarningFlag, false);
  }
}
