import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/announcement.dart';
import '../../../services/announcement_service.dart';

class AnnouncementHistoryDialog extends StatelessWidget {
  const AnnouncementHistoryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final announcementService = context.watch<AnnouncementService>();
    final announcements = announcementService.announcements;

    Widget content;
    if (announcements.isEmpty) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Text('目前沒有任何歷史公告。'),
      );
    } else {
      content = SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        width: double.maxFinite,
        child: Material(
          color: Colors.transparent,
          child: ListView.separated(
            padding: const EdgeInsets.only(top: 16.0),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              // Use the new custom Cupertino-style expansion tile
              return _CupertinoAnnouncementTile(announcement: announcements[index]);
            },
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
          ),
        ),
      );
    }

    return CupertinoAlertDialog(
      title: const Text('歷史公告'),
      content: content,
      actions: <CupertinoDialogAction>[
        CupertinoDialogAction(
          isDefaultAction: true,
          child: const Text('關閉'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

// --- NEW WIDGET START ---
/// A custom stateful widget that mimics ExpansionTile but with a Cupertino look and feel.
class _CupertinoAnnouncementTile extends StatefulWidget {
  final Announcement announcement;

  const _CupertinoAnnouncementTile({required this.announcement});

  @override
  State<_CupertinoAnnouncementTile> createState() => _CupertinoAnnouncementTileState();
}

class _CupertinoAnnouncementTileState extends State<_CupertinoAnnouncementTile> {
  bool _isExpanded = false;
  final DateFormat _formatter = DateFormat('yyyy-MM-dd HH:mm');

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = _formatter.format(widget.announcement.timestamp.toLocal());

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _toggleExpansion,
          behavior: HitTestBehavior.opaque, // Ensures the whole row is tappable
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.announcement.title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedTime,
                        style: TextStyle(fontSize: 13.0, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                  color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: Container(), // Collapsed state: empty container
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            child: Text(
              widget.announcement.content,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ), // Expanded state: the content
          crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
          firstCurve: Curves.easeOut,
          secondCurve: Curves.easeIn,
          sizeCurve: Curves.easeInOut,
        ),
      ],
    );
  }
}
// --- NEW WIDGET END ---
