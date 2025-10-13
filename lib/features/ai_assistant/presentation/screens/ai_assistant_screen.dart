import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:weatherpro/features/radar/data/services/radar_forecast_service.dart';
import 'package:weatherpro/features/weather/presentation/state/weather_data_state.dart';
import 'package:weatherpro/services/location_service.dart';
import 'package:weatherpro/services/usage_limit_service.dart';
import 'package:weatherpro/services/remote_config_service.dart';
// --- MODIFICATION START: Add new imports ---
// 原因: 引入我們重構後所需的 Service 和 Tools，以便在這裡組裝它們。
import '../../data/services/firebase_ai_service.dart';
import '../../domain/services/ai_assistant_service.dart';
import '../../domain/services/gemini_tools.dart';
// --- MODIFICATION END ---
import '../cubit/ai_assistant_cubit.dart';
import '../cubit/ai_assistant_state.dart';
import '../widgets/message_widget.dart';
import '../widgets/message_input_bar.dart';
import '../widgets/outfit_assistant_view.dart';
import '../widgets/quick_questions_panel.dart';

enum AiAssistantViewType {
  weatherAssistant,
  outfitAssistant,
}

class AiAssistantScreenProvider extends StatelessWidget {
  const AiAssistantScreenProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return const AiAssistantScreen();
  }
}

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  AiAssistantViewType _selectedView = AiAssistantViewType.weatherAssistant;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AiAssistantCubit, AiAssistantState>(
      listener: (context, state) {
        if (_selectedView == AiAssistantViewType.weatherAssistant) {
          _scrollToBottom();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: CupertinoNavigationBar(
          middle: const Text('AI 天氣小幫手'),
          backgroundColor: Colors.grey[100],
          automaticallyImplyLeading: false,
          border: const Border(
            bottom: BorderSide(
              color: CupertinoColors.systemGrey4,
              width: 0.5,
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
              child: CupertinoSlidingSegmentedControl<AiAssistantViewType>(
                groupValue: _selectedView,
                children: const {
                  AiAssistantViewType.weatherAssistant: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('天氣助手'),
                  ),
                  AiAssistantViewType.outfitAssistant: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('穿搭助手'),
                  ),
                },
                onValueChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedView = value;
                    });
                  }
                },
              ),
            ),
            Expanded(
              child: _selectedView == AiAssistantViewType.weatherAssistant
                  ? _buildWeatherAssistant(context)
                  : const OutfitAssistantView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherAssistant(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Expanded(
            child: BlocBuilder<AiAssistantCubit, AiAssistantState>(
              builder: (context, state) {
                if (state.status == AiAssistantStatus.initial && state.messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == AiAssistantStatus.failure && state.messages.length <= 1) {
                  return Center(child: Text('Error: ${state.error}'));
                }
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final message = state.messages[index];
                    // 4. Remove the no-longer-needed quickReplies parameter.
                    return MessageWidget(
                      text: message.text,
                      isFromUser: message.fromUser,
                      isTyping: message.isTyping,
                    );
                  },
                );
              },
            ),
          ),
          // 2. Add a BlocBuilder to conditionally display the quick questions panel.
          BlocBuilder<AiAssistantCubit, AiAssistantState>(
            // Use buildWhen to optimize and rebuild only when quickReplies change.
            buildWhen: (previous, current) => previous.quickReplies != current.quickReplies,
            builder: (context, state) {
              if (state.quickReplies.isEmpty) {
                // If there are no quick replies, return an empty, non-space-consuming widget.
                return const SizedBox.shrink();
              }
              // Otherwise, display the panel.
              return QuickQuestionsPanel(
                questions: state.quickReplies,
                onQuestionTapped: (question) {
                  // Tapping a question sends a message to the cubit.
                  context.read<AiAssistantCubit>().sendMessage(question);
                },
              );
            },
          ),
          BlocBuilder<AiAssistantCubit, AiAssistantState>(
            builder: (context, state) {
              return MessageInputBar(
                controller: _messageController,
                isLoading: state.status == AiAssistantStatus.loading,
                onSubmitted: () {
                  final text = _messageController.text;
                  if (text.isNotEmpty) {
                    context.read<AiAssistantCubit>().sendMessage(text);
                    _messageController.clear();
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
