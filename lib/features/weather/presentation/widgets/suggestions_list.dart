import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Assuming Provider is used
import '../state/weather_state.dart';

class SuggestionsList extends StatelessWidget {
  const SuggestionsList({super.key});

  @override
  Widget build(BuildContext context) {
    final weatherState = context.watch<WeatherState>();
    final suggestions = weatherState.suggestions;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      child: suggestions.isNotEmpty
        ? Container(
            margin: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0), // Match search bar horizontal padding
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [ BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4.0, offset: const Offset(0, 2)) ]
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              shrinkWrap: true,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return ListTile(
                  title: Text(suggestion),
                  onTap: () => weatherState.handleSuggestionTap(suggestion, context),
                  dense: true,
                );
              },
            ),
          )
        : const SizedBox.shrink(),
    );
  }
}
