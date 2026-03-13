import 'package:flutter/material.dart';

import 'core/service_locator.dart';
import 'data/services/favorites_service.dart';
import 'data/services/panic_search_service.dart';
import 'features/journal/repositories/journal_repository.dart';
import 'features/journal/services/emotion_detection_service.dart';
import 'features/journal/services/journal_storage_service.dart';
import 'features/journal/services/prayer_generator_service.dart';
import 'features/journal/services/verse_suggestion_service.dart';
import 'features/bible/services/bible_search_service.dart';
import 'features/bible/services/bookmark_service.dart';
import 'features/bible/services/highlight_service.dart';
import 'features/home/services/reading_plan_service.dart';
import 'features/home/services/reading_progress_service.dart';
import 'features/home/services/reminder_notification_service.dart';
import 'features/home/services/streak_service.dart';
import 'features/settings/accessibility_service.dart';
import 'features/settings/bible_cache_service.dart';
import 'features/settings/data_export_service.dart';
import 'features/settings/settings_service.dart';
import 'features/panic/services/panic_history_service.dart';
import 'features/panic/services/semantic_panic_search_service.dart';
import 'ui/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load Bible (KJV) and panic dataset concurrently.
  await Future.wait([
    bibleRepo.init(),
    panicRepo.init(),
  ]);

  // Wire up services that depend on repository data.
  panicSearchService = PanicSearchService(repository: panicRepo);
  favoritesService = FavoritesService();
  await favoritesService.init();

  // Journal services.
  final journalStorage = JournalStorageService();
  await journalStorage.init();
  journalRepo = JournalRepository(storage: journalStorage);
  emotionDetectionService = EmotionDetectionService();
  verseSuggestionService = VerseSuggestionService(bibleRepo: bibleRepo);
  prayerGeneratorService = PrayerGeneratorService();

  // Bible Step 6 services.
  bibleSearchService = BibleSearchService(repository: bibleRepo);
  final bookmarkStorage = BookmarkService();
  await bookmarkStorage.init();
  bookmarkService = bookmarkStorage;
  final highlightStorage = HighlightService();
  await highlightStorage.init();
  highlightService = highlightStorage;

  // Home Step 7 services.
  readingProgressService = ReadingProgressService();
  readingPlanService = ReadingPlanService();
  streakService = StreakService();
  await streakService.updateStreak();
  reminderNotificationService = ReminderNotificationService();
  await reminderNotificationService.init();

  // Settings Step 8 services.
  settingsService = SettingsService();
  await settingsService.init();
  accessibilityService = AccessibilityService();
  await accessibilityService.init();
  dataExportService = DataExportService();
  bibleCacheService = BibleCacheService(repository: bibleRepo);

  // Ensure preferred translation is ready for quick Bible access.
  await bibleRepo.ensureLoaded(settingsService.preferredTranslation);

  // Keep plan selection synchronized with settings.
  await readingPlanService.selectPlan(settingsService.selectedReadingPlan);

  // Panic Step 5 services.
  semanticPanicSearchService =
      SemanticPanicSearchService(repository: panicRepo);
  final panicHistory = PanicHistoryService();
  await panicHistory.init();
  panicHistoryService = panicHistory;

  debugPrint('Bible loaded — ${bibleRepo.allBookNames.length} books (KJV)');
  debugPrint('Panic dataset — ${panicRepo.count} entries');
  debugPrint('Favorites restored — ${favoritesService.count} saved');
  debugPrint('Bookmarks restored — ${bookmarkService.getBookmarks().length}');
  debugPrint('Highlights restored — ${highlightService.getHighlights().length}');
  debugPrint('Reading streak — ${streakService.getCurrentStreak()} days');
  debugPrint('Journal entries — ${journalRepo.count} entries');
  debugPrint('Panic history — ${panicHistoryService.count} sessions');

  runApp(const BibleApp());
}

class BibleApp extends StatelessWidget {
  const BibleApp({super.key});

  ThemeData _buildTheme(Brightness brightness) {
    final seed = accessibilityService.highContrast
        ? const Color(0xFF8A5B2E)
        : const Color(0xFF6B4226);

    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: brightness,
        contrastLevel: accessibilityService.highContrast ? 0.45 : 0,
      ),
      useMaterial3: true,
      fontFamily: 'Georgia',
    );

    final textTheme = base.textTheme.apply(
      fontSizeFactor: accessibilityService.fontScale,
      bodyColor: accessibilityService.highContrast
          ? (brightness == Brightness.dark ? Colors.white : Colors.black)
          : null,
      displayColor: accessibilityService.highContrast
          ? (brightness == Brightness.dark ? Colors.white : Colors.black)
          : null,
    );

    return base.copyWith(textTheme: textTheme);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: appPreferencesNotifier,
      builder: (_, __, ___) => MaterialApp(
        title: 'Bible App',
        debugShowCheckedModeBanner: false,
        themeMode: settingsService.themeMode,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        home: const HomeScreen(),
      ),
    );
  }
}
