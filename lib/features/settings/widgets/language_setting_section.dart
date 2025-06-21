import 'package:flutter/cupertino.dart';

class LanguageSettingSection extends StatelessWidget {
  final String selectedLanguage;
  final Map<String, String> languageDisplayNames;
  final ValueChanged<String> onLanguageChanged;

  const LanguageSettingSection({
    super.key,
    required this.selectedLanguage,
    required this.languageDisplayNames,
    required this.onLanguageChanged,
  });

  void _showLanguagePicker(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('選擇語言'), // TODO: Localize
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            isDefaultAction: selectedLanguage == 'zh',
            onPressed: () {
              Navigator.pop(context);
              if (selectedLanguage != 'zh') {
                onLanguageChanged('zh');
              }
            },
            child: Text(languageDisplayNames['zh']!),
          ),
          CupertinoActionSheetAction(
            isDefaultAction: selectedLanguage == 'en',
            onPressed: () {
              Navigator.pop(context);
              if (selectedLanguage != 'en') {
                onLanguageChanged('en');
              }
            },
            child: Text(languageDisplayNames['en']!),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('取消'), // TODO: Localize
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoListSection.insetGrouped(
      header: const Text('一般'), // TODO: Localize
      children: <CupertinoListTile>[
        CupertinoListTile(
          title: const Text('語言'), // TODO: Localize
          additionalInfo: Text(languageDisplayNames[selectedLanguage] ?? selectedLanguage),
          trailing: const CupertinoListTileChevron(),
          onTap: () => _showLanguagePicker(context),
        ),
      ],
    );
  }
}
