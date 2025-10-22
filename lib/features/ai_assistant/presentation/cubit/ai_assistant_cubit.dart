import 'dart:async';
import 'dart:convert'; // --- ADDED for jsonEncode
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data'; // --- ADDED ---
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weatherpro/services/remote_config_service.dart';
import 'package:weatherpro/services/usage_limit_service.dart';
import 'package:weatherpro/features/radar/data/services/radar_forecast_service.dart';
import 'package:weatherpro/features/weather/domain/repositories/air_quality_repository.dart';
import 'package:weatherpro/features/weather/domain/repositories/observation_repository.dart';
import 'package:weatherpro/features/weather/domain/repositories/uv_index_repository.dart';
import 'package:weatherpro/features/weather/domain/repositories/weather_forecast_repository.dart';
import 'package:weatherpro/features/weather/presentation/state/weather_data_state.dart';
import 'package:weatherpro/services/location_service.dart';
import '../../domain/services/gemini_tools.dart';
import 'ai_assistant_state.dart';
import '../../data/models/ai_message.dart';
// --- NEW IMPORT ---
// 原因: 引入我們新的抽象服務介面
import '../../domain/services/ai_assistant_service.dart';

class AiAssistantCubit extends Cubit<AiAssistantState> {
  // --- MODIFICATION START: Injecting New Service ---
  // 原因: 這是新的、抽象的依賴，Cubit 將透過它來獲取數據，使 Cubit 可被測試。
  late final AiAssistantService _aiAssistantService;
  final WeatherDataState _weatherDataState;
  WeatherDataState get weatherDataState => _weatherDataState;
  // --- MODIFICATION END ---

  /* --- OLD CODE (Commented Out) ---
  // 原因: 這些 Firebase 物件的直接互動邏輯已被移至 FirebaseAiService
  late final GenerativeModel _model;
  late GenerativeModel _imageModel; // --- ADDED ---
  late final GeminiTools _geminiTools;
  ChatSession? _chat;
  */

  final RemoteConfigService _remoteConfigService;
  final UsageLimitService _usageLimitService;

  final List<String> _quickQuestions = [
    '台北明天溫度多少?',
    '需要帶雨傘嗎?',
    '適合戶外運動嗎?',
    '紫外線指數',
  ];

  static const String _genderKey = 'ai_assistant_gender';
  static const String _ageKey = 'ai_assistant_age';
  static const String _bodyTypeKey = 'ai_assistant_body_type';
  static const String _fitPreferenceKey = 'ai_assistant_fit_preference';
  static const String _tempPreferenceKey = 'ai_assistant_temp_preference';
  static const String _latestOutfitImageFile = 'latest_outfit.png';

  // --- MODIFICATION START: New Constructor ---
  // 原因: 新的建構函式接收 AiAssistantService，並將舊依賴傳遞給它。
  // 這是過渡時期的作法，最終目標是在更高層的依賴注入容器中完成服務的組裝。
  AiAssistantCubit({
    required WeatherDataState weatherDataState,
    required ObservationRepository observationRepository,
    required UVIndexRepository uvIndexRepository,
    required AirQualityRepository airQualityRepository,
    required WeatherForecastRepository weatherForecastRepository,
    required LocationService locationService,
    required RadarForecastService radarForecastService,
    required RemoteConfigService remoteConfigService,
    required UsageLimitService usageLimitService,
    required AiAssistantService aiAssistantService, // Added new service
  })  : _weatherDataState = weatherDataState,
        _remoteConfigService = remoteConfigService,
        _usageLimitService = usageLimitService,
        _aiAssistantService = aiAssistantService, // Assigned new service
        super(const AiAssistantState()) {
    /* --- OLD CODE (Commented Out) ---
    _geminiTools = GeminiTools(
      weatherDataState: weatherDataState,
      observationRepository: observationRepository,
      uvIndexRepository: uvIndexRepository,
      airQualityRepository: airQualityRepository,
      weatherForecastRepository: weatherForecastRepository,
      locationService: locationService,
      radarForecastService: radarForecastService,
    );
    */
    // MODIFICATION: Removed `_initialize()` call to prevent race conditions.
  }
  // --- MODIFICATION END ---

