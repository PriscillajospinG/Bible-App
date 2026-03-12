import '../models/bible_testament.dart';
import '../models/bible_chapter.dart';
import '../models/bible_verse.dart';
import '../services/bible_loader_service.dart';

/// In-memory repository for the KJV Bible dataset.
///
/// Call [init] once (e.g. in main.dart before runApp) to load and cache the
/// parsed Bible. All lookup methods are synchronous after that.
class BibleRepository {
  BibleRepository({BibleLoaderService? loaderService})
      : _loader = loaderService ?? BibleLoaderService();

  final BibleLoaderService _loader;
  Bible? _bible;

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// Loads the Bible asset and caches it. Safe to call multiple times;
  /// subsequent calls are no-ops.
  Future<void> init() async {
    _bible ??= await _loader.load();
  }

  Bible get _data {
    if (_bible == null) {
      throw StateError(
        'BibleRepository has not been initialised. '
        'Await BibleRepository.init() before accessing data.',
      );
    }
    return _bible!;
  }

  // ---------------------------------------------------------------------------
  // Accessors
  // ---------------------------------------------------------------------------

  /// The translation identifier, e.g. "KJV".
  String get translation => _data.translation;

  /// All testaments (Old Testament, New Testament).
  List<BibleTestament> get testaments => List.unmodifiable(_data.testaments);

  /// Returns a [BibleChapter] or null if not found.
  ///
  /// Example:
  /// ```dart
  /// final chapter = repo.getChapter('KJV', 'John', 3);
  /// ```
  /// The [translation] parameter is validated against the loaded translation
  /// and throws if there is a mismatch.
  BibleChapter? getChapter(
    String translation,
    String bookName,
    int chapterNumber,
  ) {
    _assertTranslation(translation);
    return _data.getChapter(bookName, chapterNumber);
  }

  /// Returns a [BibleVerse] or null if not found.
  ///
  /// Example:
  /// ```dart
  /// final verse = repo.getVerse('KJV', 'John', 3, 16);
  /// ```
  BibleVerse? getVerse(
    String translation,
    String bookName,
    int chapterNumber,
    int verseNumber,
  ) {
    _assertTranslation(translation);
    return _data.getVerse(bookName, chapterNumber, verseNumber);
  }

  /// Returns all verses in a chapter, or an empty list if not found.
  List<BibleVerse> getVerses(
    String translation,
    String bookName,
    int chapterNumber,
  ) {
    _assertTranslation(translation);
    return _data.getChapter(bookName, chapterNumber)?.verses ?? const [];
  }

  /// Returns every book name across all testaments.
  List<String> get allBookNames => _data.testaments
      .expand((t) => t.books)
      .map((b) => b.name)
      .toList(growable: false);

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  void _assertTranslation(String translation) {
    if (translation.toUpperCase() != _data.translation.toUpperCase()) {
      throw ArgumentError(
        'Requested translation "$translation" but the loaded dataset is '
        '"${_data.translation}". Load the matching asset to use a different '
        'translation.',
      );
    }
  }
}
