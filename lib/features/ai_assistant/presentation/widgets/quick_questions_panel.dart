import 'package:flutter/material.dart';

class QuickQuestionsPanel extends StatelessWidget {
  final List<String> quickQuestions;
  final bool isLoading;
  final Function(String) onQuestionSelected;

  const QuickQuestionsPanel({
    super.key,
    required this.quickQuestions,
    required this.isLoading,
    required this.onQuestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Split quickQuestions into two halves for two columns
    int halfLength = (quickQuestions.length / 2).ceil();
    List<String> firstColumnQuestions = quickQuestions.sublist(0, halfLength);
    List<String> secondColumnQuestions = quickQuestions.sublist(halfLength);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      child: Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        margin: EdgeInsets.zero,
        color: Colors.white, // AI訊息與預設問題外框改為白色
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    '你可以這樣問我：',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start, // Align the columns to the start (left)
                crossAxisAlignment: CrossAxisAlignment.start, // Align the row children to the start vertically
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Left align chips horizontally within column
                    children: firstColumnQuestions.map((question) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0), // Add vertical spacing between chips
                        child: ActionChip(
                          label: Text(question),
                          onPressed: isLoading ? null : () => onQuestionSelected(question),
                          side: BorderSide(color: Theme.of(context).colorScheme.outline),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          backgroundColor: Colors.white, // 預設問題外框改為白色
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(width: 16.0), // Add spacing between the two columns
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Left align chips horizontally within column
                    children: secondColumnQuestions.map((question) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0), // Add vertical spacing between chips
                        child: ActionChip(
                          label: Text(question),
                          onPressed: isLoading ? null : () => onQuestionSelected(question),
                          side: BorderSide(color: Theme.of(context).colorScheme.outline),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          backgroundColor: Colors.white, // 預設問題外框改為白色
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
