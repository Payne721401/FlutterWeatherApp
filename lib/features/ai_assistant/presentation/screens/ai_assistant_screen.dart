import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert'; // For JSON decoding

import '../../../ai_assistant/data/models/ai_message.dart';
import '../../../ai_assistant/presentation/widgets/message_widget.dart';
import '../../../ai_assistant/presentation/widgets/quick_questions_panel.dart';
import '../../../ai_assistant/presentation/widgets/message_input_bar.dart';
import '../../../ai_assistant/presentation/widgets/error_alert_dialog.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _textFieldFocus = FocusNode();
  final List<MessageData> _messages = <MessageData>[];
  bool _loading = false;
  bool _showQuickQuestions = true; // New state variable for quick questions visibility

  late final GenerativeModel _model;
  ChatSession? _chat;

  final List<String> _quickQuestions = [
    '台北明天溫度多少?',
    '需要帶雨傘嗎?',
    '適合戶外運動嗎?',
    '紫外線指數',
  ];

  // Define the overall AI response JSON Schema
  final jsonSchema = Schema(
    SchemaType.object,
    properties: {
      'response_type': Schema(
        SchemaType.string,
        description: 'The type of response: "text_response" for general text, or "weather_report" for weather data.',
        enumValues: ['text_response', 'weather_report'],
      ),
      'text_content': Schema(
        SchemaType.string,
        description: 'The textual content of the response, used when response_type is "text_response".',
      ),
      'weather_report': Schema(
        SchemaType.object,
        description: 'Structured weather information, including general forecast, UV info, and clothing advice.',
        properties: {
          'general_forecast': Schema(
            SchemaType.object,
            description: 'General weather forecast information.',
            properties: {
              'location': Schema(SchemaType.string, description: 'The location for the weather report.'),
              'date': Schema(SchemaType.string, description: 'The date of the forecast (e.g., "4月15日 星期二").'),
              'condition_icon': Schema(SchemaType.string, description: 'URL or identifier for weather condition icon (e.g., "sunny", "cloudy", "rainy").'),
              'condition_description': Schema(SchemaType.string, description: 'A brief description of the weather condition (e.g., "晴朗", "陰天", "陣雨").'),
              'high_temperature': Schema(SchemaType.number, description: 'The high temperature in Celsius.'),
              'low_temperature': Schema(SchemaType.number, description: 'The low temperature in Celsius.'),
              'temperature_change_advice': Schema(SchemaType.string, description: 'Advice related to temperature changes (e.g., "日夜溫差大，早晚請適時增減衣物").'),
              'precipitation_chance': Schema(SchemaType.string, description: 'Chance of precipitation (e.g., "0-5%", "30-50%").'),
              'wind_direction_speed': Schema(SchemaType.string, description: 'Wind direction and speed (e.g., "東北風 微風").'),
              'data_source': Schema(SchemaType.string, description: 'Source of weather data (e.g., "Yahoo天氣").'),
              'data_update_time': Schema(SchemaType.string, description: 'Last update time of weather data (e.g., "2025年4月14日").'),
            },
          ),
          'uv_info': Schema(
            SchemaType.object,
            description: 'Ultraviolet (UV) index information and advice.',
            properties: {
              'uv_index': Schema(SchemaType.number, description: 'The UV index.'),
              'uv_description': Schema(SchemaType.string, description: 'Description of the UV level (e.g., "低量級", "中量級", "高量級").'),
              'uv_advice': Schema(SchemaType.string, description: 'Specific advice for the UV level (e.g., "建議戶外活動時戴帽、撐傘、擦防曬乳").'),
            },
          ),
          'clothing_advice': Schema(
            SchemaType.object,
            description: 'Clothing advice based on weather conditions.',
            properties: {
              'advice_text': Schema(SchemaType.string, description: 'General clothing advice.'),
              'items': Schema(
                SchemaType.array,
                items: Schema(SchemaType.string),
                description: 'List of recommended clothing items (e.g., ["薄外套", "短袖", "長褲"]).',
              ),
            },
          ),
        },
      ),
    },
  );


  @override
  void initState() {
    super.initState();
    _addWelcomeMessage(); // Add welcome message on init
    var googleAI = FirebaseAI.googleAI(auth: FirebaseAuth.instance);
    _model = googleAI.generativeModel(
      model: 'gemini-2.0-flash-lite',
      systemInstruction: Content.system(
        """
            你是一個專業的天氣應用程式的AI助手，旨在提供準確簡潔的天ableration相關資訊。
            只回答與天氣相關的問題。
            如果問題與天氣無關，你必須將 response_type 設為 "text_response"，並將 text_content 設為 "這不是天氣相關的問題，請重新輸入天氣資訊。"。
            當使用者的意圖是獲取天氣報告或天氣預報時，你必須將 response_type 設為 "weather_report"。
            當 response_type 是 "weather_report" 時，你應該根據使用者的具體要求，**只填寫 weather_report 物件中相關的子物件（general_forecast、uv_info、clothing_advice），並且提供真實具體的值。不相關的子物件請完全省略，不要回傳空物件或帶有佔位符的物件。**
            例如，如果使用者問紫外線指數，你只填寫 uv_info，並確保所有 required 欄位都有真實數據。
            如果使用者問明天天氣，你只填寫 general_forecast，並確保所有 required 欄位都有真實數據。
            如果使用者問穿搭建議，你只填寫 clothing_advice，並確保所有 required 欄位都有真實數據。
            如果使用者問一般天氣預報，你填寫 general_forecast，並確保所有 required 欄位都有真實數據。
            回應的語言（繁體中文或英文）應與使用者的輸入語言相符。
            保持回應簡潔、專業，並專注於氣象準確性。
            condition_icon 欄位請填寫如 "sunny", "cloudy", "rainy", "partly_cloudy" 等描述性字串，用於前端顯示對應的圖示。
        """
      ),
       generationConfig: GenerationConfig(
            responseMimeType: 'application/json', responseSchema: jsonSchema),
    );
    _chat = _model.startChat();
  }

  void _addWelcomeMessage() {
    _messages.add(
      MessageData(
        text: '歡迎使用AI天氣小幫手！我可以為您提供即時天氣資訊、預報分析和個人化建議。試試點擊上方的快速按鈕，或直接告訴我想了解什麼天氣資訊吧! ✨',
        fromUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _textFieldFocus.dispose();
    super.dispose();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeOutCirc,
      ),
    );
  }

  Future<void> _sendMessage({String? predefinedMessage}) async {
    final userMessage = predefinedMessage ?? _messageController.text;
    if (userMessage.isEmpty) return;

    setState(() {
      _messages.add(MessageData(text: userMessage, fromUser: true));
      _loading = true;
      _showQuickQuestions = false; // Hide quick questions after user sends a message
    });

    _messageController.clear();
    _textFieldFocus.requestFocus();

    try {
      final responseStream = _chat?.sendMessageStream(
        Content.text(userMessage),
      );

      if (responseStream == null) {
        _showError('No response from AI.');
        setState(() {
          _messages.add(MessageData(text: 'AI encountered an error or provided no response.', fromUser: false));
        });
        return;
      }

      // Add a placeholder message with typing indicator
      final aiMessageIndex = _messages.length;
      setState(() {
        _messages.add(MessageData(text: '', fromUser: false, isTyping: true));
      });
      _scrollDown();

      StringBuffer completeResponseBuffer = StringBuffer();
      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          completeResponseBuffer.write(chunk.text!);
          // Update the message text as chunks arrive for typing effect
          setState(() {
            _messages[aiMessageIndex] = MessageData(
              text: completeResponseBuffer.toString(),
              fromUser: false,
              isTyping: true, // Keep typing until stream ends
            );
          });
          _scrollDown();
        }
      }

      final fullAiResponse = completeResponseBuffer.toString();
      String displayResponse = 'AI returned an unexpected response.';
      Map<String, dynamic>? weatherReportData; // To store parsed weather data
      List<AISuggestion> suggestions = [];

      if (fullAiResponse.isNotEmpty) {
        try {
          String cleanedResponse = fullAiResponse.trim();
          if (cleanedResponse.startsWith('```json') && cleanedResponse.endsWith('```')) {
            cleanedResponse = cleanedResponse.substring(7, cleanedResponse.length - 3).trim();
          }

          final Map<String, dynamic> parsedJson = jsonDecode(cleanedResponse) as Map<String, dynamic>;
          final String? responseType = parsedJson['response_type'] as String?;

          if (responseType == 'text_response') {
            displayResponse = parsedJson['text_content'] as String? ?? 'AI沒有提供有效回應。';
            weatherReportData = null; // Ensure weather data is null for text responses
          } else if (responseType == 'weather_report') {
            weatherReportData = parsedJson['weather_report'] as Map<String, dynamic>?;
            displayResponse = ''; // No direct text, handled by structured data
          }
          else {
            // Fallback for unexpected response_type
            displayResponse = 'AI回應格式錯誤，原始回應：$fullAiResponse';
            weatherReportData = null;
          }
        } catch (e) {
          print('Error parsing AI response as JSON: $e');
          displayResponse = 'AI回應解析失敗，原始回應：$fullAiResponse';
          weatherReportData = null;
        }
      } else {
        displayResponse = 'AI沒有提供有效回應。';
        weatherReportData = null;
      }

      // Final update of the AI message
      setState(() {
        if (aiMessageIndex < _messages.length) {
          _messages[aiMessageIndex] = MessageData(
            text: displayResponse,
            fromUser: false,
            suggestions: suggestions,
            isTyping: false, // Turn off typing indicator
            weatherReportData: weatherReportData, // Pass structured weather data
          );
        } else {
          // Fallback if message was somehow removed or index is off
          _messages.add(MessageData(text: displayResponse, fromUser: false, suggestions: suggestions, isTyping: false, weatherReportData: weatherReportData));
        }
      });

    } catch (e) {
      _showError('發生錯誤: ${e.toString()}');
      setState(() {
        _messages.add(MessageData(text: 'Error: ${e.toString()}', fromUser: false, isTyping: false));
      });
    } finally {
      setState(() {
        _loading = false;
        _scrollDown();
      });
    }
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return ErrorAlertDialog(message: message);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Changed background color to light grey
      appBar: AppBar(
        title: const Text('AI 天氣小幫手'),
        backgroundColor: Colors.grey[100], // Set AppBar background to match Scaffold
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            if (_showQuickQuestions)
              QuickQuestionsPanel(
                quickQuestions: _quickQuestions,
                isLoading: _loading,
                onQuestionSelected: (question) {
                  _sendMessage(predefinedMessage: question);
                },
              ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, idx) {
                  final message = _messages[idx];
                  return MessageWidget(
                    text: message.text,
                    image: message.image,
                    isFromUser: message.fromUser ?? false,
                    suggestions: message.suggestions,
                    isTyping: message.isTyping, // Pass typing state
                    weatherReportData: message.weatherReportData, // Pass structured weather data
                  );
                },
              ),
            ),
            MessageInputBar(
              controller: _messageController,
              onSubmitted: _sendMessage,
              isLoading: _loading,
            ),
          ],
        ),
      ),
    );
  }
}