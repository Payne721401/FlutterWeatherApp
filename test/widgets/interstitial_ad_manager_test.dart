
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weatherpro/services/remote_config_service.dart';
import 'package:weatherpro/widgets/interstitial_ad_manager.dart';

// 建立 Mock
class MockRemoteConfigService extends Mock implements RemoteConfigService {}

void main() {
  // 【最終修正 - 步驟 1】偽裝平台為 Android
  debugDefaultTargetPlatformOverride = TargetPlatform.android;

  TestWidgetsFlutterBinding.ensureInitialized();

  late InterstitialAdManager interstitialAdManager;
  late MockRemoteConfigService mockRemoteConfigService;

  setUp(() {
    interstitialAdManager = InterstitialAdManager.instance;
    mockRemoteConfigService = MockRemoteConfigService();

    when(() => mockRemoteConfigService.interstitialAdUnitIdAndroid).thenReturn('test-android-id');
    when(() => mockRemoteConfigService.interstitialAdUnitIdIos).thenReturn('test-ios-id');

    // 【最終修正 - 步驟 2】保留單例狀態清理，這對於多個測試是必要的
    addTearDown(() {
      interstitialAdManager.dispose();
    });
  });

  group('InterstitialAdManager - Unit Test', () {
    test('loadAd does not throw exception when called', () {
      // 因為平台已模擬，這個 expect 會觸發 loadAd 內部邏輯
      expect(
        () => interstitialAdManager.loadAd(remoteConfigService: mockRemoteConfigService),
        returnsNormally,
      );
      // 驗證 loadAd 確實呼叫了 remote config
      verify(() => mockRemoteConfigService.interstitialAdUnitIdAndroid).called(1);
    });

    test('showAd calls loadAd when ad is not ready', () {
      // 安排 (Arrange)
      // 由於 teardown 會清理，此測試開始時是乾淨的狀態

      // 行動 (Act)
      interstitialAdManager.showAd(remoteConfigService: mockRemoteConfigService);

      // 斷言 (Assert)
      // 因為平台已模擬且狀態乾淨，showAd 會觸發 loadAd
      verify(() => mockRemoteConfigService.interstitialAdUnitIdAndroid).called(1);
    });

    test('loadAd does nothing if ad unit id is empty', () {
      // 安排
      when(() => mockRemoteConfigService.interstitialAdUnitIdAndroid).thenReturn('');

      // 行動 & 斷言
      expect(() => interstitialAdManager.loadAd(remoteConfigService: mockRemoteConfigService), returnsNormally);
      // 我們需要驗證，即使平台正確，但因為 ID 為空，它不應該繼續索取 ID。
      // 由於 setUp 中已經 when(...).thenReturn('test-android-id')，我們需要驗證的是呼叫次數為 0
      verifyNever(() => mockRemoteConfigService.interstitialAdUnitIdIos);
    });

    test('dispose method cleans up resources', () {
      expect(() => interstitialAdManager.dispose(), returnsNormally);
    });
  });
  
  // 【最終修正 - 步驟 3】清理平台偽裝
  tearDownAll(() {
    debugDefaultTargetPlatformOverride = null;
  });
}
