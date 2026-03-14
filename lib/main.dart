import 'package:flutter/material.dart';

import 'ai/gemma_model_service.dart';
import 'ai/emotion_detection_service.dart';
import 'ai/bible_api_service.dart';
import 'ai/verse_cache_service.dart';
import 'ai/spiritual_guidance_service.dart';
import 'ai/journal_reflection_service.dart';
import 'core/service_locator.dart';
import 'data/repositories/bible_repository.dart';
import 'data/services/favorites_service.dart';
import 'data/services/panic_search_service.dart';
import 'features/journal/repositories/journal_repository.dart';
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

  // Load core datasets with guarded startup.
  try {
    await Future.wait([
      bibleRepo.init(),
      panicRepo.init(),
    ]);
  } catch (e) {
    debugPrint('Core dataset initialization failed: $e');
    // Retry Bible load with explicit fallback chain to prevent boot crash.
    for (final t in [
      BibleRepository.defaultTranslation,
      'NIV',
      'KJV',
      'AMP',
    ]) {
      try {
        await bibleRepo.ensureLoaded(t);
        break;
      } catch (_) {
        // Try next translation.
      }
    }
    try {
      await panicRepo.init();
    } catch (inner) {
      debugPrint('Panic dataset initialization failed: $inner');
    }
  }

  // Wire up services that depend on repository data.
  panicSearchService = PanicSearchService(repository: panicRepo);
  favoritesService = FavoritesService();
  try {
    await favoritesService.init();
  } catch (e) {
    debugPrint('Favorites init failed: $e');
  }

  // Journal services.
  final journalStorage = JournalStorageService();
  try {
    await journalStorage.init();
  } catch (e) {
    debugPrint('Journal storage init failed: $e');
  }
  journalRepo = JournalRepository(storage: journalStorage);
  emotionDetectionService = EmotionDetectionService();
  verseSuggestionService = VerseSuggestionService(bibleRepo: bibleRepo);
  prayerGeneratorService = PrayerGeneratorService();

  // Bible Step 6 services.
  bibleSearchService = BibleSearchService(repository: bibleRepo);
  final bookmarkStorage = BookmarkService();
  try {
    await bookmarkStorage.init();
  } catch (e) {
    debugPrint('Bookmark init failed: $e');
  }
  bookmarkService = bookmarkStorage;
  final highlightStorage = HighlightService();
  try {
    await highlightStorage.init();
  } catch (e) {
    debugPrint('Highlight init failed: $e');
  }
  highlightService = highlightStorage;

  // Home Step 7 services.
  readingProgressService = ReadingProgressService();
  readingPlanService = ReadingPlanService();
  streakService = StreakService();
  try {
    await streakService.updateStreak();
  } catch (e) {
    debugPrint('Streak update failed: $e');
  }
  reminderNotificationService = ReminderNotificationService();
  try {
    await reminderNotificationService.init();
  } catch (e) {
    debugPrint('Reminder notification init failed: $e');
  }

  // Local AI (Gemma) service.
  gemmaModelService = GemmaModelService();
  try {
    await gemmaModelService.initializeModel();
    debugPrint('Gemma model initialized at ${gemmaModelService.modelPathOrEmpty}');
  } catch (e) {
    // Keep app fully functional even if model/native engine isn't ready yet.
    debugPrint('Gemma model not initialized: $e');
  }

  // RAG pipeline services (Bible API + verse cache + guidance + reflection).
  bibleApiService = BibleApiService();
  verseCacheService = VerseCacheService();
  try {
    await verseCacheService.init();
  } catch (e) {
    debugPrint('VerseCacheService init failed: $e');
  }
  spiritualGuidanceService = SpiritualGuidanceService(
    emotionDetection: emotionDetectionService,
    bibleApi: bibleApiService,
    verseCache: verseCacheService,
    modelService: gemmaModelService,
  );
  try {
    await spiritualGuidanceService.init();
  } catch (e) {
    debugPrint('SpiritualGuidanceService init failed: $e');
  }
  journalReflectionService = JournalReflectionService(
    emotionDetection: emotionDetectionService,
    bibleApi: bibleApiService,
    verseCache: verseCacheService,
    modelService: gemmaModelService,
  );
  try {
    await journalReflectionService.init();
  } catch (e) {
    debugPrint('JournalReflectionService init failed: $e');
  }

  // Settings Step 8 services.
  settingsService = SettingsService();
  try {
    await settingsService.init();
  } catch (e) {
    debugPrint('Settings init failed: $e');
  }
  accessibilityService = AccessibilityService();
  try {
    await accessibilityService.init();
  } catch (e) {
    debugPrint('Accessibility init failed: $e');
  }
  dataExportService = DataExportService();
  bibleCacheService = BibleCacheService(repository: bibleRepo);

  // Ensure preferred translation is ready for quick Bible access.
  try {
    await bibleRepo.ensureLoaded(settingsService.preferredTranslation);
  } catch (e) {
    debugPrint('Preferred translation load failed: $e');
    try {
      await bibleRepo.ensureLoaded(BibleRepository.defaultTranslation);
    } catch (_) {
      // Continue boot with whichever translation is already loaded.
    }
  }

  // Keep plan selection synchronized with settings.
  try {
    await readingPlanService.selectPlan(settingsService.selectedReadingPlan);
  } catch (e) {
    debugPrint('Reading plan sync failed: $e');
  }

  // Panic Step 5 services.
  semanticPanicSearchService =
      SemanticPanicSearchService(repository: panicRepo);
  final panicHistory = PanicHistoryService();
  try {
    await panicHistory.init();
  } catch (e) {
    debugPrint('Panic history init failed: $e');
  }
  panicHistoryService = panicHistory;

  debugPrint(
    'Bible loaded — ${bibleRepo.allBookNames.length} books (${BibleRepository.defaultTranslation})',
  );
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
