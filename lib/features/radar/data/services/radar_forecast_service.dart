import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/utils/app_constants.dart'; // Import the new constants file
import '../models/rainfall_data.dart';

class RadarForecastService extends ChangeNotifier {
  static final RadarForecastService _instance = RadarForecastService._internal();
  factory RadarForecastService() => _instance;
  RadarForecastService._internal();

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
    print('[RadarForecastService] 正在初始化...');
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(minutes: 5),
      ));
      await remoteConfig.setDefaults(const {"radar_rainfall_url": ""});
      await remoteConfig.fetchAndActivate();
      
      _r2FileUrl = remoteConfig.getString("radar_rainfall_url");
      
      if (_r2FileUrl.isEmpty) {
        print('[RadarForecastService] 警告: 從 Remote Config 獲取的 radar_rainfall_url 為空！');
      } else {
        print('[RadarForecastService] 成功從 Remote Config 獲取 R2 URL: $_r2FileUrl');
        final prefs = await SharedPreferences.getInstance();
        // Use the shared constant key to save the URL
        await prefs.setString(radarRainfallUrlKey, _r2FileUrl);
        print('[RadarForecastService] URL 已儲存至 SharedPreferences 供後台任務使用。');
      }

      _startPeriodicFetching();
    } catch (e) {
      print('[RadarForecastService] Firebase Remote Config 初始化失敗: $e');
      _hasError = true;
      notifyListeners();
      _startPeriodicFetching();
    }
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
    if (_r2FileUrl.isEmpty) {
      print('[RadarForecastService] R2 URL 為空，跳過資料獲取。');
      _hasError = true;
      notifyListeners();
      return;
    }

    print('[RadarForecastService] 開始從 R2 獲取資料...');
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(_r2FileUrl));
      
      print('[RadarForecastService] HTTP 回應狀態碼: ${response.statusCode}');

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        print('[RadarForecastService] 成功獲取資料，回應內容 (前500字元): ${responseBody.substring(0, responseBody.length > 500 ? 500 : responseBody.length)}');
        
        final Map<String, dynamic> jsonData = json.decode(responseBody);
        _cachedRainfallData = RainfallData.fromJson(jsonData);
        
        final timestampStr = _cachedRainfallData!.metadata['timestamp'] as String?;
        if (timestampStr != null) {
          _dataTimestamp = DateTime.tryParse(timestampStr);
        }
        
        print('[RadarForecastService] 資料解析成功！最新時間戳: $_dataTimestamp');
        _hasError = false;
      } else {
        print('[RadarForecastService] 獲取資料失敗，狀態碼: ${response.statusCode}');
        _hasError = true;
      }
    } catch (e) {
      print('[RadarForecastService] 獲取或解析資料時發生嚴重錯誤: $e');
      _hasError = true;
      _cachedRainfallData = null;
    } finally {
      _isLoading = false;
      print('[RadarForecastService] 資料獲取流程結束。 isLoading: $_isLoading, hasError: $_hasError');
      notifyListeners();
    }
  }
}
