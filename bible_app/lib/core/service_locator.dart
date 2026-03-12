import '../data/repositories/bible_repository.dart';
import '../data/repositories/panic_response_repository.dart';
import '../data/services/favorites_service.dart';
import '../data/services/panic_search_service.dart';

/// Global singleton service/repository instances used across the app.
///
/// All `late final` values are set inside [main] before [runApp] is called,
/// so they are safe to access from any widget or service.
final bibleRepo = BibleRepository();
final panicRepo = PanicResponseRepository();
late final PanicSearchService panicSearchService;
late final FavoritesService favoritesService;
