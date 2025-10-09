import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // MODIFIED: Import added

import '../models/announcement.dart';

class AnnouncementService extends ChangeNotifier {
  static const _kAnnouncementsKey = 'announcements_storage_key';
  final SharedPreferences _prefs;

  List<Announcement> _announcements = [];

  AnnouncementService(this._prefs) {
    _loadAnnouncements();
  }

  List<Announcement> get announcements => _announcements;
  int get unreadCount => _announcements.where((a) => !a.isRead).length;

  Future<void> _loadAnnouncements() async {
    final List<String> announcementsJson = _prefs.getStringList(_kAnnouncementsKey) ?? [];
    _announcements = announcementsJson
        .map((json) => Announcement.fromJson(json))
        .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  Future<void> refresh() async {
    await _prefs.reload();
    await _loadAnnouncements();
  }

  /// Adds a new announcement from a received FCM message.
  ///
  /// This method is now "smart" and can create a complete announcement
  /// from either a data payload or a notification payload.
  Future<Announcement?> addAnnouncementFromFCM(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final data = message.data;
      
      // Smartly create the announcement object, same logic as background handler
      final newAnnouncement = Announcement(
        id: data['id']?.toString() ?? 'noti_${DateTime.now().millisecondsSinceEpoch}',
        title: data['title']?.toString() ?? notification?.title ?? '新公告',
        content: data['content']?.toString() ?? notification?.body ?? '點擊查看詳情',
        timestamp: (data['timestamp'] != null)
            ? DateTime.parse(data['timestamp'])
            : DateTime.now(),
        isRead: false, // Always starts as unread
      );

      // Reload data from disk to avoid overwriting background changes
      await _prefs.reload();
      final currentJson = _prefs.getStringList(_kAnnouncementsKey) ?? [];
      
      // Check for duplicates before adding
      if (currentJson.any((json) => json.contains(newAnnouncement.id))) {
        debugPrint('Announcement with id ${newAnnouncement.id} already exists. Skipping.');
        return null; // Return null to indicate no new announcement was added
      }

      // Add to the list in memory
      _announcements.insert(0, newAnnouncement);
      _announcements.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Save the updated list to disk
      await _saveAnnouncements();
      notifyListeners();
      
      // Return the newly created announcement so the UI can use it
      return newAnnouncement;

    } catch (e) {
      debugPrint('Error adding announcement from FCM: $e');
      return null;
    }
  }

  Future<void> markAllAsRead() async {
    if (unreadCount == 0) return;
    _announcements = _announcements.map((a) => a.copyWith(isRead: true)).toList();
    await _saveAnnouncements();
    notifyListeners();
  }

  Future<void> _saveAnnouncements() async {
    final List<String> announcementsJson = _announcements.map((a) => a.toJson()).toList();
    await _prefs.setStringList(_kAnnouncementsKey, announcementsJson);
  }
}
