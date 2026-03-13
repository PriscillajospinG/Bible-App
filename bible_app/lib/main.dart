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
  debugPrint('Journal entries — ${journalRepo.count} entries');
  debugPrint('Panic history — ${panicHistoryService.count} sessions');

  runApp(const BibleApp());
}

class BibleApp extends StatelessWidget {
  const BibleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bible App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B4226)),
        useMaterial3: true,
        fontFamily: 'Georgia',
      ),
      home: const HomeScreen(),
    );
  }
}
