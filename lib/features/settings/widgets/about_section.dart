import 'package:flutter/cupertino.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoListSection.insetGrouped(
      header: const Text('關於'), // TODO: Localize
      children: <CupertinoListTile>[
        CupertinoListTile(
          title: const Text('版本'), // TODO: Localize
          additionalInfo: const Text('1.0.0'), // TODO: Get from package_info
          onTap: () {
            /* Maybe show more details */
          },
        ),
        CupertinoListTile(
          title: const Text('開發者資訊'), // TODO: Localize
          trailing: const CupertinoListTileChevron(),
          onTap: () {
            /* Navigate to developer info screen */
          },
        ),
      ],
    );
  }
}
