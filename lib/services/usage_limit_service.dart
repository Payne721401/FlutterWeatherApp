import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:weatherpro/services/auth_service.dart';
import 'package:weatherpro/services/remote_config_service.dart';

/// 自定義異常，由 runProtectedAiAction 在用量耗盡或驗證失敗時拋出。
class UsageLimitException implements Exception {
  final String message;
  UsageLimitException(this.message);

  @override
  String toString() => 'UsageLimitException: $message';
}

/// UsageLimitService - 負責處理所有與 AI 用量計數相關的安全邏輯。
/// 該服務嚴格遵循最終確認的「安全每日重置計數器」計畫，並加入客戶端混淆邏輯。
class UsageLimitService with ChangeNotifier {
  final AuthService _authService;
  final RemoteConfigService _remoteConfigService;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  User? _currentUser;
  int _dailyMessageCount = 0;
  int _dailyMessageLimit = 20; // 預設值，主要用於UI顯示和客戶端預檢
  int _dailyImageCount = 0; // --- ADDED ---
  int _dailyImageLimit = 10;   // --- ADDED ---
  bool _isInitialized = false;

  // --- Public Getters for UI display ---
  int get dailyMessageCount => _dailyMessageCount;
  int get dailyMessageLimit => _dailyMessageLimit;
  int get dailyImageCount => _dailyImageCount; // --- ADDED ---
  int get dailyImageLimit => _dailyImageLimit; // --- ADDED ---
  bool get isInitialized => _isInitialized;

  UsageLimitService({
    required AuthService authService,
    required RemoteConfigService remoteConfigService,
  })  : _authService = authService,
        _remoteConfigService = remoteConfigService {
    initialize();
  }

  /// 初始化服務，主動獲取用戶狀態，並監聽後續變化。
  void initialize() {
    _dailyMessageLimit = _remoteConfigService.aiDailyMessageLimitLevel1;
    _dailyImageLimit = _remoteConfigService.aiDailyImageLimitLevel1; // --- ADDED ---
    _handleUserChange(_authService.currentUser);
    _authService.authStateChanges.listen(_handleUserChange);
  }

  void _handleUserChange(User? user) {
    _currentUser = user;
    if (user != null) {
      _syncInitialCount(user.uid);
    } else {
      _isInitialized = false;
      _dailyMessageCount = 0;
      _dailyImageCount = 0; // --- ADDED ---
      notifyListeners();
    }
  }

