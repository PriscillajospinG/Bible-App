import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ReminderSettings {
  final bool bibleReadingEnabled;
  final TimeOfDay bibleReadingTime;
  final bool prayerEnabled;
  final TimeOfDay prayerTime;

  const ReminderSettings({
    required this.bibleReadingEnabled,
    required this.bibleReadingTime,
    required this.prayerEnabled,
    required this.prayerTime,
  });
}

/// Offline-safe daily reminder service that avoids exact-alarm scheduling.
class ReminderService {
  static const int _bibleReadingReminderId = 7001;
  static const int _prayerReminderId = 7002;

  static const String _bibleReadingEnabledKey = 'bible_reading_enabled';
  static const String _bibleReadingHourKey = 'bible_reading_hour';
  static const String _bibleReadingMinuteKey = 'bible_reading_minute';

  static const String _prayerEnabledKey = 'prayer_enabled';
  static const String _prayerHourKey = 'prayer_hour';
  static const String _prayerMinuteKey = 'prayer_minute';

  static const TimeOfDay _defaultBibleReadingTime =
      TimeOfDay(hour: 6, minute: 0);
  static const TimeOfDay _defaultPrayerTime = TimeOfDay(hour: 6, minute: 40);

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _tzInitialized = false;
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

    final bibleEnabled = prefs.getBool(_bibleReadingEnabledKey) ?? true;
    final bibleHour = prefs.getInt(_bibleReadingHourKey) ?? _defaultBibleReadingTime.hour;
    final bibleMinute =
        prefs.getInt(_bibleReadingMinuteKey) ?? _defaultBibleReadingTime.minute;

    final prayerEnabled = prefs.getBool(_prayerEnabledKey) ?? true;
    final prayerHour = prefs.getInt(_prayerHourKey) ?? _defaultPrayerTime.hour;
    final prayerMinute = prefs.getInt(_prayerMinuteKey) ?? _defaultPrayerTime.minute;

    return ReminderSettings(
      bibleReadingEnabled: bibleEnabled,
      bibleReadingTime: TimeOfDay(hour: bibleHour, minute: bibleMinute),
      prayerEnabled: prayerEnabled,
      prayerTime: TimeOfDay(hour: prayerHour, minute: prayerMinute),
    );
  }

  Future<void> updateBibleReadingReminder({
    required bool enabled,
    required TimeOfDay time,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bibleReadingEnabledKey, enabled);
    await prefs.setInt(_bibleReadingHourKey, time.hour);
    await prefs.setInt(_bibleReadingMinuteKey, time.minute);

    if (enabled) {
      await _scheduleReminderSafely(
        id: _bibleReadingReminderId,
        title: 'Bible Reading Reminder',
        body: 'Start your day with God\'s Word.',
        selectedTime: time,
      );
      return;
    }

    await _cancelReminder(_bibleReadingReminderId);
  }

  Future<void> updatePrayerReminder({
    required bool enabled,
    required TimeOfDay time,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prayerEnabledKey, enabled);
    await prefs.setInt(_prayerHourKey, time.hour);
    await prefs.setInt(_prayerMinuteKey, time.minute);

    if (enabled) {
      await _scheduleReminderSafely(
        id: _prayerReminderId,
        title: 'Prayer Reminder',
        body: 'Take a moment to pray.',
        selectedTime: time,
      );
      return;
    }

    await _cancelReminder(_prayerReminderId);
  }

  Future<void> rescheduleAll() async {
    final settings = await loadSettings();

    if (settings.bibleReadingEnabled) {
      await _scheduleReminderSafely(
        id: _bibleReadingReminderId,
        title: 'Bible Reading Reminder',
        body: 'Start your day with God\'s Word.',
        selectedTime: settings.bibleReadingTime,
      );
    } else {
      await _cancelReminder(_bibleReadingReminderId);
    }

    if (settings.prayerEnabled) {
      await _scheduleReminderSafely(
        id: _prayerReminderId,
        title: 'Prayer Reminder',
        body: 'Take a moment to pray.',
        selectedTime: settings.prayerTime,
      );
    } else {
      await _cancelReminder(_prayerReminderId);
    }
  }

  Future<void> cancelAllReminders() async {
    await _cancelReminder(_bibleReadingReminderId);
    await _cancelReminder(_prayerReminderId);
  }

  Future<void> _cancelReminder(int id) async {
    try {
      if (!_initialized) {
        await init(onOpenToday: _onOpenToday);
      }
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('ReminderService cancel failed: $e');
    }
  }

  Future<void> _scheduleReminderSafely({
    required int id,
    required String title,
    required String body,
    required TimeOfDay selectedTime,
  }) async {
    try {
      if (!_initialized) {
        await init(onOpenToday: _onOpenToday);
      }

      _initializeTimezoneIfNeeded();

      await _plugin.cancel(id);

      const androidDetails = AndroidNotificationDetails(
        'daily_faith_reminders',
        'Faith Reminders',
        channelDescription: 'Daily reminders for Bible reading and prayer.',
        importance: Importance.high,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails();

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOf(selectedTime),
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: 'open_today',
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      // Never crash the app if scheduling fails.
      debugPrint('ReminderService schedule failed: $e');
    }
  }

  void _initializeTimezoneIfNeeded() {
    if (_tzInitialized) return;
    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('ReminderService timezone init failed: $e');
    }
    _tzInitialized = true;
  }

  tz.TZDateTime _nextInstanceOf(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  void _onNotificationResponse(NotificationResponse response) {
    if (response.payload == 'open_today') {
      _onOpenToday?.call();
    }
  }
}
