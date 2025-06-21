import 'package:flutter/material.dart';

class MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmitted;
  final bool isLoading;

  const MessageInputBar({
    super.key,
    required this.controller,
    required this.onSubmitted,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: '輸入訊息...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              ),
              onSubmitted: (_) => onSubmitted(),
            ),
          ),
          const SizedBox(width: 8.0),
          if (!isLoading)
            IconButton.filled(
              icon: const Icon(Icons.send),
              onPressed: onSubmitted,
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue.shade400,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            )
          else
            const CircularProgressIndicator(),
        ],
      ),
    );
  }
}
