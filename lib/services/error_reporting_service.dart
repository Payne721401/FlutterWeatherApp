
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// 自定義異常，用於在 Crashlytics 中清晰地標識安全威脅報告。
class SecurityThreatException implements Exception {
  final String message;
  SecurityThreatException(this.message);

  @override
  String toString() => 'SecurityThreatException: $message';
}

/// ErrorReportingService - 專門用於向後台報告錯誤和事件的服務。
class ErrorReportingService {
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// 向 Firebase Crashlytics 報告一個非致命的安全威脅。
  Future<void> reportSecurityThreat(String reason, String severity) async {
    final exception = SecurityThreatException('RASP Threat Detected: $reason');
    final stackTrace = StackTrace.current;

    // 記錄一個非致命錯誤
    await _crashlytics.recordError(
      exception,
      stackTrace,
      reason: 'freeRASP Detection',
      // 附加額外資訊以供篩選
      information: [
        'Severity: $severity',
        'Threat Reason: $reason',
      ],
      fatal: false, // 標記為非致命錯誤
    );
  }
}
