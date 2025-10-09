import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

/// Shows a non-dismissible dialog forcing the user to update the app.
///
/// This dialog presents options based on the app's distribution phase.
Future<void> showUpdateDialog(BuildContext context) async {
  await showCupertinoDialog(
    context: context,
    // This makes the dialog non-dismissible by tapping outside.
    barrierDismissible: false,
    builder: (BuildContext context) => CupertinoAlertDialog(
      title: const Text('發現新版本！'),
      // MODIFICATION: Content updated for non-store distribution like App Distribution.
      content: const Text('為了獲得最佳體驗並使用最新功能，請下載並安裝最新版本。'),
      actions: <CupertinoDialogAction>[
        // TODO: When publishing to the public app stores, uncomment the following
        //       CupertinoDialogAction and replace the placeholder IDs.
        /*
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () async {
            const String androidPackageName = 'YOUR_ANDROID_PACKAGE_NAME';
            const String appleAppId = 'YOUR_APP_ID';

            final Uri storeUrl = Platform.isAndroid
                ? Uri.parse("market://details?id=$androidPackageName")
                : Uri.parse("https://apps.apple.com/app/id$appleAppId");

            if (await canLaunchUrl(storeUrl)) {
              await launchUrl(storeUrl, mode: LaunchMode.externalApplication);
            }
          },
          child: const Text('前往商店更新'),
        ),
        */

        // This action allows the user to close the app, which is necessary for a forced update.
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () {
            // This will close the app.
            SystemNavigator.pop();
          },
          child: const Text('關閉 App'),
        ),
      ],
    ),
  );
}

/// Shows a dialog to inform the user that they are using a beta version of the app.
Future<void> showBetaWarningDialog(BuildContext context) async {
  await showCupertinoDialog(
    context: context,
    builder: (BuildContext context) => CupertinoAlertDialog(
      title: const Text('Beta 版本提示'),
      content: const Text('此為 Beta 版本，部分功能可能尚不穩定，敬請見諒。'),
      actions: <CupertinoDialogAction>[
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('我瞭解了'),
        ),
      ],
    ),
  );
}
