
import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:weatherpro/services/auth_service.dart';
import 'package:weatherpro/services/remote_config_service.dart';

/// Custom exception thrown by runProtectedAiAction when usage is depleted or validation fails.
class UsageLimitException implements Exception {
  final String message;
  UsageLimitException(this.message);

  @override
  String toString() => 'UsageLimitException: $message';
}

/// UsageLimitService - Handles all security logic related to AI usage counting.
/// This service strictly follows the finalized "Secure Daily Reset Counter" plan, including client-side obfuscation logic.
class UsageLimitService with ChangeNotifier {
  final AuthService _authService;
  final RemoteConfigService _remoteConfigService;
  final FirebaseDatabase _database;

  User? _currentUser;
  int _dailyMessageCount = 0;
  int _dailyMessageLimit = 20; // Default value, mainly for UI display and client-side pre-check
  int _dailyImageCount = 0; // --- ADDED ---
  int _dailyImageLimit = 10;   // --- ADDED ---
  bool _isInitialized = false;

  // --- Public Getters for UI display ---
  int get dailyMessageCount => _dailyMessageCount;
  int get dailyMessageLimit => _dailyMessageLimit;
  int get dailyImageCount => _dailyImageCount; // --- ADDED ---
  int get dailyImageLimit => _dailyImageLimit; // --- ADDED ---
  bool get isInitialized => _isInitialized;

  // Public constructor for app use
  UsageLimitService({
    required AuthService authService,
    required RemoteConfigService remoteConfigService,
  }) : this.internal(
          authService: authService,
          remoteConfigService: remoteConfigService,
          database: FirebaseDatabase.instance,
        );

  // Internal constructor for testing purposes
  @visibleForTesting
  UsageLimitService.internal({
    required AuthService authService,
    required RemoteConfigService remoteConfigService,
    required FirebaseDatabase database,
  })  : _authService = authService,
        _remoteConfigService = remoteConfigService,
        _database = database {
    initialize();
  }


  /// Initializes the service, proactively fetches user status, and listens for subsequent changes.
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

  /// Core secure executor: Safely increments the counter through client-side pre-check and backend atomic transaction before executing a sensitive operation.
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

    try {
      await aiAction();
    } catch (e) {
      rethrow;
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
        data['image_count'] = 0;
        data['dateString'] = todayDateString;
        data['dayTimestamp'] = todayTimestamp;
      }
      return Transaction.success(data);
    });

    if (result.committed && result.snapshot != null) {
      final data = Map<String, dynamic>.from(result.snapshot!.value as Map);
      _dailyMessageCount = data['count'] as int;
      notifyListeners();
    } else {
      await _syncInitialCount(_currentUser!.uid);
      throw UsageLimitException("已達今日上限，請明天再試。");
    }
  }

  // --- MODIFICATION START: Logic changed to increment count AFTER action ---
  /// A separate secure executor for image generation operations.
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
        data['count'] = 0;
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