  Future<String> _getLatestOutfitImagePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_latestOutfitImageFile';
  }

  // MODIFICATION: Renamed to public `initialize` and removed `_`.
  Future<void> initialize() async {
    try {
      try {
        final imagePath = await _getLatestOutfitImagePath();
        final imageFile = File(imagePath);
        if (await imageFile.exists()) {
          final imageBytes = await imageFile.readAsBytes();
          emit(state.copyWith(generatedImageBytes: imageBytes));
          log('Successfully loaded latest outfit image from disk.');
        }
      } catch (e) {
        log('Failed to load outfit image from disk: $e');
      }

      await _loadPersonalizationSettings();

      // --- MODIFICATION START: Delegating Initialization ---
      // 原因: 初始化邏輯現在被委派給 AiAssistantService，Cubit 只需呼叫它。
      await _aiAssistantService.initialize();
      // --- MODIFICATION END ---

      /* --- OLD CODE (Commented Out) --
      // 原因: 這整段 Firebase 物件的初始化邏輯，已完整搬移至 FirebaseAiService
      final systemPrompt = await rootBundle.loadString(
        'lib/features/ai_assistant/assets/prompts/weather_assistant_system_prompt.md',
      );

      final modelName = _remoteConfigService.aiModelName;
      log('Using AI Model from Remote Config Service: $modelName');

      final generationConfig = GenerationConfig(
        temperature: 0.3,
        maxOutputTokens: 1024,
      );

      final googleAI = FirebaseAI.googleAI(
        auth: FirebaseAuth.instance,
        appCheck: FirebaseAppCheck.instance,
      );

      _model = googleAI.generativeModel(
        model: modelName,
        systemInstruction: Content.system(systemPrompt),
        tools: _geminiTools.tools,
        generationConfig: generationConfig,
      );
      _chat = _model.startChat();
      
      // --- ADDED START ---
      final imageModelName = _remoteConfigService.aiImageModelName;
      log('Using AI Image Model from Remote Config Service: $imageModelName');
      _imageModel = googleAI.generativeModel(
        model: imageModelName,
        generationConfig: GenerationConfig(
            responseModalities: [ResponseModalities.text, ResponseModalities.image]
        ),
      );
      // --- ADDED END ---
      */

      final welcomeMessage = MessageData(
        text: '''
歡迎使用AI天氣小幫手！我可以為您提供：
- **即時天氣狀況**：查詢現在氣溫、濕度、風速等。
- **未來天氣預報**：提供未來一週及3天每3小時預報。
- **空氣品質**：查詢AQI指數與等級。
- **紫外線指數**：提供縣在紫外線強度與曝曬建議。
- **未來一小時降雨**：根據雷達回波，預測接下來60分鐘的降雨情形。

直接告訴我想了解什麼，或者點點下方的快捷問題吧！ 👇
''',
        fromUser: false,
      );

      emit(
        state.copyWith(
          status: AiAssistantStatus.success,
          messages: [welcomeMessage],
          quickReplies: _quickQuestions,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AiAssistantStatus.failure,
          error: '初始化失敗: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _loadPersonalizationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    emit(state.copyWith(
      selectedGender: prefs.getString(_genderKey),
      userAge: prefs.getString(_ageKey),
      selectedBodyType: prefs.getString(_bodyTypeKey),
      selectedFitPreference: prefs.getString(_fitPreferenceKey),
      selectedTempPreference: prefs.getString(_tempPreferenceKey),
    ));
  }

  /* --- OLD CODE (Commented Out) ---
  // 原因: 這些方法現在已過時，因為我們可以 mock AiAssistantService 本身，不再需要手動注入 final class 的實例。
  // --- ADDED START ---
  @visibleForTesting
  void setImageModelForTest(GenerativeModel model) {
    _imageModel = model;
  }

  @visibleForTesting
  void setChatSessionForTest(ChatSession chat) {
    _chat = chat;
  }
  // --- ADDED END ---
  */

  // --- NEW CODE START: Methods for Outfit & Personalization Settings ---

  void selectScene(String scene) => emit(state.copyWith(selectedScene: scene, customScene: ''));
  void setCustomScene(String scene) => emit(state.copyWith(customScene: scene));
  void selectStyle(String style) => emit(state.copyWith(selectedStyle: style, customStyle: ''));
  void setCustomStyle(String style) => emit(state.copyWith(customStyle: style));
  void selectGender(String gender) => emit(state.copyWith(selectedGender: gender));
  void setUserAge(String ageString) => emit(state.copyWith(userAge: ageString));
  void selectBodyType(String bodyType) => emit(state.copyWith(selectedBodyType: bodyType));
  void selectFitPreference(String fit) => emit(state.copyWith(selectedFitPreference: fit));
  void selectTempPreference(String temp) => emit(state.copyWith(selectedTempPreference: temp));

  Future<void> savePersonalizationSettings() async {
    log("Personalization settings save requested.");
    final prefs = await SharedPreferences.getInstance();
    if (state.selectedGender != null) await prefs.setString(_genderKey, state.selectedGender!);
    if (state.userAge != null) await prefs.setString(_ageKey, state.userAge!);
    if (state.selectedBodyType != null) await prefs.setString(_bodyTypeKey, state.selectedBodyType!);
    if (state.selectedFitPreference != null) await prefs.setString(_fitPreferenceKey, state.selectedFitPreference!);
    if (state.selectedTempPreference != null) await prefs.setString(_tempPreferenceKey, state.selectedTempPreference!);
    log("Personalization settings saved.");
  }

  String _buildOutfitPrompt() {
    final finalStyle = state.customStyle.isNotEmpty ? state.customStyle : state.selectedStyle;
    final finalScene = state.customScene.isNotEmpty ? state.customScene : state.selectedScene;

    // Placeholder values as discussed. TODO: Integrate with WeatherDataState later.
    final location = _weatherDataState.currentLocationName ?? '未知地點';
    final temperature = _weatherDataState.temperature?.round().toString() ?? '未知溫度';
    final weatherCondition = _weatherDataState.condition ?? '未知天氣';

    final promptData = {
      "location": location,
      "temperature": temperature,
      "weather_condition": weatherCondition,
      "gender": state.selectedGender ?? "女性",
      "age_group": state.userAge ?? "青年",
      "style": '$finalScene $finalStyle',
      "body_type": state.selectedBodyType,
      "fit_preference": state.selectedFitPreference,
      "temperature_preference": state.selectedTempPreference,
    };

    promptData.removeWhere((key, value) => value == null);
    return jsonEncode(promptData);
  }

  // --- NEW CODE END ---

  // --- MODIFICATION of existing generateOutfitImage method ---

  Future<void> generateOutfitImage() async {
    // --- MODIFICATION START: Validate personalization settings ---
    if (state.selectedGender == null ||
        state.userAge == null || state.userAge!.isEmpty ||
        state.selectedBodyType == null ||
        state.selectedFitPreference == null ||
        state.selectedTempPreference == null) {
      emit(state.copyWith(
        imageGenerationStatus: ImageGenerationStatus.failure,
        imageGenerationError: '請先完成所有個人化設定',
      ));
      return;
    }
    
    emit(state.copyWith(
      imageGenerationStatus: ImageGenerationStatus.loading,
      generatedImageBytes: null,
      imageGenerationError: null,
    ));

    try {
      // MODIFICATION: Simplified error handling by removing nested try-catch.
      await _usageLimitService.runProtectedImageAction(() async {
        
        // --- GA LOG EVENT START ---
        final analyticsParameters = {
          'scene': state.customScene.isNotEmpty ? state.customScene : state.selectedScene,
          'style': state.customStyle.isNotEmpty ? state.customStyle : state.selectedStyle,
          'gender': state.selectedGender,
          'age': state.userAge,
          'body_type': state.selectedBodyType,
          'fit_preference': state.selectedFitPreference,
          'temp_preference': state.selectedTempPreference,
        };
        analyticsParameters.removeWhere((key, value) => value == null || value.isEmpty);
        FirebaseAnalytics.instance.logEvent(
          name: 'ai_outfit_generate',
          parameters: analyticsParameters.map((key, value) => MapEntry(key, value.toString())),
        );
        // --- GA LOG EVENT END ---

        // --- MINIMAL MODIFICATION START ---
        // Combine the system prompt from the service with the user-specific data.
        final systemPrompt = _aiAssistantService.outfitSystemPrompt;
        final userPrompt = _buildOutfitPrompt();
        final fullPrompt = '$systemPrompt\n\n$userPrompt';
        log("Generated Full Outfit Prompt: $fullPrompt");
        
        final response = await _aiAssistantService.generateOutfitImage(fullPrompt);
        // --- MINIMAL MODIFICATION END ---

        if (response.inlineDataParts.isNotEmpty) {
          final imageBytes = response.inlineDataParts.first.bytes;

          try {
            final imagePath = await _getLatestOutfitImagePath();
            await File(imagePath).writeAsBytes(imageBytes);
            log('Successfully saved latest outfit image to disk.');
          } catch (e) {
            log('Failed to save outfit image to disk: $e');
          }

          emit(state.copyWith(
            imageGenerationStatus: ImageGenerationStatus.success,
            generatedImageBytes: imageBytes,
          ));
        } else {
          throw Exception('API did not return an image.');
        }
      });
    } on UsageLimitException catch (e) {
      log('Image generation usage limit exceeded: ${e.toString()}');
      emit(state.copyWith(
        imageGenerationStatus: ImageGenerationStatus.failure,
        imageGenerationError: e.message,
      ));
    } catch (e) {
      log('Image generation general error: ${e.toString()}');
      emit(state.copyWith(
        imageGenerationStatus: ImageGenerationStatus.failure,
        imageGenerationError: '圖片生成失敗，請稍後再試。',
      ));
    }
  }
  // --- MODIFICATION END ---

  Future<void> sendMessage(String messageText) async {
    
    // --- GA LOG EVENT START ---
    final isQuickReply = _quickQuestions.contains(messageText);
    FirebaseAnalytics.instance.logEvent(
      name: 'ai_chat_query',
      parameters: {
        'query_text': messageText.length > 100 ? messageText.substring(0, 100) : messageText,
        'query_length': messageText.length,
        'source': isQuickReply ? 'quick_reply' : 'manual_input',
      },
    );
    // --- GA LOG EVENT END ---

    emit(state.copyWith(quickReplies: []));

    // --- MODIFICATION START ---
    // if (messageText.isEmpty || _chat == null || state.status == AiAssistantStatus.loading) return;
    // 原因: _chat 物件已移至 Service 層，Cubit 不再需要檢查它是否為 null。
    if (messageText.isEmpty || state.status == AiAssistantStatus.loading) return;
    // --- MODIFICATION END ---

    final userMessage = MessageData(text: messageText, fromUser: true);

    emit(
      state.copyWith(
        status: AiAssistantStatus.loading,
        messages: [...state.messages, userMessage],
      ),
    );

    final aiMessagePlaceholder = MessageData(
      text: '',
      fromUser: false,
      isTyping: true,
    );
    emit(state.copyWith(messages: [...state.messages, aiMessagePlaceholder]));
    final aiMessageIndex = state.messages.length - 1;

    try {
      await _usageLimitService.runProtectedAiAction(() async {
        try {
          // --- MODIFICATION START: Delegating Data Fetching ---
          // 原因: 獲取 streaming response 的邏輯現在委派給 AiAssistantService。
          final responseStream = _aiAssistantService.sendMessage(messageText);
          /* --- OLD CODE (Commented Out) ---
          final responseStream = _chat!.sendMessageStream(
            Content.text(messageText),
          );
          */
          // --- MODIFICATION END ---
          
          StringBuffer responseBuffer = StringBuffer();

          await for (final response in responseStream) {
            if (response.text != null) {
              responseBuffer.write(response.text);
              final updatedMessages = List<MessageData>.from(state.messages);
              // BUG FIX: Added boundary check to prevent RangeError.
              if (aiMessageIndex < updatedMessages.length) {
                updatedMessages[aiMessageIndex] = updatedMessages[aiMessageIndex].copyWith(text: responseBuffer.toString());
                emit(state.copyWith(messages: updatedMessages));
              }
            }

            /* --- OLD CODE (Commented Out) ---
            // 原因: 處理 function call 的往返邏輯已完整封裝在 FirebaseAiService 中。
            // Cubit 現在只需要處理最終的文字流即可，職責更單純。
            if (response.functionCalls.isNotEmpty) {
              final functionResponses = <FunctionResponse>[];
              for (final functionCall in response.functionCalls) {
                final functionResponseData = await _geminiTools.handleFunctionCall(functionCall.name, functionCall.args);
                functionResponses.add(
                  FunctionResponse(functionCall.name, functionResponseData),
                );
              }

              final toolResponseStream = _chat!.sendMessageStream(
                Content.functionResponses(functionResponses),
              );

              await for (final toolResponse in toolResponseStream) {
                if (toolResponse.text != null) {
                  responseBuffer.write(toolResponse.text);
                  final updatedMessages = List<MessageData>.from(
                    state.messages,
                  );
                  updatedMessages[aiMessageIndex] = updatedMessages[aiMessageIndex].copyWith(
                    text: responseBuffer.toString(),
                  );
                  emit(state.copyWith(messages: updatedMessages));
                }
              }
            }
            */
          }
          
          // BUG FIX: Logic moved from `finally` to the end of a successful try block.
          final finalMessages = List<MessageData>.from(state.messages);
          if (aiMessageIndex < finalMessages.length) {
            finalMessages[aiMessageIndex] = finalMessages[aiMessageIndex].copyWith(isTyping: false);
          }
          emit(
            state.copyWith(
              status: AiAssistantStatus.success,
              messages: finalMessages,
            ),
          );

        } catch (e) {
          log('AI chat error inside runProtectedAiAction: ${e.toString()}');
          const errorMessage = '抱歉，目前無法連線至服務，請稍後再試。';

          final updatedMessages = List<MessageData>.from(state.messages);
          // BUG FIX: Added boundary check to prevent RangeError.
          if (aiMessageIndex < updatedMessages.length) {
            updatedMessages[aiMessageIndex] = updatedMessages[aiMessageIndex].copyWith(text: errorMessage, isTyping: false);
          }
          emit(
            state.copyWith(
              status: AiAssistantStatus.failure,
              messages: updatedMessages,
              error: e.toString(),
            ),
          );
        }
        // BUG FIX: Removed the incorrect `finally` block that was here.
      });
    } on UsageLimitException catch (e) {
      final updatedMessages = List<MessageData>.from(state.messages);
      // BUG FIX: Added boundary check to prevent RangeError.
      if (aiMessageIndex < updatedMessages.length) {
        updatedMessages[aiMessageIndex] = updatedMessages[aiMessageIndex].copyWith(text: e.message, isTyping: false);
      }
      emit(
        state.copyWith(
          status: AiAssistantStatus.failure,
          messages: updatedMessages,
          error: e.toString(),
        ),
      );
    } catch (e, s) { // <-- 在 catch 中增加 ", s"
      log('AI chat error. Type: ${e.runtimeType.toString()}', error: e, stackTrace: s);
      const errorMessage = '抱歉，目前無法連線至服務，請稍後再試。';

      final updatedMessages = List<MessageData>.from(state.messages);
      // BUG FIX: Added boundary check to prevent RangeError.
      if (aiMessageIndex < updatedMessages.length) {
        updatedMessages[aiMessageIndex] = updatedMessages[aiMessageIndex].copyWith(text: errorMessage, isTyping: false);
      }
      emit(
        state.copyWith(
          status: AiAssistantStatus.failure,
          messages: updatedMessages,
          error: e.toString(),
        ),
      );
    }
  }
}
