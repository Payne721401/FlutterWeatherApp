import 'package:flutter/material.dart';

class ErrorAlertDialog extends StatelessWidget {
  final String message;

  const ErrorAlertDialog({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('發生錯誤'),
      content: SingleChildScrollView(
        child: SelectableText(message),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('確定'),
        ),
      ],
    );
  }
}
