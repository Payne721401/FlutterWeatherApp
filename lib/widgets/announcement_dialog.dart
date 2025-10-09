import 'package:flutter/cupertino.dart';
import '../models/announcement.dart';

/// A dialog that displays the details of a single announcement.
class AnnouncementDialog extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementDialog({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(announcement.title),
      content: Text(announcement.content),
      actions: <CupertinoDialogAction>[
        CupertinoDialogAction(
          isDefaultAction: true,
          child: const Text('確認'),
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
        ),
      ],
    );
  }
}
