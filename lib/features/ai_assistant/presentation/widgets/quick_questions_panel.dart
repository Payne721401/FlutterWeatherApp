import 'package:flutter/material.dart';

class QuickQuestionsPanel extends StatelessWidget {
  final List<String> questions;
  final Function(String) onQuestionTapped;

  const QuickQuestionsPanel({
    super.key,
    required this.questions,
    required this.onQuestionTapped,
  });

  @override
  Widget build(BuildContext context) {
    // Use a container with a fixed height to ensure the ListView has a bounded height.
    return Container(
      height: 50,
      // Use transparent color to ensure it blends with the background.
      color: Colors.transparent, 
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final question = questions[index];
          return ActionChip(
            label: Text(question),
            onPressed: () => onQuestionTapped(question),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            side: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
            backgroundColor: Theme.of(context).colorScheme.surface,
            labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
      ),
    );
  }
}
