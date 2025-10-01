import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weatherpro/services/remote_config_service.dart'; // Import the centralized service
import 'package:weatherpro/utils/app_constants.dart';
import '../models/rainfall_data.dart';

class RadarForecastService extends ChangeNotifier {
  // MODIFICATION: The service now requires a RemoteConfigService instance to be passed in.
  final RemoteConfigService _remoteConfigService;

  // MODIFICATION: Removed the singleton pattern to allow for dependency injection.
  RadarForecastService({required RemoteConfigService remoteConfigService})
      : _remoteConfigService = remoteConfigService;

  String _r2FileUrl = '';
  Timer? _timer;
  RainfallData? _cachedRainfallData;
  DateTime? _dataTimestamp;

  bool _isLoading = false;
  bool _hasError = false;

  RainfallData? get rainfallData => _cachedRainfallData;
  DateTime? get dataTimestamp => _dataTimestamp;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  Future<void> initializeAndStartFetching() async {
    log('[RadarForecastService] 正在初始化...');
    try {
      // MODIFICATION: Removed all manual Remote Config initialization.
      // Now directly using the provided instance.
      _r2FileUrl = _remoteConfigService.radarRainfallUrl;
      
      if (_r2FileUrl.isEmpty) {
        log('[RadarForecastService] 警告: 從 Remote Config 獲取的 radar_rainfall_url 為空！');
        // We will still attempt to fetch later in case the URL becomes available.
      } else {
        log('[RadarForecastService] 成功從 Remote Config 獲取 R2 URL: $_r2FileUrl');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(radarRainfallUrlKey, _r2FileUrl);
        log('[RadarForecastService] URL 已儲存至 SharedPreferences 供後台任務使用。');
      }

    } catch (e) {
      log('[RadarForecastService] 讀取 Remote Config URL 時失敗: $e');
      _hasError = true;
      notifyListeners();
    }
    
    // The fetching logic remains the same.
    _startPeriodicFetching();
  }

  void _startPeriodicFetching() {
    _timer?.cancel();
    _fetchAndCacheData();
    _timer = Timer.periodic(const Duration(minutes: 10), (timer) {
      _fetchAndCacheData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAndCacheData() async {
    // If the URL was initially empty, try to get it again.
    if (_r2FileUrl.isEmpty) {
      _r2FileUrl = _remoteConfigService.radarRainfallUrl;
    }

    if (_r2FileUrl.isEmpty) {
      log('[RadarForecastService] R2 URL 為空，跳過資料獲取。');
      _hasError = true;
      notifyListeners();
      return;
    }

    log('[RadarForecastService] 開始從 R2 獲取資料...');
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(_r2FileUrl));
      
      log('[RadarForecastService] HTTP 回應狀態碼: ${response.statusCode}');

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        log('[RadarForecastService] 成功獲取資料，回應內容 (前500字元): ${responseBody.substring(0, responseBody.length > 500 ? 500 : responseBody.length)}');
        
        final Map<String, dynamic> jsonData = json.decode(responseBody);
        _cachedRainfallData = RainfallData.fromJson(jsonData);
        
        final timestampStr = _cachedRainfallData!.metadata['timestamp'] as String?;
        if (timestampStr != null) {
          _dataTimestamp = DateTime.tryParse(timestampStr);
        }
        
        log('[RadarForecastService] 資料解析成功！最新時間戳: $_dataTimestamp');
        _hasError = false;
      } else {
        log('[RadarForecastService] 獲取資料失敗，狀態碼: ${response.statusCode}');
        _hasError = true;
      }
    } catch (e) {
      log('[RadarForecastService] 獲取或解析資料時發生嚴重錯誤: $e');
      _hasError = true;
      _cachedRainfallData = null;
    } finally {
      _isLoading = false;
      log('[RadarForecastService] 資料獲取流程結束。 isLoading: $_isLoading, hasError: $_hasError');
      notifyListeners();
    }
  }
}
