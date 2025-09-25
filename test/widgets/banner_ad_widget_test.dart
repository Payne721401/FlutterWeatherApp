
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:weatherpro/services/remote_config_service.dart';
import 'package:weatherpro/widgets/banner_ad_widget.dart';

// 建立 Mock
class MockRemoteConfigService extends Mock implements RemoteConfigService {}

void main() {
  // 【最終修正】偽裝平台為 Android，以繞過 Platform.isAndroid 檢查
  debugDefaultTargetPlatformOverride = TargetPlatform.android;

  late MockRemoteConfigService mockRemoteConfigService;

  setUp(() {
    mockRemoteConfigService = MockRemoteConfigService();
    when(() => mockRemoteConfigService.bannerAdUnitIdAndroid).thenReturn('test-android-id');
    when(() => mockRemoteConfigService.bannerAdUnitIdIos).thenReturn('test-ios-id');
  });

  // 輔助函式，用於建構我們的測試環境
  Future<void> pumpBannerAdWidget(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<RemoteConfigService>.value(value: mockRemoteConfigService),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: BannerAdWidget(),
          ),
        ),
      ),
    );
  }

  group('BannerAdWidget - Initial State Unit Test', () {
    testWidgets('should display loading indicator initially without errors', (WidgetTester tester) async {
      // 安排 (Arrange)
      await pumpBannerAdWidget(tester);

      // 斷言 (Assert)
      expect(find.text('廣告載入中...'), findsOneWidget);
    });

    testWidgets('should not throw error if ad unit id is empty', (WidgetTester tester) async {
      // 安排 (Arrange)
      when(() => mockRemoteConfigService.bannerAdUnitIdAndroid).thenReturn('');

      // 行動 (Act)
      await pumpBannerAdWidget(tester);

      // 斷言 (Assert)
      // 【已還原】如此處邏輯解釋，Widget 應維持在載入中狀態
      expect(find.text('廣告載入中...'), findsOneWidget);
    });
  });
  
  // 【還原】測試結束後，將平台偽裝清除，避免影響其他測試檔案
  tearDownAll(() {
     debugDefaultTargetPlatformOverride = null;
  });
}
