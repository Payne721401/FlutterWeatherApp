import 'dart:async';
import 'dart:developer';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:weatherpro/features/ai_assistant/domain/services/ai_assistant_service.dart';
import 'package:weatherpro/features/ai_assistant/domain/services/gemini_tools.dart';
import 'package:weatherpro/services/remote_config_service.dart';

class FirebaseAiService implements AiAssistantService {
  late final GenerativeModel _model;
  late final GenerativeModel _imageModel;
  late final GeminiTools _geminiTools;
  ChatSession? _chat;

  final RemoteConfigService _remoteConfigService;

  // --- MODIFICATION START ---
  // A new property to hold the system prompt content.
  String _outfitSystemPrompt = '';

  // Implement the new getter from the interface.
  @override
  String get outfitSystemPrompt => _outfitSystemPrompt;
  // --- MODIFICATION END ---

  FirebaseAiService({
    required RemoteConfigService remoteConfigService,
    required GeminiTools geminiTools,
  })  : _remoteConfigService = remoteConfigService,
        _geminiTools = geminiTools;

  @override
  Future<void> initialize() async {
    final textsystemPrompt = await rootBundle.loadString(
      'lib/features/ai_assistant/assets/prompts/weather_assistant_system_prompt.md',
    );

    // --- MODIFICATION START ---
    // Load the prompt content into the new property.
    _outfitSystemPrompt = await rootBundle.loadString(
      'lib/features/ai_assistant/assets/prompts/outfit_assistant_system_prompt.md',
    );
    // --- MODIFICATION END ---

    final modelName = _remoteConfigService.aiModelName;
    log('Using AI Model from Remote Config Service: $modelName');

    final generationConfig = GenerationConfig(
      temperature: 0.3,
      maxOutputTokens: 1024,
    );

    final googleAI = FirebaseAI.googleAI(
      auth: FirebaseAuth.instance,
      // appCheck: FirebaseAppCheck.instance
    );

    _model = googleAI.generativeModel(
      model: modelName,
      systemInstruction: Content.system(textsystemPrompt),
      tools: _geminiTools.tools,
      generationConfig: generationConfig,
    );

    final imageModelName = _remoteConfigService.aiImageModelName;
    log('Using AI Image Model from Remote Config Service: $imageModelName');
    _imageModel = googleAI.generativeModel(
      model: imageModelName,
      // systemInstruction is no longer used here as it's not supported by gemini-pro-vision.
      generationConfig: GenerationConfig(
          responseModalities: [ResponseModalities.text, ResponseModalities.image]),
    );

    resetChat();
  }

  @override
  Future<GenerateContentResponse> generateOutfitImage(String prompt) {
    return _imageModel.generateContent([Content.text(prompt)]);
  }

  @override
  Stream<GenerateContentResponse> sendMessage(String message) {
    if (_chat == null) {
      throw Exception('Chat session not initialized. Call initialize() first.');
    }
    
    final controller = StreamController<GenerateContentResponse>();

    Future<void> execute() async {
      final responseStream = _chat!.sendMessageStream(Content.text(message));

      await for (final response in responseStream) {
        controller.add(response);

        if (response.functionCalls.isNotEmpty) {
          final functionResponses = <FunctionResponse>[];
          for (final functionCall in response.functionCalls) {
            final functionResponseData =
                await _geminiTools.handleFunctionCall(functionCall.name, functionCall.args);
            functionResponses.add(
              FunctionResponse(functionCall.name, functionResponseData),
            );
          }

          final toolResponseStream = _chat!.sendMessageStream(
            Content.functionResponses(functionResponses),
          );

          await for (final toolResponse in toolResponseStream) {
            controller.add(toolResponse);
          }
        }
      }
      await controller.close();
    }

    execute().catchError((e, s) {
      controller.addError(e, s);
      controller.close();
    });

    return controller.stream;
  }


  @override
  void resetChat() {
    _chat = _model.startChat();
  }
}
