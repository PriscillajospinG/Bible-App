import 'package:flutter/material.dart';

import '../../core/service_locator.dart';
import 'widgets/font_size_slider.dart';
import 'widgets/settings_tile.dart';
import 'widgets/theme_selector.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _translation;
  late ThemeMode _themeMode;
  late TimeOfDay _reminderTime;
  late String _readingPlan;
  late double _fontScale;
  late bool _highContrast;
  late bool _largeVerseText;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _translation = settingsService.preferredTranslation;
    _themeMode = settingsService.themeMode;
    _reminderTime = settingsService.reminderTime;
    _readingPlan = settingsService.selectedReadingPlan;
    _fontScale = accessibilityService.fontScale;
    _highContrast = accessibilityService.highContrast;
    _largeVerseText = accessibilityService.largeVerseText;
  }

  Future<void> _saveTranslation(String value) async {
    setState(() => _translation = value);
    await settingsService.savePreferredTranslation(value);
    await bibleRepo.ensureLoaded(value);
    appPreferencesNotifier.value++;
  }

  Future<void> _saveTheme(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    await settingsService.saveThemeMode(mode);
    appPreferencesNotifier.value++;
  }

  Future<void> _pickReminder() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      helpText: 'Set daily reminder',
    );
    if (picked == null) return;

    setState(() => _reminderTime = picked);
    await settingsService.saveReminderTime(picked);
    await reminderService.updateReminder(enabled: true, time: picked);
    appPreferencesNotifier.value++;
  }

  Future<void> _savePlan(String planName) async {
    setState(() => _readingPlan = planName);
    await settingsService.saveSelectedReadingPlan(planName);
    await readingPlanService.selectPlan(planName);
  }

  Future<void> _saveFontScale(double value) async {
    setState(() => _fontScale = value);
    await accessibilityService.saveFontScale(value);
    appPreferencesNotifier.value++;
  }

  Future<void> _saveHighContrast(bool value) async {
    setState(() => _highContrast = value);
    await accessibilityService.saveHighContrast(value);
    appPreferencesNotifier.value++;
  }

  Future<void> _saveLargeVerseText(bool value) async {
    setState(() => _largeVerseText = value);
    await accessibilityService.saveLargeVerseText(value);
    appPreferencesNotifier.value++;
  }

  Future<void> _exportData() async {
    setState(() => _busy = true);
    try {
      final path = await dataExportService.exportUserData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export saved at $path'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset app data?'),
        content: const Text(
          'This will clear local preferences, journal, bookmarks, highlights, and progress data. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      await dataExportService.resetAllData();
      await settingsService.init();
      await accessibilityService.init();
      await streakService.loadCurrentStreak();
      appPreferencesNotifier.value++;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('App data has been reset.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final planNames = readingPlanService.availablePlans.map((e) => e.name).toList();
    final translations = bibleRepo.getTranslations();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: IgnorePointer(
        ignoring: _busy,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const SizedBox(height: 10),
            SettingsTile(
              leading: const Icon(Icons.translate_rounded),
              title: 'Preferred Bible Translation',
              subtitle: 'Used for quick open and plan reading',
              trailing: DropdownButton<String>(
                value: _translation,
                underline: const SizedBox.shrink(),
                items: translations
                    .map((t) => DropdownMenuItem<String>(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) _saveTranslation(v);
                },
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.brightness_6_outlined),
                        SizedBox(width: 8),
                        Text('Theme', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ThemeSelector(current: _themeMode, onChanged: _saveTheme),
                  ],
                ),
              ),
            ),
            SettingsTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: 'Daily Reminder Time',
              subtitle: _reminderTime.format(context),
              onTap: _pickReminder,
            ),
            SettingsTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: 'Reading Plan',
              subtitle: _readingPlan,
              trailing: DropdownButton<String>(
                value: _readingPlan,
                underline: const SizedBox.shrink(),
                items: planNames
                    .map((name) => DropdownMenuItem<String>(
                          value: name,
                          child: SizedBox(width: 180, child: Text(name, overflow: TextOverflow.ellipsis)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) _savePlan(v);
                },
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.accessibility_new_rounded),
                        SizedBox(width: 8),
                        Text('Accessibility', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FontSizeSlider(value: _fontScale, onChanged: _saveFontScale),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('High Contrast Mode'),
                      value: _highContrast,
                      onChanged: _saveHighContrast,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Larger Verse Text'),
                      value: _largeVerseText,
                      onChanged: _saveLargeVerseText,
                    ),
                  ],
                ),
              ),
            ),
            SettingsTile(
              leading: const Icon(Icons.download_rounded),
              title: 'Export User Data (JSON)',
              subtitle: 'Journal, bookmarks, highlights, progress, streak',
              onTap: _exportData,
            ),
            SettingsTile(
              leading: Icon(Icons.delete_forever_rounded, color: Colors.red.shade700),
              title: 'Reset App Data',
              subtitle: 'Clear local data and settings',
              onTap: _resetData,
              destructive: true,
            ),
          ],
        ),
      ),
    );
  }
}
