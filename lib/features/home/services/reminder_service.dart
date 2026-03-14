import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReminderSettings {
  final bool enabled;
  final TimeOfDay time;

  const ReminderSettings({
    required this.enabled,
    required this.time,
  });
}

/// Offline-safe daily reminder service that avoids exact-alarm scheduling.
class ReminderService {
  static const int _reminderId = 7001;
  static const String _enabledKey = 'reminder_enabled';
  static const String _hourKey = 'reminder_hour';
  static const String _minuteKey = 'reminder_minute';

  static const List<String> _messages = <String>[
    'Take a moment to read today\'s scripture.',
    'Pause and pray.',
    'Write a reflection in your journal.',
  ];

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  VoidCallback? _onOpenToday;

  Future<void> init({VoidCallback? onOpenToday}) async {
    if (_initialized) return;
    _onOpenToday = onOpenToday;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true &&
          launchDetails?.notificationResponse?.payload == 'open_today') {
        _onOpenToday?.call();
      }

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      _initialized = true;
    } catch (e) {
      // Never fail app boot if notification setup fails.
      debugPrint('ReminderService init failed: $e');
      _initialized = true;
    }
  }

  Future<ReminderSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_enabledKey) ?? false;
    final hour = prefs.getInt(_hourKey) ?? 8;
    final minute = prefs.getInt(_minuteKey) ?? 0;
    return ReminderSettings(
      enabled: enabled,
      time: TimeOfDay(hour: hour, minute: minute),
    );
  }

  Future<void> updateReminder({
    required bool enabled,
    required TimeOfDay time,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    await prefs.setInt(_hourKey, time.hour);
    await prefs.setInt(_minuteKey, time.minute);

    if (enabled) {
      await _scheduleReminderSafely(time);
      return;
    }

    await cancelReminder();
  }

  Future<void> rescheduleIfEnabled() async {
    final settings = await loadSettings();
    if (!settings.enabled) return;
    await _scheduleReminderSafely(settings.time);
  }

  Future<void> cancelReminder() async {
    try {
      if (!_initialized) {
        await init(onOpenToday: _onOpenToday);
      }
      await _plugin.cancel(_reminderId);
    } catch (e) {
      debugPrint('ReminderService cancel failed: $e');
    }
  }

  Future<void> _scheduleReminderSafely(TimeOfDay selectedTime) async {
    try {
      if (!_initialized) {
        await init(onOpenToday: _onOpenToday);
      }

      await _plugin.cancel(_reminderId);

      const androidDetails = AndroidNotificationDetails(
        'daily_prayer_reminder',
        'Daily Prayer Reminder',
        channelDescription:
            'Daily reminders for scripture reading, prayer, and journaling.',
        importance: Importance.high,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails();

      final message = _pickRotatingMessage(selectedTime);

      await _plugin.periodicallyShow(
        _reminderId,
        'Daily Prayer Reminder',
        message,
        RepeatInterval.daily,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: 'open_today',
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      // Never crash the app if scheduling fails.
      debugPrint('ReminderService schedule failed: $e');
    }
  }

  String _pickRotatingMessage(TimeOfDay selectedTime) {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final salt = selectedTime.hour * 60 + selectedTime.minute;
    final idx = (dayOfYear + salt) % _messages.length;
    return _messages[idx];
  }

  void _onNotificationResponse(NotificationResponse response) {
    if (response.payload == 'open_today') {
      _onOpenToday?.call();
    }
  }
}
