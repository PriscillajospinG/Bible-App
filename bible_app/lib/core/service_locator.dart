import 'package:flutter/foundation.dart';

import '../data/repositories/bible_repository.dart';
import '../data/repositories/panic_response_repository.dart';
import '../data/services/favorites_service.dart';
import '../data/services/panic_search_service.dart';
import '../features/journal/repositories/journal_repository.dart';
import '../features/journal/services/emotion_detection_service.dart';
import '../features/journal/services/journal_storage_service.dart';
import '../features/journal/services/prayer_generator_service.dart';
import '../features/journal/services/verse_suggestion_service.dart';

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
