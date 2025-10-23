import 'dart:async';
import 'dart:typed_data';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weatherpro/features/ai_assistant/data/models/ai_message.dart';
import 'package:weatherpro/features/ai_assistant/domain/services/ai_assistant_service.dart';
import 'package:weatherpro/features/ai_assistant/presentation/cubit/ai_assistant_cubit.dart';
import 'package:weatherpro/features/ai_assistant/presentation/cubit/ai_assistant_state.dart';
import 'package:weatherpro/services/remote_config_service.dart';
import 'package:weatherpro/services/usage_limit_service.dart';
import 'package:weatherpro/features/weather/presentation/state/weather_data_state.dart';
import 'package:weatherpro/features/weather/domain/repositories/observation_repository.dart';
import 'package:weatherpro/features/weather/domain/repositories/uv_index_repository.dart';
import 'package:weatherpro/features/weather/domain/repositories/air_quality_repository.dart';
import 'package:weatherpro/features/weather/domain/repositories/weather_forecast_repository.dart';
import 'package:weatherpro/services/location_service.dart';
import 'package:weatherpro/features/radar/data/services/radar_forecast_service.dart';

// --- MOCKS ---
class MockAiAssistantService extends Mock implements AiAssistantService {}
class MockRemoteConfigService extends Mock implements RemoteConfigService {}
class MockUsageLimitService extends Mock implements UsageLimitService {}
class MockWeatherDataState extends Mock implements WeatherDataState {}
class MockObservationRepository extends Mock implements ObservationRepository {}
class MockUVIndexRepository extends Mock implements UVIndexRepository {}
class MockAirQualityRepository extends Mock implements AirQualityRepository {}
class MockWeatherForecastRepository extends Mock implements WeatherForecastRepository {}
class MockLocationService extends Mock implements LocationService {}
class MockRadarForecastService extends Mock implements RadarForecastService {}

