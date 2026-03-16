import 'package:flutter/material.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'ai/services/gemma_model_service.dart';
import 'ai/services/emotion_detection_service.dart';
import 'ai/services/emotion_verses_repository.dart';
import 'ai/services/fallback_bible_service.dart';
import 'ai/services/bible_api_service.dart';
import 'ai/services/verse_cache_service.dart';
import 'ai/services/spiritual_guidance_service.dart';
import 'ai/services/journal_reflection_service.dart';
import 'core/services/service_locator.dart';
import 'data/repositories/bible_repository.dart';
import 'data/datasources/favorites_service.dart';
import 'data/datasources/panic_dataset_service.dart';
import 'data/datasources/panic_search_service.dart';
import 'features/journal/repositories/journal_repository.dart';
import 'features/journal/services/journal_storage_service.dart';
import 'features/journal/services/prayer_generator_service.dart';
import 'features/journal/services/verse_suggestion_service.dart';
import 'features/bible/services/bible_search_service.dart';
import 'features/bible/services/bookmark_service.dart';
import 'features/bible/services/highlight_service.dart';
import 'features/reading_plan/services/reading_plan_service.dart';
import 'features/home/services/reading_progress_service.dart';
import 'features/reminders/services/reminder_service.dart';
import 'features/home/services/streak_service.dart';
import 'features/home/services/verse_of_day_service.dart';
import 'features/home/services/prayer_point_service.dart';
import 'features/settings/services/accessibility_service.dart';
import 'features/settings/services/bible_cache_service.dart';
import 'features/settings/services/data_export_service.dart';
import 'features/settings/services/settings_service.dart';
import 'features/kyrie/services/panic_history_service.dart';
import 'features/kyrie/services/panic_guidance_service.dart';
import 'features/kyrie/services/semantic_panic_search_service.dart';
import 'routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env asset.
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('dotenv load failed (continuing without env vars): $e');
  }

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
  panicDatasetService = PanicDatasetService();
  try {
    await panicDatasetService.init();
  } catch (e) {
    debugPrint('PanicDatasetService init failed: $e');
  }
  panicSearchService = PanicSearchService(datasetService: panicDatasetService);
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
  readingPlanService = ReadingPlanService(repository: bibleRepo);
  try {
    await readingPlanService.init();
  } catch (e) {
    debugPrint('ReadingPlanService init failed: $e');
  }
  streakService = StreakService();
  try {
    await streakService.updateStreak();
  } catch (e) {
    debugPrint('Streak update failed: $e');
  }
  reminderService = ReminderService();
  try {
    await reminderService.init(
      onOpenToday: () => tabSwitchRequest.value = 0,
    );
    await reminderService.rescheduleAll();
  } catch (e) {
    debugPrint('Reminder service init failed: $e');
  }

  // Local AI (Gemma) service.
  gemmaModelService = GemmaModelService();
  aiModelReadyNotifier.value = false;
  aiModelInitInProgressNotifier.value = false;

  // RAG pipeline services (Bible API + verse cache + guidance + journal AI).
  // Shared emotion → verse map (loaded once, injected into both RAG services).
  emotionVersesRepository = EmotionVersesRepository();
  try {
    await emotionVersesRepository.init();
  } catch (e) {
    debugPrint('EmotionVersesRepository init failed: $e');
  }

  // Offline-first Bible fallback (KJV flat JSON, no network needed).
  fallbackBibleService = FallbackBibleService();
  try {
    await fallbackBibleService.init();
  } catch (e) {
    debugPrint('FallbackBibleService init failed: $e');
  }

  // Verse cache must be initialized before BibleApiService so it can be injected.
  verseCacheService = VerseCacheService();
  try {
    await verseCacheService.init();
  } catch (e) {
    debugPrint('VerseCacheService init failed: $e');
  }

  bibleApiService = BibleApiService(fallback: fallbackBibleService, cache: verseCacheService);

  // verseSuggestionService is wired here (after bibleApiService) so it can
  // use the API for verse lookups with built-in cache + fallback.
  verseSuggestionService = VerseSuggestionService(
    bibleRepo: bibleRepo,
    bibleApi: bibleApiService,
  );
  verseOfDayService = VerseOfDayService(
    bibleApi: bibleApiService,
  );
  prayerPointService = PrayerPointService(
    emotionDetection: emotionDetectionService,
    modelService: gemmaModelService,
    verseSuggestionService: verseSuggestionService,
  );

  spiritualGuidanceService = SpiritualGuidanceService(
    emotionDetection: emotionDetectionService,
    bibleApi: bibleApiService,
    verseCache: verseCacheService,
    emotionVerses: emotionVersesRepository,
    modelService: gemmaModelService,
  );
  journalReflectionService = JournalReflectionService(
    emotionDetection: emotionDetectionService,
    bibleApi: bibleApiService,
    verseCache: verseCacheService,
    emotionVerses: emotionVersesRepository,
    modelService: gemmaModelService,
  );

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
  panicGuidanceService = PanicGuidanceService(
    emotionDetection: emotionDetectionService,
    searchService: panicSearchService,
    modelService: gemmaModelService,
    bibleApi: bibleApiService,
  );
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
        initialRoute: AppRouter.home,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
