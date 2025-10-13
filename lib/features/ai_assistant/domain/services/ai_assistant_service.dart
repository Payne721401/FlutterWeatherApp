import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_ai/firebase_ai.dart';

abstract class AiAssistantService {
  Future<void> initialize();

  Future<GenerateContentResponse> generateOutfitImage(String prompt);

  Stream<GenerateContentResponse> sendMessage(String message);

  void resetChat();

  // --- ADDED: Getter for the outfit system prompt ---
  String get outfitSystemPrompt;
}
