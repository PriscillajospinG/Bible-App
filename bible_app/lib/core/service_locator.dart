import 'package:flutter/foundation.dart';

import '../data/repositories/bible_repository.dart';
import '../data/repositories/panic_response_repository.dart';
import '../data/services/favorites_service.dart';
import '../data/services/panic_search_service.dart';
import '../features/journal/repositories/journal_repository.dart';
import '../features/journal/services/emotion_detection_service.dart';
import '../features/journal/services/prayer_generator_service.dart';
import '../features/journal/services/verse_suggestion_service.dart';
import '../features/bible/services/bible_search_service.dart';
import '../features/bible/services/bookmark_service.dart';
import '../features/bible/services/highlight_service.dart';
import '../features/home/services/reading_plan_service.dart';
import '../features/home/services/reading_progress_service.dart';
import '../features/home/services/reminder_notification_service.dart';
import '../features/home/services/streak_service.dart';
import '../features/settings/accessibility_service.dart';
import '../features/settings/bible_cache_service.dart';
import '../features/settings/data_export_service.dart';
import '../features/settings/settings_service.dart';
import '../features/panic/services/panic_history_service.dart';
import '../features/panic/services/semantic_panic_search_service.dart';

/// Global singleton service/repository instances used across the app.
///
/// All `late final` values are set inside [main] before [runApp] is called,
/// so they are safe to access from any widget or service.
final bibleRepo = BibleRepository();
final panicRepo = PanicResponseRepository();
late final PanicSearchService panicSearchService;
late final FavoritesService favoritesService;

// ── Journal ──────────────────────────────────────────────────────────────────
late final JournalRepository journalRepo;
late final EmotionDetectionService emotionDetectionService;
late final VerseSuggestionService verseSuggestionService;
late final PrayerGeneratorService prayerGeneratorService;

/// Incremented each time a journal entry is saved.
///
/// [TodayScreen] listens to this notifier so it refreshes automatically after
/// the user saves a new entry in the Journal tab.
final journalRefreshNotifier = ValueNotifier<int>(0);

// ── Bible Step 6 ─────────────────────────────────────────────────────────────
late final BibleSearchService bibleSearchService;
late final BookmarkService bookmarkService;
late final HighlightService highlightService;

// ── Home Step 7 ──────────────────────────────────────────────────────────────
late final ReadingProgressService readingProgressService;
late final ReadingPlanService readingPlanService;
late final StreakService streakService;
late final ReminderNotificationService reminderNotificationService;

// ── Settings Step 8 ──────────────────────────────────────────────────────────
late final SettingsService settingsService;
late final AccessibilityService accessibilityService;
late final DataExportService dataExportService;
late final BibleCacheService bibleCacheService;

/// Bump this notifier whenever theme/accessibility/settings should rebuild the app shell.
final appPreferencesNotifier = ValueNotifier<int>(0);

// ── Panic Step 5 ─────────────────────────────────────────────────────────────
late final SemanticPanicSearchService semanticPanicSearchService;
late final PanicHistoryService panicHistoryService;

/// Set to a tab index to programmatically switch the HomeScreen tab.
///
/// Example: setting this to `1` switches to the Bible tab.
/// [HomeScreen] listens to this notifier and resets it to `null` after use.
final tabSwitchRequest = ValueNotifier<int?>(null);
