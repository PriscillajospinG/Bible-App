import 'package:flutter/material.dart';

import '../../../core/services/service_locator.dart';
import '../widgets/font_size_slider.dart';
import '../widgets/settings_tile.dart';
import '../widgets/theme_selector.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _customDaysController;
  late String _translation;
  late ThemeMode _themeMode;
  late String _readingPlan;
  late double _fontScale;
  late bool _highContrast;
  late bool _largeVerseText;

  bool _bibleReminderEnabled = true;
  TimeOfDay _bibleReminderTime = const TimeOfDay(hour: 6, minute: 0);
  bool _prayerReminderEnabled = true;
  TimeOfDay _prayerReminderTime = const TimeOfDay(hour: 6, minute: 40);

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _customDaysController = TextEditingController();
    _translation = settingsService.preferredTranslation;
    _themeMode = settingsService.themeMode;
    _readingPlan =
      readingPlanService.getPlanByName(settingsService.selectedReadingPlan).name;
    _fontScale = accessibilityService.fontScale;
    _highContrast = accessibilityService.highContrast;
    _largeVerseText = accessibilityService.largeVerseText;
    _loadReminderSettings();
  }

  @override
  void dispose() {
    _customDaysController.dispose();
    super.dispose();
  }

  Future<void> _loadReminderSettings() async {
    try {
      final reminderSettings = await reminderService.loadSettings();
      if (!mounted) return;
      setState(() {
        _bibleReminderEnabled = reminderSettings.bibleReadingEnabled;
        _bibleReminderTime = reminderSettings.bibleReadingTime;
        _prayerReminderEnabled = reminderSettings.prayerEnabled;
        _prayerReminderTime = reminderSettings.prayerTime;
      });
    } catch (_) {
      // Keep defaults when local reminder settings cannot be loaded.
    }
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

  Future<void> _savePlan(String planName) async {
    setState(() => _readingPlan = planName);
    await settingsService.saveSelectedReadingPlan(planName);
    await readingPlanService.selectPlan(planName);
  }

  String _durationLabelFromPlanName(String planName) {
    final lower = planName.toLowerCase();
    if (lower.contains('custom')) return 'Custom';
    final match = RegExp(r'(\d+)').firstMatch(planName);
    final days = int.tryParse(match?.group(1) ?? '');
    if (days == null) return '30 days';
    return '$days days';
  }

  Future<void> _onDurationChanged(String label) async {
    if (label == 'Custom') {
      final existing = await readingPlanService.getCustomPlanDays();
      if (!mounted) return;
      final customDays = await _pickCustomPlanDays(existing);
      if (!mounted) return;
      if (customDays == null) return;

      await readingPlanService.selectPlanByDays(customDays, custom: true);
      final planName = readingPlanService.getPlanByName('Custom Plan').name;
      await _savePlan(planName);
      if (!mounted) return;
      setState(() => _readingPlan = planName);
      return;
    }

    final days = int.tryParse(label.split(' ').first);
    if (days == null) return;
    await readingPlanService.selectPlanByDays(days);
    if (!mounted) return;
    final planName = readingPlanService.getPlanByName('$days Day Plan').name;
    await _savePlan(planName);
    if (!mounted) return;
    setState(() => _readingPlan = planName);
  }

  Future<int?> _pickCustomPlanDays(int initialDays) async {
    _customDaysController.text = initialDays.toString();
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Custom Plan Duration'),
        content: TextField(
          controller: _customDaysController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Number of days',
            hintText: 'e.g. 120',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(_customDaysController.text.trim());
              if (value == null || value < 7 || value > 1500) {
                Navigator.of(dialogContext).pop();
                return;
              }
              Navigator.of(dialogContext).pop(value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (!mounted) return null;
    return result;
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

  Future<void> _toggleBibleReminder(bool enabled) async {
    setState(() => _bibleReminderEnabled = enabled);
    await reminderService.updateBibleReadingReminder(
      enabled: enabled,
      time: _bibleReminderTime,
    );
  }

  Future<void> _togglePrayerReminder(bool enabled) async {
    setState(() => _prayerReminderEnabled = enabled);
    await reminderService.updatePrayerReminder(
      enabled: enabled,
      time: _prayerReminderTime,
    );
  }

  Future<void> _pickBibleReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _bibleReminderTime,
      helpText: 'Bible reading reminder time',
    );
    if (picked == null) return;

    setState(() => _bibleReminderTime = picked);
    await reminderService.updateBibleReadingReminder(
      enabled: _bibleReminderEnabled,
      time: picked,
    );
  }

  Future<void> _pickPrayerReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _prayerReminderTime,
      helpText: 'Prayer reminder time',
    );
    if (picked == null) return;

    setState(() => _prayerReminderTime = picked);
    await reminderService.updatePrayerReminder(
      enabled: _prayerReminderEnabled,
      time: picked,
    );
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset app data?'),
        content: const Text(
          'This will clear local preferences, journal, bookmarks, highlights, and progress data. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      await dataExportService.resetAllData();
      await settingsService.init();
      await accessibilityService.init();
      await streakService.loadCurrentStreak();
      await _loadReminderSettings();
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
    final durationOptions = readingPlanService.durationOptions;
    final resolvedDuration = _durationLabelFromPlanName(_readingPlan);
    final selectedDuration = durationOptions.contains(resolvedDuration)
        ? resolvedDuration
        : '30 days';
    final translations = bibleRepo.getTranslations();

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF8F0),
        elevation: 0,
        title: const Text('Profile & Settings'),
      ),
      body: IgnorePointer(
        ignoring: _busy,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            const _SectionHeader(
              title: 'Reading Preferences',
              icon: Icons.menu_book_outlined,
            ),
            SettingsTile(
              leading: const Icon(Icons.translate_rounded),
              title: 'Preferred Bible Translation',
              subtitle: 'Used for quick open and reading plan passages',
              trailing: DropdownButton<String>(
                value: _translation,
                underline: const SizedBox.shrink(),
                items: translations
                    .map((t) => DropdownMenuItem<String>(
                          value: t,
                          child: Text(t),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) _saveTranslation(v);
                },
              ),
            ),
            SettingsTile(
              leading: const Icon(Icons.menu_book_rounded),
              title: 'Reading Plan Duration',
              subtitle: _readingPlan,
              trailing: DropdownButton<String>(
                value: selectedDuration,
                underline: const SizedBox.shrink(),
                items: durationOptions
                    .map(
                      (name) => DropdownMenuItem<String>(
                        value: name,
                        child: SizedBox(
                          width: 180,
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) _onDurationChanged(v);
                },
              ),
            ),
            const SizedBox(height: 4),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.brightness_6_outlined),
                        SizedBox(width: 8),
                        Text(
                          'Theme',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ThemeSelector(current: _themeMode, onChanged: _saveTheme),
                  ],
                ),
              ),
            ),

            const _SectionHeader(
              title: 'Reminders',
              icon: Icons.notifications_active_outlined,
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                child: Column(
                  children: [
                    _ReminderRow(
                      title: 'Bible Reading Reminder',
                      subtitle: 'Start your day with God\'s Word.',
                      icon: Icons.auto_stories_rounded,
                      enabled: _bibleReminderEnabled,
                      time: _bibleReminderTime,
                      onToggle: _toggleBibleReminder,
                      onPickTime: _pickBibleReminderTime,
                    ),
                    const Divider(height: 18),
                    _ReminderRow(
                      title: 'Prayer Reminder',
                      subtitle: 'Take a moment to pray.',
                      icon: Icons.volunteer_activism_rounded,
                      enabled: _prayerReminderEnabled,
                      time: _prayerReminderTime,
                      onToggle: _togglePrayerReminder,
                      onPickTime: _pickPrayerReminderTime,
                    ),
                  ],
                ),
              ),
            ),

            const _SectionHeader(
              title: 'Accessibility',
              icon: Icons.accessibility_new_rounded,
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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

            const _SectionHeader(
              title: 'Data',
              icon: Icons.folder_outlined,
            ),
            SettingsTile(
              leading: const Icon(Icons.download_rounded),
              title: 'Export User Data (JSON)',
              subtitle: 'Journal, bookmarks, highlights, progress, streak',
              onTap: _exportData,
            ),
            SettingsTile(
              leading:
                  Icon(Icons.delete_forever_rounded, color: Colors.red.shade700),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6B4226), size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B4226),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.time,
    required this.onToggle,
    required this.onPickTime,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final TimeOfDay time;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFF0E9D2),
            foregroundColor: const Color(0xFF6B4226),
            child: Icon(icon, size: 18),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(subtitle),
          trailing: Switch(value: enabled, onChanged: onToggle),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 72, right: 10),
            child: OutlinedButton.icon(
              onPressed: onPickTime,
              icon: const Icon(Icons.schedule_rounded, size: 18),
              label: Text(enabled ? time.format(context) : '${time.format(context)} (off)'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
