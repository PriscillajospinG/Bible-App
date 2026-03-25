import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'ai/services/gemma_model_service.dart';
import 'ai/services/emotion_detection_service.dart';
import 'ai/services/emotion_verses_repository.dart';
import 'ai/services/spiritual_guidance_service.dart';
import 'ai/services/journal_reflection_service.dart';
import 'core/services/service_locator.dart';
import 'core/services/local_bible_service.dart';
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
  debugPrint('App started');

  // Load environment variables from .env asset.
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('dotenv load failed (continuing without env vars): $e');
  }

  // Wire up service instances first so the UI can render immediately.
  panicDatasetService = PanicDatasetService();
  panicSearchService = PanicSearchService(datasetService: panicDatasetService);
  favoritesService = FavoritesService();

  // Journal services.
  final journalStorage = JournalStorageService();
  journalRepo = JournalRepository(storage: journalStorage);
  emotionDetectionService = EmotionDetectionService();
  prayerGeneratorService = PrayerGeneratorService();

  // Bible Step 6 services.
  bibleSearchService = BibleSearchService(repository: bibleRepo);
  final bookmarkStorage = BookmarkService();
  bookmarkService = bookmarkStorage;
  final highlightStorage = HighlightService();
  highlightService = highlightStorage;

  // Home Step 7 services.
  readingProgressService = ReadingProgressService();
  readingPlanService = ReadingPlanService(repository: bibleRepo);
  streakService = StreakService();
  reminderService = ReminderService();

  // Local AI (Gemma) service.
  gemmaModelService = GemmaModelService();
  localBibleService = LocalBibleService(repository: bibleRepo);
  bibleDatasetReadyNotifier.value = false;
  bibleDatasetInitInProgressNotifier.value = false;
  aiModelReadyNotifier.value = false;
  aiModelInitInProgressNotifier.value = false;

  // RAG pipeline services (offline local Bible + guidance + journal AI).
  // Shared emotion → verse map (loaded once, injected into both RAG services).
  emotionVersesRepository = EmotionVersesRepository();

  // verseSuggestionService is wired here after LocalBibleService is ready so
  // all verse lookups come from the bundled NLT dataset.
  verseSuggestionService = VerseSuggestionService(
    bibleRepo: bibleRepo,
    localBible: localBibleService,
  );
  verseOfDayService = VerseOfDayService(
    localBible: localBibleService,
  );
  prayerPointService = PrayerPointService(
    emotionDetection: emotionDetectionService,
    modelService: gemmaModelService,
    verseSuggestionService: verseSuggestionService,
  );

  spiritualGuidanceService = SpiritualGuidanceService(
    emotionDetection: emotionDetectionService,
    localBible: localBibleService,
    emotionVerses: emotionVersesRepository,
    modelService: gemmaModelService,
  );
  journalReflectionService = JournalReflectionService(
    emotionDetection: emotionDetectionService,
    localBible: localBibleService,
    emotionVerses: emotionVersesRepository,
    modelService: gemmaModelService,
  );

  // Settings Step 8 services.
  settingsService = SettingsService();
  accessibilityService = AccessibilityService();
  dataExportService = DataExportService();
  bibleCacheService = BibleCacheService(repository: bibleRepo);

  // Panic Step 5 services.
  panicGuidanceService = PanicGuidanceService(
    emotionDetection: emotionDetectionService,
    searchService: panicSearchService,
    modelService: gemmaModelService,
    localBible: localBibleService,
  );
  semanticPanicSearchService =
      SemanticPanicSearchService(repository: panicRepo);
  final panicHistory = PanicHistoryService();
  panicHistoryService = panicHistory;

  runApp(const BibleApp());

  Future.microtask(_warmStartServices);
}

Future<void> _warmStartServices() async {
  debugPrint('========== WARM START SERVICES BEGIN ==========');
  // Core datasets
  try {
    await panicRepo.init();
  } catch (e) {
    debugPrint('Panic dataset initialization failed: $e');
  }

  // Persisted/local services
  try {
    await panicDatasetService.init();
  } catch (e) {
    debugPrint('PanicDatasetService init failed: $e');
  }
  try {
    await favoritesService.init();
  } catch (e) {
    debugPrint('Favorites init failed: $e');
  }
  try {
    await journalRepo.storage.init();
  } catch (e) {
    debugPrint('Journal storage init failed: $e');
  }
  try {
    await bookmarkService.init();
  } catch (e) {
    debugPrint('Bookmark init failed: $e');
  }
  try {
    await highlightService.init();
  } catch (e) {
    debugPrint('Highlight init failed: $e');
  }
  try {
    await readingPlanService.init();
  } catch (e) {
    debugPrint('ReadingPlanService init failed: $e');
  }
  try {
    await streakService.updateStreak();
  } catch (e) {
    debugPrint('Streak update failed: $e');
  }
  try {
    await reminderService.init(
      onOpenToday: () => tabSwitchRequest.value = 0,
    );
    await reminderService.rescheduleAll();
  } catch (e) {
    debugPrint('Reminder service init failed: $e');
  }
  try {
    await settingsService.init();
  } catch (e) {
    debugPrint('Settings init failed: $e');
  }
  try {
    await accessibilityService.init();
  } catch (e) {
    debugPrint('Accessibility init failed: $e');
  }
  try {
    await emotionVersesRepository.init();
  } catch (e) {
    debugPrint('EmotionVersesRepository init failed: $e');
  }
  try {
    await panicHistoryService.init();
  } catch (e) {
    debugPrint('Panic history init failed: $e');
  }

  // Bible dataset in safe background load.
  bibleDatasetInitInProgressNotifier.value = true;
  debugPrint('Loading Bible dataset...');
  await localBibleService.loadBible();
  bibleDatasetReadyNotifier.value = localBibleService.isLoaded;
  bibleDatasetInitInProgressNotifier.value = false;
  debugPrint(localBibleService.isLoaded
      ? 'Bible dataset loaded'
      : 'Bible dataset failed, using fallback verse');

  // Sync plan after settings are loaded.
  try {
    await readingPlanService.selectPlan(settingsService.selectedReadingPlan);
  } catch (e) {
    debugPrint('Reading plan sync failed: $e');
  }

  // Keep preferred translation loaded for reader screens.
  try {
    await bibleRepo.ensureLoaded(settingsService.preferredTranslation);
  } catch (e) {
    debugPrint('Preferred translation load failed: $e');
  }

  // Heavy model init in background (non-blocking).
  aiModelInitInProgressNotifier.value = true;
  debugPrint('Initializing Gemma in background...');
  unawaited(
    gemmaModelService.initializeModel().then((_) {
      aiModelReadyNotifier.value = gemmaModelService.isReady;
      debugPrint('Gemma ready: ${gemmaModelService.isReady}');
    }).catchError((Object e, StackTrace _) {
      aiModelReadyNotifier.value = false;
      debugPrint('Gemma initialization failed: $e');
    }).whenComplete(() {
      aiModelInitInProgressNotifier.value = false;
    }),
  );
  
  debugPrint('========== WARM START SERVICES COMPLETE ==========');
  debugPrint('Bible loaded: ${bibleDatasetReadyNotifier.value}');
  debugPrint('Gemma ready: ${gemmaModelService.isReady}');
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
