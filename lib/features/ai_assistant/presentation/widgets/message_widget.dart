import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../data/models/ai_message.dart'; // Import the new MessageData
import 'general_weather_card.dart';
import 'uv_index_card.dart';
import 'clothing_advice_card.dart';

class MessageWidget extends StatefulWidget {
  final Image? image;
  final String? text;
  final bool isFromUser;
  final List<AISuggestion>? suggestions; // Added for AI suggestions
  final bool isTyping; // New: Added for typing animation
  final Map<String, dynamic>? weatherReportData; // New: Structured weather data

  const MessageWidget({
    super.key,
    this.image,
    this.text,
    required this.isFromUser,
    this.suggestions,
    this.isTyping = false, // Initialize isTyping
    this.weatherReportData,
  });

  @override
  State<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(); // Repeat animation
    _dotAnimations = List.generate(3, (index) {
      return Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.2, // Stagger the start of each dot's animation
            (index * 0.2) + 0.5, // End of animation for each dot
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bubbleMaxWidth = widget.isFromUser ? screenWidth * 0.9 : screenWidth * 2 / 3;

    final Color messageBubbleColor = widget.isFromUser
        ? const Color.fromARGB(255, 93, 179, 250) // User message bubble color
        : Colors.white; // AI message bubble color
    
    final Color messageTextColor = widget.isFromUser ? Colors.white : Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: widget.isFromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: widget.isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Flexible(
              child: Container(
                constraints: BoxConstraints(maxWidth: bubbleMaxWidth), // Apply width limit
                decoration: BoxDecoration(
                  color: messageBubbleColor,
                  borderRadius: widget.isFromUser
                      ? const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(4), // Pointy end for user
                        )
                      : const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(4), // Pointy end for AI
                          bottomRight: Radius.circular(18),
                        ),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 20,
                ),
                margin: const EdgeInsets.only(bottom: 8),
                child: widget.isTyping && !widget.isFromUser // Only show typing indicator for AI and when typing
                    ? AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Row(
                            mainAxisSize: MainAxisSize.min, // Keep dots close
                            children: _dotAnimations.map((animation) {
                              return Opacity(
                                opacity: animation.value,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 1.0),
                                  child: Container(
                                    width: 8.0,
                                    height: 8.0,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start, // Align text to start within bubble
                        children: [
                          if (widget.text case final text?) 
                            MarkdownBody(
                              data: text,
                              styleSheet: MarkdownStyleSheet.fromTheme(
                                Theme.of(context),
                              ).copyWith(
                                p: Theme.of(context).textTheme.bodyMedium?.copyWith(color: messageTextColor),
                              ),
                            ),
                          if (widget.image case final image?) image,
                          if (!widget.isFromUser && widget.weatherReportData != null) ...[
                            if (widget.weatherReportData!['general_forecast'] is Map && (widget.weatherReportData!['general_forecast'] as Map).isNotEmpty)
                              GeneralWeatherCard(data: widget.weatherReportData!['general_forecast'] as Map<String, dynamic>),
                            if (widget.weatherReportData!['uv_info'] is Map && (widget.weatherReportData!['uv_info'] as Map).isNotEmpty)
                              UvIndexCard(data: widget.weatherReportData!['uv_info'] as Map<String, dynamic>),
                            if (widget.weatherReportData!['clothing_advice'] is Map && (widget.weatherReportData!['clothing_advice'] as Map).isNotEmpty)
                              ClothingAdviceCard(data: widget.weatherReportData!['clothing_advice'] as Map<String, dynamic>),
                          ]
                        ],
                      ),
              ),
            ),
          ],
        ),
        // AI Suggestion Cards (if any)
        if (!widget.isFromUser && widget.suggestions != null && widget.suggestions!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 0.0, bottom: 5.0, left: 5.0), // Indent suggestions slightly
            child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.suggestions!.map((suggestion) =>
                 Card(
                   elevation: 2,
                   margin: const EdgeInsets.symmetric(vertical: 4.0),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                   child: Padding(
                     padding: const EdgeInsets.all(12.0),
                     child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(suggestion.title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                           const SizedBox(height: 4),
                           Text(suggestion.description, style: Theme.of(context).textTheme.bodyMedium),
                        ]
                     ),
                   )
                 )
              ).toList(),
            ),
          ),
      ],
    );
  }
}