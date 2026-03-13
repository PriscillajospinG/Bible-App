import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _translationKey = 'settings_preferred_translation';
  static const _themeModeKey = 'settings_theme_mode';
  static const _reminderHourKey = 'settings_reminder_hour';
  static const _reminderMinuteKey = 'settings_reminder_minute';
  static const _readingPlanKey = 'settings_reading_plan';

  String _preferredTranslation = 'KJV';
  ThemeMode _themeMode = ThemeMode.system;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  String _selectedReadingPlan = '30 Day Gospel Plan';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    _preferredTranslation = prefs.getString(_translationKey) ?? 'KJV';
    _themeMode = _themeFromString(prefs.getString(_themeModeKey) ?? 'system');

    final hour = prefs.getInt(_reminderHourKey) ?? 8;
    final minute = prefs.getInt(_reminderMinuteKey) ?? 0;
    _reminderTime = TimeOfDay(hour: hour, minute: minute);

    _selectedReadingPlan =
        prefs.getString(_readingPlanKey) ?? '30 Day Gospel Plan';
  }

  String get preferredTranslation => _preferredTranslation;
  ThemeMode get themeMode => _themeMode;
  TimeOfDay get reminderTime => _reminderTime;
  String get selectedReadingPlan => _selectedReadingPlan;

  Future<void> savePreferredTranslation(String translation) async {
    _preferredTranslation = translation.toUpperCase();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_translationKey, _preferredTranslation);
  }

  Future<String> getPreferredTranslation() async {
    final prefs = await SharedPreferences.getInstance();
    _preferredTranslation = prefs.getString(_translationKey) ?? _preferredTranslation;
    return _preferredTranslation;
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _themeToString(mode));
  }

  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode =
        _themeFromString(prefs.getString(_themeModeKey) ?? _themeToString(_themeMode));
    return _themeMode;
  }

  Future<void> saveReminderTime(TimeOfDay time) async {
    _reminderTime = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderHourKey, time.hour);
    await prefs.setInt(_reminderMinuteKey, time.minute);
  }

  Future<TimeOfDay> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    _reminderTime = TimeOfDay(
      hour: prefs.getInt(_reminderHourKey) ?? _reminderTime.hour,
      minute: prefs.getInt(_reminderMinuteKey) ?? _reminderTime.minute,
    );
    return _reminderTime;
  }

  Future<void> saveSelectedReadingPlan(String planName) async {
    _selectedReadingPlan = planName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_readingPlanKey, planName);
  }

  Future<String> getSelectedReadingPlan() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedReadingPlan =
        prefs.getString(_readingPlanKey) ?? _selectedReadingPlan;
    return _selectedReadingPlan;
  }

  String _themeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  ThemeMode _themeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
