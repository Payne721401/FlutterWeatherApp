import 'package:equatable/equatable.dart';

class MessageData extends Equatable {
  final String text;
  final bool fromUser;
  final bool isTyping;
  final List<String>? quickReplies; // PLAN: Add quickReplies field

  const MessageData({
    required this.text,
    required this.fromUser,
    this.isTyping = false,
    this.quickReplies, // PLAN: Add to constructor
  });

  MessageData copyWith({
    String? text,
    bool? isTyping,
    List<String>? quickReplies, // PLAN: Add to copyWith
    bool removeQuickReplies = false, // Helper to explicitly remove replies
  }) {
    return MessageData(
      text: text ?? this.text,
      fromUser: fromUser,
      isTyping: isTyping ?? this.isTyping,
      quickReplies: removeQuickReplies ? null : quickReplies ?? this.quickReplies,
    );
  }

  @override
  // PLAN: Add quickReplies to props for Equatable
  List<Object?> get props => [text, fromUser, isTyping, quickReplies];
}
