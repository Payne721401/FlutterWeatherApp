
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // 【新增】導入服務
import 'package:freerasp/freerasp.dart';
import './error_reporting_service.dart'; // 【新增】導入服務

enum ThreatSeverity {
  critical, // 嚴重威脅，應終止 App
  warning,  // 警告威脅，僅報告
}

// 【移除】不再需要 AppSecurityState 枚舉

/// SecurityService - 封裝 freeRASP 功能，實現靜默報告和關鍵終止
class SecurityService { // 【移除】移除 with ChangeNotifier
  
  // 【新增】注入依賴
  final ErrorReportingService _reportingService;
  SecurityService({required ErrorReportingService reportingService})
      : _reportingService = reportingService;

  // 【移除】不再需要任何與 UI 狀態相關的變數

  /// 初始化 freeRASP 並開始監聽威脅
  Future<void> initialize() async {
    // 1. & 2. & 3. 您的 Android/iOS/Talsec 配置保持不變
    final androidConfig = AndroidConfig(
      packageName: 'com.weatherpro.ai.android',
      signingCertHashes: ['cnq9G1rW10FxjAV13GCMfswDimyWMauVfXSvFo5wKyA='],
    );
    final iosConfig = IOSConfig(
      bundleIds: ['com.weatherpro.ai.ios'],
      teamId: 'YOUR_TEAM_ID',
    );
    final config = TalsecConfig(
      androidConfig: androidConfig,
      iosConfig: iosConfig,
      watcherMail: '90727sam@gmail.com',
      isProd: kReleaseMode,
    );

    // 4. 【修改】更新回呼以包含威脅分級
    final actions = ThreatCallback(
      // --- Critical Threats ---
      onPrivilegedAccess: () => _handleThreat('設備已被 Root/越獄。', ThreatSeverity.critical),
      onHooks: () => _handleThreat('偵測到掛鉤框架。', ThreatSeverity.critical),
      onAppIntegrity: () => _handleThreat('應用程式完整性被破壞。', ThreatSeverity.critical),

      // --- Warning Threats ---
      onDebug: () => _handleThreat('偵測到調試器附加。', ThreatSeverity.warning),
      onSimulator: () => _handleThreat('應用程式正在模擬器中執行。', ThreatSeverity.warning),
      onUnofficialStore: () => _handleThreat('應用程式非從官方商店安裝。', ThreatSeverity.warning),
      onDeviceBinding: () => _handleThreat('應用程式綁定的設備不符。', ThreatSeverity.warning),
      onSecureHardwareNotAvailable: () => _handleThreat('安全硬體不可用。', ThreatSeverity.warning),
      onObfuscationIssues: () => _handleThreat('程式碼混淆存在問題。', ThreatSeverity.warning),
    );

    // 5. & 6. 您的啟動和監聽器附加方法保持不變
    await Talsec.instance.start(config);
    Talsec.instance.attachListener(actions);

    developer.log("freeRASP initialized with silent reporting.", name: "SecurityService");
  }

  /// 【重構】威脅處理方法，執行報告和行動
  void _handleThreat(String reason, ThreatSeverity severity) {
    developer.log(
      "Threat detected: $reason, Severity: ${severity.name}",
      name: "SecurityService",
      level: 900, // 使用較高的日誌級別
    );

    // 步驟 1: 向後台報告威脅
    _reportingService.reportSecurityThreat(reason, severity.name);

    // 步驟 2: 根據嚴重性採取行動
    if (severity == ThreatSeverity.critical) {
      // 關鍵威脅 -> 終止應用程式
      SystemNavigator.pop();
    }
    // 對於警告威脅，報告後不執行任何 UI 操作
  }
}