void main() {
  // MODIFICATION: Initialize the binding for tests that use platform channels.
  TestWidgetsFlutterBinding.ensureInitialized();

  // --- MOCKS INSTANTIATION ---
  late MockAiAssistantService mockAiAssistantService;
  late MockRemoteConfigService mockRemoteConfigService;
  late MockUsageLimitService mockUsageLimitService;
  late MockWeatherDataState mockWeatherDataState;
  late MockObservationRepository mockObservationRepository;
  late MockUVIndexRepository mockUVIndexRepository;
  late MockAirQualityRepository mockAirQualityRepository;
  late MockWeatherForecastRepository mockWeatherForecastRepository;
  late MockLocationService mockLocationService;
  late MockRadarForecastService mockRadarForecastService;

  // --- TEST DATA ---
  final testImageBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
  const testMessage = 'Hello, Assistant!';
  const testApiResponse = 'Hello there! How can I help you?';
  final usageLimitException = UsageLimitException('已達今日上限');

  // --- Reusable Matcher for the initial welcome message ---
  final Matcher emitsWelcomeMessage = isA<AiAssistantState>()
      .having((s) => s.status, 'status', AiAssistantStatus.success)
      .having((s) => s.messages.first.text, 'message text', contains('歡迎使用AI天氣小幫手'))
      .having((s) => s.quickReplies, 'quickReplies', isNotEmpty);

  setUp(() {
    // MODIFICATION: Mock SharedPreferences to use in-memory values for tests.
    SharedPreferences.setMockInitialValues({});

    mockAiAssistantService = MockAiAssistantService();
    mockRemoteConfigService = MockRemoteConfigService();
    mockUsageLimitService = MockUsageLimitService();
    mockWeatherDataState = MockWeatherDataState();
    mockObservationRepository = MockObservationRepository();
    mockUVIndexRepository = MockUVIndexRepository();
    mockAirQualityRepository = MockAirQualityRepository();
    mockWeatherForecastRepository = MockWeatherForecastRepository();
    mockLocationService = MockLocationService();
    mockRadarForecastService = MockRadarForecastService();

    // Default stub for successful initialization
    when(() => mockAiAssistantService.initialize()).thenAnswer((_) async {});
    when(() => mockAiAssistantService.outfitSystemPrompt).thenReturn('A test system prompt');

    // Default stubs for services
    when(() => mockRemoteConfigService.aiImageModelName).thenReturn('gemini-test-model');
    when(() => mockRemoteConfigService.aiModelName).thenReturn('gemini-pro');

    // Default stub for usage limit service to pass through the action
    when(() => mockUsageLimitService.runProtectedImageAction(any()))
        .thenAnswer((invocation) async {
      final function = invocation.positionalArguments.first as Future<void> Function();
      await function();
    });
    when(() => mockUsageLimitService.runProtectedAiAction(any()))
        .thenAnswer((invocation) async {
      final function = invocation.positionalArguments.first as Future<void> Function();
      await function();
    });
  });

  // Helper function to build the cubit with all mocked dependencies
  AiAssistantCubit buildCubit() {
    return AiAssistantCubit(
      remoteConfigService: mockRemoteConfigService,
      usageLimitService: mockUsageLimitService,
      weatherDataState: mockWeatherDataState,
      observationRepository: mockObservationRepository,
      uvIndexRepository: mockUVIndexRepository,
      airQualityRepository: mockAirQualityRepository,
      weatherForecastRepository: mockWeatherForecastRepository,
      locationService: mockLocationService,
      radarForecastService: mockRadarForecastService,
      aiAssistantService: mockAiAssistantService,
    );
  }

  group('AiAssistantCubit - Initialization', () {
    blocTest<AiAssistantCubit, AiAssistantState>(
      'emits welcome message on success',
      build: buildCubit,
      act: (cubit) => cubit.initialize(),
      skip: 1, // MODIFICATION: Skip the initial state.
      expect: () => <Matcher>[emitsWelcomeMessage],
      verify: (_) {
        verify(() => mockAiAssistantService.initialize()).called(1);
      },
    );

    blocTest<AiAssistantCubit, AiAssistantState>(
      'emits failure state when AiAssistantService.initialize throws an exception',
      setUp: () {
        when(() => mockAiAssistantService.initialize()).thenThrow(Exception('Init failed'));
      },
      build: buildCubit,
      act: (cubit) => cubit.initialize(),
      skip: 1, // MODIFICATION: Skip the initial state.
      expect: () => <Matcher>[
        isA<AiAssistantState>()
            .having((s) => s.status, 'status', AiAssistantStatus.failure)
            .having((s) => s.error, 'error', contains('初始化失敗')),
      ],
      verify: (_) {
         verify(() => mockAiAssistantService.initialize()).called(1);
      }
    );
  });

  group('AiAssistantCubit - generateOutfitImage', () {
    blocTest<AiAssistantCubit, AiAssistantState>(
      'emits [welcome, loading, success] when image generation is successful',
      setUp: () {
        final realPart = InlineDataPart('image/png', testImageBytes);
        final content = Content('model', [realPart]);
        final candidate = Candidate(content, null, null, null, null);
        final realResponse = GenerateContentResponse([candidate], null);
        when(() => mockAiAssistantService.generateOutfitImage(any())).thenAnswer((_) async => realResponse);
      },
      build: buildCubit,
      act: (cubit) async {
        await cubit.initialize();
        cubit.selectGender('女性');
        cubit.setUserAge('青年');
        cubit.selectBodyType('標準');
        cubit.selectFitPreference('合身');
        cubit.selectTempPreference('適中');
        await cubit.generateOutfitImage();
      },
      skip: 1, 
      expect: () => <Matcher>[
        emitsWelcomeMessage,
        isA<AiAssistantState>().having((s) => s.selectedGender, 'gender', '女性'),
        isA<AiAssistantState>().having((s) => s.userAge, 'age', '青年'),
        isA<AiAssistantState>().having((s) => s.selectedBodyType, 'bodyType', '標準'),
        isA<AiAssistantState>().having((s) => s.selectedFitPreference, 'fit', '合身'),
        isA<AiAssistantState>().having((s) => s.selectedTempPreference, 'temp', '適中'),
        isA<AiAssistantState>().having((s) => s.imageGenerationStatus, 'status', ImageGenerationStatus.loading),
        isA<AiAssistantState>()
            .having((s) => s.imageGenerationStatus, 'status', ImageGenerationStatus.success)
            .having((s) => s.generatedImageBytes, 'bytes', testImageBytes),
      ],
      verify: (_) {
        verify(() => mockUsageLimitService.runProtectedImageAction(any())).called(1);
        verify(() => mockAiAssistantService.generateOutfitImage(any())).called(1);
      },
    );

    blocTest<AiAssistantCubit, AiAssistantState>(
      'emits [welcome, loading, failure] when UsageLimitException is thrown',
      setUp: () {
        when(() => mockUsageLimitService.runProtectedImageAction(any())).thenThrow(usageLimitException);
      },
      build: buildCubit,
      act: (cubit) async {
        await cubit.initialize();
        cubit.selectGender('女性');
        cubit.setUserAge('青年');
        cubit.selectBodyType('標準');
        cubit.selectFitPreference('合身');
        cubit.selectTempPreference('適中');
        await cubit.generateOutfitImage();
      },
      skip: 1, 
      expect: () => <Matcher>[
        emitsWelcomeMessage,
        isA<AiAssistantState>().having((s) => s.selectedGender, 'gender', '女性'),
        isA<AiAssistantState>().having((s) => s.userAge, 'age', '青年'),
        isA<AiAssistantState>().having((s) => s.selectedBodyType, 'bodyType', '標準'),
        isA<AiAssistantState>().having((s) => s.selectedFitPreference, 'fit', '合身'),
        isA<AiAssistantState>().having((s) => s.selectedTempPreference, 'temp', '適中'),
        isA<AiAssistantState>().having((s) => s.imageGenerationStatus, 'status', ImageGenerationStatus.loading),
        isA<AiAssistantState>()
            .having((s) => s.imageGenerationStatus, 'status', ImageGenerationStatus.failure)
            .having((s) => s.imageGenerationError, 'error', usageLimitException.message),
      ],
      verify: (_) {
        verifyNever(() => mockAiAssistantService.generateOutfitImage(any()));
      },
    );

    blocTest<AiAssistantCubit, AiAssistantState>(
      'emits [welcome, loading, failure] when the API call fails',
      setUp: () {
        when(() => mockAiAssistantService.generateOutfitImage(any())).thenThrow(Exception('API Error'));
      },
      build: buildCubit,
       act: (cubit) async {
        await cubit.initialize();
        cubit.selectGender('女性');
        cubit.setUserAge('青年');
        cubit.selectBodyType('標準');
        cubit.selectFitPreference('合身');
        cubit.selectTempPreference('適中');
        await cubit.generateOutfitImage();
      },
      skip: 1, 
      expect: () => <Matcher>[
        emitsWelcomeMessage,
        isA<AiAssistantState>().having((s) => s.selectedGender, 'gender', '女性'),
        isA<AiAssistantState>().having((s) => s.userAge, 'age', '青年'),
        isA<AiAssistantState>().having((s) => s.selectedBodyType, 'bodyType', '標準'),
        isA<AiAssistantState>().having((s) => s.selectedFitPreference, 'fit', '合身'),
        isA<AiAssistantState>().having((s) => s.selectedTempPreference, 'temp', '適中'),
        isA<AiAssistantState>().having((s) => s.imageGenerationStatus, 'status', ImageGenerationStatus.loading),
        isA<AiAssistantState>()
            .having((s) => s.imageGenerationStatus, 'status', ImageGenerationStatus.failure)
            .having((s) => s.imageGenerationError, 'error', '圖片生成失敗，請稍後再試。'),
      ],
    );
  });

  group('AiAssistantCubit - sendMessage', () {
    blocTest<AiAssistantCubit, AiAssistantState>(
      'emits with correct message flow on successful API call',
      setUp: () {
        final responseStream = Stream.fromIterable([
          GenerateContentResponse([Candidate(Content('model', [TextPart('Hello ')]), null, null, null, null)], null),
          GenerateContentResponse([Candidate(Content('model', [TextPart('there! How can I help you?')]), null, null, null, null)], null),
        ]);
        when(() => mockAiAssistantService.sendMessage(any())).thenAnswer((_) => responseStream);
      },
      build: buildCubit,
      act: (cubit) async {
        await cubit.initialize();
        await cubit.sendMessage(testMessage);
      },
      skip: 1, 
      expect: () => <Matcher>[
        emitsWelcomeMessage,
        isA<AiAssistantState>().having((s) => s.quickReplies, 'quickReplies', isEmpty),
        isA<AiAssistantState>()
          .having((s) => s.status, 'status', AiAssistantStatus.loading)
          .having((s) => s.messages.last, 'last message', const MessageData(text: testMessage, fromUser: true)),
        isA<AiAssistantState>().having((s) => s.messages.last, 'typing message', const MessageData(text: '', fromUser: false, isTyping: true)),
        isA<AiAssistantState>().having((s) => s.messages.last.text, 'streaming text 1', 'Hello '),
        isA<AiAssistantState>().having((s) => s.messages.last.text, 'streaming text 2', testApiResponse),
        isA<AiAssistantState>()
          .having((s) => s.status, 'final status', AiAssistantStatus.success)
          .having((s) => s.messages.last, 'final message', const MessageData(text: testApiResponse, fromUser: false, isTyping: false)),
      ],
      verify: (_) {
        verify(() => mockUsageLimitService.runProtectedAiAction(any())).called(1);
        final captured = verify(() => mockAiAssistantService.sendMessage(captureAny())).captured;
        expect(captured.first, testMessage);
      },
    );

    blocTest<AiAssistantCubit, AiAssistantState>(
      'emits failure when UsageLimitException is thrown',
      setUp: () {
        when(() => mockUsageLimitService.runProtectedAiAction(any())).thenThrow(usageLimitException);
      },
      build: buildCubit,
      act: (cubit) async {
        await cubit.initialize();
        await cubit.sendMessage(testMessage);
      },
      skip: 1, 
      expect: () => <Matcher>[
        emitsWelcomeMessage,
        isA<AiAssistantState>().having((s) => s.quickReplies, 'quickReplies', isEmpty),
        isA<AiAssistantState>().having((s) => s.status, 'status', AiAssistantStatus.loading),
        isA<AiAssistantState>().having((s) => s.messages.last, 'typing message', const MessageData(text: '', fromUser: false, isTyping: true)),
        isA<AiAssistantState>()
            .having((s) => s.status, 'status', AiAssistantStatus.failure)
            .having((s) => s.messages.last.text, 'error message', usageLimitException.message),
      ],
       verify: (_) {
        verify(() => mockUsageLimitService.runProtectedAiAction(any())).called(1);
        verifyNever(() => mockAiAssistantService.sendMessage(any()));
      },
    );

    blocTest<AiAssistantCubit, AiAssistantState>(
      'emits failure when API call fails',
      setUp: () {
        when(() => mockAiAssistantService.sendMessage(any())).thenThrow(Exception('API Error'));
      },
      build: buildCubit,
      act: (cubit) async {
        await cubit.initialize();
        await cubit.sendMessage(testMessage);
      },
      skip: 1, 
      expect: () => <Matcher>[
        emitsWelcomeMessage,
        isA<AiAssistantState>().having((s) => s.quickReplies, 'quickReplies', isEmpty),
        isA<AiAssistantState>().having((s) => s.status, 'status', AiAssistantStatus.loading),
        isA<AiAssistantState>().having((s) => s.messages.last, 'typing message', const MessageData(text: '', fromUser: false, isTyping: true)),
        isA<AiAssistantState>()
            .having((s) => s.status, 'status', AiAssistantStatus.failure)
            .having((s) => s.messages.last.text, 'error message', '抱歉，目前無法連線至服務，請稍後再試。'),
      ],
    );
  });
}
