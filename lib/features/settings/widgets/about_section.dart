import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../../services/app_version_service.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    // --- MODIFICATION START: Get AppVersionService from Provider ---
    final appVersionService = context.watch<AppVersionService>();
    // --- MODIFICATION END ---

    return Column(
      children: <CupertinoListTile>[
        CupertinoListTile(
          title: const Text('版本'),
          // --- MODIFICATION START: Display dynamic version ---
          additionalInfo: Text(appVersionService.appVersion),
          // --- MODIFICATION END ---
          onTap: () {
            // You could show more details here, like the build number
            // For example: Text('${appVersionService.appVersion} (${appVersionService.buildNumber})')
          },
        ),
        CupertinoListTile(
          title: const Text('開發者資訊'),
          trailing: const CupertinoListTileChevron(),
          onTap: () {
            // TODO: Navigate to a developer info screen or open a URL
          },
        ),
      ],
    );
  }
}
