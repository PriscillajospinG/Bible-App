import 'package:flutter/material.dart';

import '../../../core/service_locator.dart';
import '../../bible/screens/verse_reader_screen.dart';
import '../../journal/models/verse_of_day.dart';
import '../../journal/widgets/prayer_point_list.dart';
import '../../journal/widgets/verse_of_day_card.dart';
import '../../settings/settings_screen.dart';
import '../services/reading_plan_service.dart';
import '../services/reading_progress_service.dart';
import '../widgets/continue_reading_card.dart';
import '../widgets/reading_plan_progress_card.dart';
import '../widgets/streak_display_card.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  VerseOfDay? _verse;
  List<String> _prayers = [];
  bool _isLoading = true;

  ReadingPosition? _readingPosition;
  ReadingPlanProgress? _planProgress;
  ReadingPlanDay? _todayAssignment;
  ReadingPlan? _activePlan;
  late int _streak;
  TimeOfDay _bibleReminderTime = const TimeOfDay(hour: 6, minute: 0);
  bool _bibleReminderEnabled = true;
  TimeOfDay _prayerReminderTime = const TimeOfDay(hour: 6, minute: 40);
  bool _prayerReminderEnabled = true;

  @override
  void initState() {
    super.initState();
    journalRefreshNotifier.addListener(_onRefresh);
    _loadTodayData();
  }

  @override
  void dispose() {
    journalRefreshNotifier.removeListener(_onRefresh);
    super.dispose();
  }

  void _onRefresh() => _loadTodayData();

  Future<void> _loadTodayData() async {
    final latestEntry = journalRepo.getLatestEntry();
    final latestKyrie = panicHistoryService.getLatestEntry();
    final emotions = latestEntry != null && latestEntry.detectedEmotions.isNotEmpty
        ? latestEntry.detectedEmotions
        : ['peace'];

    final verse = await verseOfDayService.getVerseForToday(emotions);
    final prayers = await prayerPointService.getPrayerPointsForToday(
      latestJournal: latestEntry,
      latestKyrie: latestKyrie,
    );

    final position = await readingProgressService.getLastReadingPosition();
    final progress = await readingPlanService.getProgress();
    final assignment = await readingPlanService.getTodayAssignment();
    final reminderSettings = await reminderService.loadSettings();

    setState(() {
      _verse = verse;
      _prayers = prayers;
      _readingPosition = position;
      _planProgress = progress;
      _todayAssignment = assignment;
      _activePlan = readingPlanService.getPlanByName(progress.planName);
      _streak = streakService.getCurrentStreak();
      _bibleReminderTime = reminderSettings.bibleReadingTime;
      _bibleReminderEnabled = reminderSettings.bibleReadingEnabled;
      _prayerReminderTime = reminderSettings.prayerTime;
      _prayerReminderEnabled = reminderSettings.prayerEnabled;
      _isLoading = false;
    });
  }

  Future<void> _openContinueReading() async {
    final position = _readingPosition;
    if (position == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerseReaderScreen(
          translation: position.translation,
          bookName: position.book,
          initialChapter: position.chapter,
        ),
      ),
    );
    if (!mounted) return;
    await _loadTodayData();
  }

  Future<void> _openTodayPlanReading() async {
    final assignment = _todayAssignment;
    if (assignment == null) return;

    final preferredTranslation = settingsService.preferredTranslation;
    await bibleRepo.ensureLoaded(preferredTranslation);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerseReaderScreen(
          translation: preferredTranslation,
          bookName: assignment.book,
          initialChapter: assignment.chapter,
        ),
      ),
    );
    if (!mounted) return;
    await _loadTodayData();
  }

  Future<void> _markPlanComplete() async {
    await readingPlanService.markTodayCompleted();
    if (!mounted) return;
    await _loadTodayData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reading plan updated.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final verse = _verse;
    final plan = _activePlan;
    final progress = _planProgress;
    final assignment = _todayAssignment;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F0),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadTodayData,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 28),
                  children: [
                    _Header(greeting: _greeting()),
                    const SizedBox(height: 14),
                    StreakDisplayCard(streak: _streak),
                    const SizedBox(height: 16),
                    if (verse != null) VerseOfDayCard(verse: verse),
                    const SizedBox(height: 18),
                    PrayerPointList(prayers: _prayers),
                    const SizedBox(height: 14),
                    ContinueReadingCard(
                      position: _readingPosition,
                      onContinue: _openContinueReading,
                    ),
                    const SizedBox(height: 14),
                    if (plan != null && progress != null && assignment != null)
                      ReadingPlanProgressCard(
                        plan: plan,
                        completedDays: progress.completedDays,
                        todayAssignment: assignment,
                        onMarkComplete: _markPlanComplete,
                      ),
                    const SizedBox(height: 10),
                    _TodayActionsCard(
                      bibleReminderEnabled: _bibleReminderEnabled,
                      bibleReminderTime: _bibleReminderTime,
                      prayerReminderEnabled: _prayerReminderEnabled,
                      prayerReminderTime: _prayerReminderTime,
                      onOpenPlanReading: _openTodayPlanReading,
                      onOpenPanic: () => tabSwitchRequest.value = 3,
                      onOpenJournal: () => tabSwitchRequest.value = 2,
                      onOpenSettings: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.greeting});

  final String greeting;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: TextStyle(
              fontSize: 14,
              color: Colors.brown.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Today Dashboard',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3B2A1A),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayActionsCard extends StatelessWidget {
  const _TodayActionsCard({
    required this.bibleReminderEnabled,
    required this.bibleReminderTime,
    required this.prayerReminderEnabled,
    required this.prayerReminderTime,
    required this.onOpenPlanReading,
    required this.onOpenPanic,
    required this.onOpenJournal,
    required this.onOpenSettings,
  });

  final bool bibleReminderEnabled;
  final TimeOfDay bibleReminderTime;
  final bool prayerReminderEnabled;
  final TimeOfDay prayerReminderTime;
  final VoidCallback onOpenPlanReading;
  final VoidCallback onOpenPanic;
  final VoidCallback onOpenJournal;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3D7C0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reminder Summary',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF4A3728),
            ),
          ),
          const SizedBox(height: 10),
          _ReminderSummaryRow(
            icon: Icons.auto_stories_rounded,
            title: 'Bible Reading',
            enabled: bibleReminderEnabled,
            time: bibleReminderTime,
          ),
          const SizedBox(height: 8),
          _ReminderSummaryRow(
            icon: Icons.volunteer_activism_rounded,
            title: 'Prayer',
            enabled: prayerReminderEnabled,
            time: prayerReminderTime,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenPlanReading,
                  icon: const Icon(Icons.auto_stories_rounded),
                  label: const Text('Today\'s Plan'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onOpenPanic,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4226),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.volunteer_activism_rounded),
                  label: const Text('Kyrie'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onOpenJournal,
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('Open Journal'),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onOpenSettings,
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Open Settings'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderSummaryRow extends StatelessWidget {
  const _ReminderSummaryRow({
    required this.icon,
    required this.title,
    required this.enabled,
    required this.time,
  });

  final IconData icon;
  final String title;
  final bool enabled;
  final TimeOfDay time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F4EA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6B4226)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A3728),
              ),
            ),
          ),
          Text(
            enabled ? time.format(context) : 'Off',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: enabled ? const Color(0xFF6B4226) : Colors.brown.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
