import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:weatherpro/features/ai_assistant/presentation/cubit/ai_assistant_cubit.dart';
import 'package:weatherpro/features/ai_assistant/presentation/cubit/ai_assistant_state.dart';
import 'outfit_image_display.dart';
import 'outfit_settings_sheet.dart';
import 'personalization_settings_sheet.dart';

class OutfitAssistantView extends StatelessWidget {
  const OutfitAssistantView({super.key});

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: false,
      builder: (BuildContext context) {
        return const OutfitSettingsSheet();
      },
    );
  }

  void _showPersonalizationSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: false,
      builder: (BuildContext context) {
        return const PersonalizationSettingsSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocListener<AiAssistantCubit, AiAssistantState>(
        // MODIFICATION: Changed listener condition to be more generic
        listenWhen: (previous, current) => 
          previous.imageGenerationStatus != current.imageGenerationStatus,
        listener: (context, state) {
          if (state.imageGenerationStatus == ImageGenerationStatus.failure &&
              state.imageGenerationError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.imageGenerationError!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Column(
          children: [
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: OutfitImageDisplay(),
              ),
            ),
            _buildRichMenuTrigger(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRichMenuTrigger(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Container(
        height: 56,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFFE0E0E0)), // Colors.grey.shade300
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            // --- MODIFICATION START: Expanded InkWell to include arrow ---
            Expanded(
              child: InkWell(
                onTap: () => _showSettingsSheet(context),
                child: Row(
                  children: [
                    const Icon(Icons.palette_outlined),
                    const SizedBox(width: 12),
                    const Text('開啟穿搭風格設定', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    const Spacer(), // Pushes the arrow to the far right
                    const Icon(Icons.keyboard_arrow_up),
                  ],
                ),
              ),
            ),
            // --- MODIFICATION END ---
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => _showPersonalizationSettingsSheet(context),
              tooltip: '個人化設定',
            )
          ],
        ),
      ),
    );
  }
}