  Future<void> _syncInitialCount(String uid) async {
    final utcDayInfo = _getUtcPlus8DayInfo();
    final int todayTimestamp = utcDayInfo['dayTimestamp'];
    final dbRef = _database.ref('daily_counters/$uid');
    
    try {
      final snapshot = await dbRef.get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        if (data['dayTimestamp'] == todayTimestamp) {
          _dailyMessageCount = data['count'] as int? ?? 0;
          _dailyImageCount = data['image_count'] as int? ?? 0; // --- ADDED ---
        } else {
          _dailyMessageCount = 0;
          _dailyImageCount = 0; // --- ADDED ---
        }
      } else {
        _dailyMessageCount = 0;
        _dailyImageCount = 0; // --- ADDED ---
      }
    } catch (e) {
      // MODIFICATION: Replaced debugPrint with a simple log
      developer.log("Failed to sync initial count: $e");
      _dailyMessageCount = 0;
      _dailyImageCount = 0; // --- ADDED ---
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// 核心安全執行器：在執行敏感操作前，透過客戶端預檢和後端原子性事務來安全地增加計數器。
  Future<void> runProtectedAiAction(Future<void> Function() aiAction) async {
    if (!_isInitialized || _currentUser == null) {
      throw UsageLimitException("用量服務尚未就緒，請登入後再試。");
    }

    if (!_isMessageAllowedToProceed()) { 
      await _syncInitialCount(_currentUser!.uid);
      if (!_isMessageAllowedToProceed()) { 
        throw UsageLimitException("訊息已達今日上限。");
      }
    }

    final utcDayInfo = _getUtcPlus8DayInfo();
    final dbRef = _database.ref('daily_counters/${_currentUser!.uid}');

    final TransactionResult result = await dbRef.runTransaction((Object? mutableData) {
      final todayDateString = utcDayInfo['dateString'];
      final todayTimestamp = utcDayInfo['dayTimestamp'];

      if (mutableData == null) {
        return Transaction.success({'count': 1, 'image_count': 0, 'dateString': todayDateString, 'dayTimestamp': todayTimestamp});
      }

      final Map<String, dynamic> data = Map<String, dynamic>.from(mutableData as Map);
      if ((data['dayTimestamp'] as int? ?? 0) == todayTimestamp) {
        data['count'] = (data['count'] as int? ?? 0) + 1;
      } else {
        data['count'] = 1;
        // data['image_count'] = 0;
        data['dateString'] = todayDateString;
        data['dayTimestamp'] = todayTimestamp;
      }
      return Transaction.success(data);
    });

    if (result.committed && result.snapshot != null) {
      final data = Map<String, dynamic>.from(result.snapshot!.value as Map);
      _dailyMessageCount = data['count'] as int;
      notifyListeners();
      await aiAction();
    } else {
      await _syncInitialCount(_currentUser!.uid);
      throw UsageLimitException("已達今日上限，請明天再試。");
    }
  }

  // --- MODIFICATION START: Logic changed to increment count AFTER action ---
  /// 為圖片生成操作設計的獨立安全執行器。
  Future<void> runProtectedImageAction(Future<void> Function() imageAction) async {
    if (!_isInitialized || _currentUser == null) {
      throw UsageLimitException("用量服務尚未就緒，請登入後再試。");
    }

    if (!_isImageAllowedToProceed()) {
      await _syncInitialCount(_currentUser!.uid);
      if (!_isImageAllowedToProceed()) {
        throw UsageLimitException("圖片生成已達今日上限。");
      }
    }

    try {
      await imageAction();
    } catch (e) {
      // If the action itself fails, re-throw the exception without incrementing the counter.
      rethrow;
    }

    final utcDayInfo = _getUtcPlus8DayInfo();
    final dbRef = _database.ref('daily_counters/${_currentUser!.uid}');

    final TransactionResult result = await dbRef.runTransaction((Object? mutableData) {
      final todayDateString = utcDayInfo['dateString'];
      final todayTimestamp = utcDayInfo['dayTimestamp'];

      if (mutableData == null) {
        return Transaction.success({'count': 0, 'image_count': 1, 'dateString': todayDateString, 'dayTimestamp': todayTimestamp});
      }

      final Map<String, dynamic> data = Map<String, dynamic>.from(mutableData as Map);
      if ((data['dayTimestamp'] as int? ?? 0) == todayTimestamp) {
        data['image_count'] = (data['image_count'] as int? ?? 0) + 1;
      } else {
        // This is the first image generation of the new day.
        // Per RTDB rule (A-2), we must reset both counters.
        // data['count'] = 0;
        data['image_count'] = 1;
        data['dateString'] = todayDateString;
        data['dayTimestamp'] = todayTimestamp;
      }
      return Transaction.success(data);
    });

    if (result.committed && result.snapshot != null) {
      final data = Map<String, dynamic>.from(result.snapshot!.value as Map);
      _dailyImageCount = data['image_count'] as int;
      notifyListeners();
    } else {
      await _syncInitialCount(_currentUser!.uid);
      // The action succeeded, but the counter failed to increment. 
      // Throwing the original error to not alter the logic.
      throw UsageLimitException("已達今日上限，請明天再試。");
    }
  }
  // --- MODIFICATION END ---

  Map<String, dynamic> _getUtcPlus8DayInfo() {
    final nowUtc = DateTime.now().toUtc();
    final nowInUtcPlus8 = nowUtc.add(const Duration(hours: 8));
    final startOfDayInUtcPlus8 = DateTime.utc(nowInUtcPlus8.year, nowInUtcPlus8.month, nowInUtcPlus8.day);
    final startOfDayInUtc = startOfDayInUtcPlus8.subtract(const Duration(hours: 8));
    return {
      'dateString': DateFormat('yyyy-MM-dd').format(startOfDayInUtcPlus8),
      'dayTimestamp': startOfDayInUtc.millisecondsSinceEpoch,
    };
  }

  bool _isMessageAllowedToProceed() {
    final count = _dailyMessageCount;
    final limit = _dailyMessageLimit;
    final factor = _remoteConfigService.aiCheckFactor;

    if (factor <= 0 || limit <= 0) return false;

    final calculatedDiff = (limit * factor) - (count * factor);
    if (calculatedDiff <= 0) {
      return false;
    }

    if ((' ' * count).length >= (' ' * limit).length) {
      return false;
    }
    
    return true;
  }

  bool _isImageAllowedToProceed() {
    final count = _dailyImageCount;
    final limit = _dailyImageLimit;
    final factor = _remoteConfigService.aiCheckFactor;

    if (factor <= 0 || limit <= 0) return false;

    final calculatedDiff = (limit * factor) - (count * factor);
    if (calculatedDiff <= 0) {
      return false;
    }

    if ((' ' * count).length >= (' ' * limit).length) {
      return false;
    }

    return true;
  }
}
