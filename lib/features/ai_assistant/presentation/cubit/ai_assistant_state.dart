import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import '../../data/models/ai_message.dart';

enum AiAssistantStatus { initial, loading, success, failure }

enum ImageGenerationStatus { initial, loading, success, failure }

class AiAssistantState extends Equatable {
  // For text chat
  final AiAssistantStatus status;
  final List<MessageData> messages;
  final String? error;
  final List<String> quickReplies;

  // For image generation
  final ImageGenerationStatus imageGenerationStatus;
  final Uint8List? generatedImageBytes;
  final String? imageGenerationError;

  // For Outfit Settings Sheet
  final String selectedScene;
  final String customScene;
  final String selectedStyle;
  final String customStyle;

  // For Personalization Settings Sheet
  final String? selectedGender;
  final String? userAge;
  final String? selectedBodyType;
  final String? selectedFitPreference;
  final String? selectedTempPreference;

  const AiAssistantState({
    this.status = AiAssistantStatus.initial,
    this.messages = const [],
    this.error,
    this.quickReplies = const [],
    this.imageGenerationStatus = ImageGenerationStatus.initial,
    this.generatedImageBytes,
    this.imageGenerationError,
    this.selectedScene = '休閒', // Default value
    this.customScene = '',
    this.selectedStyle = '都會', // Default value
    this.customStyle = '',
    this.selectedGender,
    this.userAge,
    this.selectedBodyType,
    this.selectedFitPreference,
    this.selectedTempPreference,
  });

  AiAssistantState copyWith({
    AiAssistantStatus? status,
    List<MessageData>? messages,
    String? error,
    List<String>? quickReplies,
    ImageGenerationStatus? imageGenerationStatus,
    Uint8List? generatedImageBytes,
    String? imageGenerationError,
    String? selectedScene,
    String? customScene,
    String? selectedStyle,
    String? customStyle,
    String? selectedGender,
    String? userAge,
    String? selectedBodyType,
    String? selectedFitPreference,
    String? selectedTempPreference,
  }) {
    return AiAssistantState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      error: error ?? this.error,
      quickReplies: quickReplies ?? this.quickReplies,
      imageGenerationStatus: imageGenerationStatus ?? this.imageGenerationStatus,
      generatedImageBytes: generatedImageBytes ?? this.generatedImageBytes,
      imageGenerationError: imageGenerationError ?? this.imageGenerationError,
      selectedScene: selectedScene ?? this.selectedScene,
      customScene: customScene ?? this.customScene,
      selectedStyle: selectedStyle ?? this.selectedStyle,
      customStyle: customStyle ?? this.customStyle,
      selectedGender: selectedGender ?? this.selectedGender,
      userAge: userAge ?? this.userAge,
      selectedBodyType: selectedBodyType ?? this.selectedBodyType,
      selectedFitPreference: selectedFitPreference ?? this.selectedFitPreference,
      // --- FIX: Corrected the typo from 'tempPreference' to 'selectedTempPreference' ---
      selectedTempPreference: selectedTempPreference ?? this.selectedTempPreference,
    );
  }

  @override
  List<Object?> get props => [
        status,
        messages,
        error,
        quickReplies,
        imageGenerationStatus,
        generatedImageBytes,
        imageGenerationError,
        selectedScene,
        customScene,
        selectedStyle,
        customStyle,
        selectedGender,
        userAge,
        selectedBodyType,
        selectedFitPreference,
        selectedTempPreference,
      ];
}
