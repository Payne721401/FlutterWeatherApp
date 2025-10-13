import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:weatherpro/features/ai_assistant/presentation/cubit/ai_assistant_cubit.dart';
import 'package:weatherpro/features/ai_assistant/presentation/cubit/ai_assistant_state.dart';

class OutfitImageDisplay extends StatelessWidget {
  const OutfitImageDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AiAssistantCubit, AiAssistantState>(
      builder: (context, state) {
        final weatherState = context.read<AiAssistantCubit>().weatherDataState;

        Widget imageContent;
        switch (state.imageGenerationStatus) {
          case ImageGenerationStatus.loading:
            imageContent = const Center(
              child: CircularProgressIndicator(),
            );
            break;
          case ImageGenerationStatus.failure:
            imageContent = Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    state.imageGenerationError ?? '圖片生成失敗',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ],
              ),
            );
            break;
          default:
            if (state.generatedImageBytes != null) {
              imageContent = Image.memory(
                state.generatedImageBytes!,
                fit: BoxFit.cover,
              );
            } else {
              imageContent = Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome_outlined, color: Colors.grey[600], size: 80),
                  const SizedBox(height: 16),
                  Text(
                    '讓 AI 為您打造專屬風格',
                    style: TextStyle(color: Colors.grey[700], fontSize: 16),
                  ),
                ],
              );
            }
        }

        return Column(
          children: [
            // --- MODIFICATION START: Centered the weather description ---
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min, // To keep the row content width tight
                children: [
                  const Icon(CupertinoIcons.cloud_sun, color: Colors.black, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    weatherState.currentLocationName ?? '地點',
                    // --- MODIFICATION: Color changed back to black ---
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${weatherState.temperature?.round() ?? '--'}°C',
                    // --- MODIFICATION: Color changed back to black ---
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ],
              ),
            ),
            // --- MODIFICATION END ---
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 4 / 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    // --- MODIFICATION: Background color is now transparent ---
                    color: Colors.transparent,
                  ),
                  child: imageContent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
