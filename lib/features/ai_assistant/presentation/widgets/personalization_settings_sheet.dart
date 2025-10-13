import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/ai_assistant_cubit.dart';
import '../cubit/ai_assistant_state.dart';

class PersonalizationSettingsSheet extends StatefulWidget {
  const PersonalizationSettingsSheet({super.key});

  @override
  State<PersonalizationSettingsSheet> createState() => _PersonalizationSettingsSheetState();
}

class _PersonalizationSettingsSheetState extends State<PersonalizationSettingsSheet> {
  late final TextEditingController _ageController;

  @override
  void initState() {
    super.initState();
    final state = context.read<AiAssistantCubit>().state;
    _ageController = TextEditingController(text: state.userAge);
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> genderOptions = ['女性', '男性'];
    final List<String> bodyTypeOptions = ['修長', '標準', '圓潤'];
    final List<String> fitPreferenceOptions = ['寬鬆', '合身'];
    final List<String> tempPreferenceOptions = ['怕冷', '怕熱', '中性'];

    const Color activeColor = Color(0xFFB39DDB);

    return BlocBuilder<AiAssistantCubit, AiAssistantState>(
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
                  const Text('個人化設定', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text('性別 & 年齡', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  ...genderOptions.map((gender) {
                    final isSelected = state.selectedGender == gender;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(gender),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          if (selected) cubit.selectGender(gender);
                        },
                        shape: const StadiumBorder(),
                        side: BorderSide.none,
                        selectedColor: activeColor,
                        backgroundColor: Colors.grey[200],
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(width: 8.0),
                  SizedBox(
                    width: 80,
                    height: 40,
                    child: TextField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      onChanged: (value) => cubit.setUserAge(value),
                      decoration: InputDecoration(
                        hintText: '年齡',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              const Text('體型', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: bodyTypeOptions.map((bodyType) {
                    final isSelected = state.selectedBodyType == bodyType;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(bodyType),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          if (selected) cubit.selectBodyType(bodyType);
                        },
                        shape: const StadiumBorder(),
                        side: BorderSide.none,
                        selectedColor: activeColor,
                        backgroundColor: Colors.grey[200],
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16.0),

              const Text('版型偏好', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: fitPreferenceOptions.map((fit) {
                    final isSelected = state.selectedFitPreference == fit;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(fit),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          if (selected) cubit.selectFitPreference(fit);
                        },
                        shape: const StadiumBorder(),
                        side: BorderSide.none,
                        selectedColor: activeColor,
                        backgroundColor: Colors.grey[200],
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16.0),

              const Text('冷熱偏好', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: tempPreferenceOptions.map((temp) {
                    final isSelected = state.selectedTempPreference == temp;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(temp),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          if (selected) cubit.selectTempPreference(temp);
                        },
                        shape: const StadiumBorder(),
                        side: BorderSide.none,
                        selectedColor: activeColor,
                        backgroundColor: Colors.grey[200],
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24.0),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    cubit.savePersonalizationSettings();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeColor,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('儲存', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
