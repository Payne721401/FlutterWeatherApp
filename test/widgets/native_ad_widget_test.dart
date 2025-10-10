
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:weatherpro/features/weather/presentation/widgets/weather_card.dart';
import 'package:weatherpro/services/remote_config_service.dart';
import 'package:weatherpro/widgets/native_ad_widget.dart';

// 建立 Mock
class MockRemoteConfigService extends Mock implements RemoteConfigService {}

void main() {
  // 【最終修正】偽裝平台為 Android
  debugDefaultTargetPlatformOverride = TargetPlatform.android;

  late MockRemoteConfigService mockRemoteConfigService;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    mockRemoteConfigService = MockRemoteConfigService();
    when(() => mockRemoteConfigService.nativeAdUnitIdAndroid).thenReturn('test-android-id');
    when(() => mockRemoteConfigService.nativeAdUnitIdIos).thenReturn('test-ios-id');
  });

  Widget createTestableWidget({required Widget child}) {
    return MultiProvider(
      providers: [
        Provider<RemoteConfigService>.value(value: mockRemoteConfigService),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('NativeAdWidget - Initial State Unit Test', () {
    testWidgets('SmallNativeAd should display loading state correctly', (WidgetTester tester) async {
      // 安排 (Arrange)
      await tester.pumpWidget(createTestableWidget(child: const SmallNativeAd()));

      // 斷言 (Assert)
      expect(find.text('廣告載入中...'), findsOneWidget);
      final loadingPlaceholder = find.byType(SizedBox);
      expect(find.ancestor(of: loadingPlaceholder, matching: find.byType(WeatherCard)), findsOneWidget);
    });

    testWidgets('MediumNativeAd should display loading state correctly', (WidgetTester tester) async {
      // 安排 (Arrange)
      await tester.pumpWidget(createTestableWidget(child: const MediumNativeAd()));

      // 斷言 (Assert)
      expect(find.text('廣告載入中...'), findsOneWidget);
      final loadingPlaceholder = find.byType(SizedBox);
      expect(find.ancestor(of: loadingPlaceholder, matching: find.byType(WeatherCard)), findsOneWidget);
    });
  });

  // 【還原】清理平台偽裝
  tearDownAll(() {
    debugDefaultTargetPlatformOverride = null;
  });
}
