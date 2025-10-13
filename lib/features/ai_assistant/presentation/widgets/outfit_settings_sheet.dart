import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/ai_assistant_cubit.dart';
import '../cubit/ai_assistant_state.dart';

class OutfitSettingsSheet extends StatefulWidget {
  const OutfitSettingsSheet({super.key});

  @override
  State<OutfitSettingsSheet> createState() => _OutfitSettingsSheetState();
}

class _OutfitSettingsSheetState extends State<OutfitSettingsSheet> {
  late final TextEditingController _customSceneController;
  late final TextEditingController _customStyleController;

  @override
  void initState() {
    super.initState();
    final state = context.read<AiAssistantCubit>().state;
    _customSceneController = TextEditingController(text: state.customScene);
    _customStyleController = TextEditingController(text: state.customStyle);
  }

  @override
  void dispose() {
    _customSceneController.dispose();
    _customStyleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> sceneOptions = ['上班', '約會', '旅遊', '婚禮', '運動', '派對', '休閒'];
    final List<String> styleOptions = ['都會', '休閒', '運動', '正式', '復古'];

    Widget buildCustomTextField({
      required TextEditingController controller,
      required VoidCallback onTap,
      required ValueChanged<String> onChanged,
    }) {
      return SizedBox(
        width: 120,
        height: 38,
        child: TextField(
          controller: controller,
          onTap: onTap,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            hintText: '自訂...',
            hintStyle: TextStyle(fontSize: 14, color: Colors.grey[600]),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0), borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.grey[200],
          ),
        ),
      );
    }

    return BlocConsumer<AiAssistantCubit, AiAssistantState>(
      listener: (context, state) {
        if (state.customScene.isEmpty && _customSceneController.text.isNotEmpty) {
          _customSceneController.clear();
        }
        if (state.customStyle.isEmpty && _customStyleController.text.isNotEmpty) {
          _customStyleController.clear();
        }
      },
      builder: (context, state) {
        final cubit = context.read<AiAssistantCubit>();
        return Padding(
          padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, MediaQuery.of(context).padding.bottom + 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('穿搭設定', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- Scene Section ---
              const Text('場景', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...sceneOptions.map((scene) {
                      final isSelected = state.selectedScene == scene;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(scene),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            if (selected) cubit.selectScene(scene);
                          },
                          shape: const StadiumBorder(),
                          side: BorderSide.none,
                          selectedColor: Colors.blue,
                          backgroundColor: Colors.grey[200],
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      );
                    }),
                    buildCustomTextField(
                      controller: _customSceneController,
                      onTap: () => cubit.selectScene(''),
                      onChanged: (value) => cubit.setCustomScene(value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // --- Style Section ---
              const Text('風格', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...styleOptions.map((style) {
                      final isSelected = state.selectedStyle == style;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(style),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            if (selected) cubit.selectStyle(style);
                          },
                          shape: const StadiumBorder(),
                          side: BorderSide.none,
                          selectedColor: Colors.blue,
                          backgroundColor: Colors.grey[200],
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      );
                    }),
                    buildCustomTextField(
                      controller: _customStyleController,
                      onTap: () => cubit.selectStyle(''),
                      onChanged: (value) => cubit.setCustomStyle(value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              const Text('地點 & 日期', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: const BorderRadius.all(Radius.circular(30)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on_outlined, color: Colors.black54),
                          const SizedBox(width: 8),
                          Text(
                            context.read<AiAssistantCubit>().weatherDataState.currentLocationName ?? '未知地點',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                     child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: const BorderRadius.all(Radius.circular(30)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today_outlined, color: Colors.black54),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('M月d日').format(DateTime.now()),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    cubit.generateOutfitImage();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('生成穿搭', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
