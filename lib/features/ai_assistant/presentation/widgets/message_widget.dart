import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MessageWidget extends StatefulWidget {
  final String text;
  final bool isFromUser;
  final bool isTyping;

  const MessageWidget({
    super.key,
    required this.text,
    required this.isFromUser,
    this.isTyping = false,
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
    );
    _dotAnimations = List.generate(3, (index) {
      return Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.2,
            (index * 0.2) + 0.5,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
    if (widget.isTyping) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant MessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTyping && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isTyping && _controller.isAnimating) {
      _controller.stop();
    }
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
        ? const Color.fromARGB(255, 93, 179, 250)
        : Colors.white;

    final Color messageTextColor = widget.isFromUser ? Colors.white : Theme.of(context).colorScheme.onSurface;

    return Row(
      mainAxisAlignment: widget.isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
            decoration: BoxDecoration(
              color: messageBubbleColor,
              borderRadius: widget.isFromUser
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(4),
                    )
                  : const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(18),
                    ),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 20,
            ),
            margin: const EdgeInsets.only(bottom: 8),
            child: widget.isTyping && widget.text.isEmpty
                ? AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
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
                : MarkdownBody(
                    data: widget.text,
                    styleSheet: MarkdownStyleSheet.fromTheme(
                      Theme.of(context),
                    ).copyWith(
                      p: Theme.of(context).textTheme.bodyMedium?.copyWith(color: messageTextColor),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
