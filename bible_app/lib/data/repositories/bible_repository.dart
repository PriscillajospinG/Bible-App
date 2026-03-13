import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/bible_book.dart';
import '../models/bible_chapter.dart';
import '../models/bible_testament.dart';
import '../models/bible_verse.dart';

/// In-memory repository for all Bible translations.
///
/// Call [init] once at startup (loads KJV eagerly). Additional translations are
/// lazy-loaded via [ensureLoaded] — useful before switching translations in the
/// reader, since each JSON file is ~7 MB.
class BibleRepository {
  // ── Translation registry ──────────────────────────────────────────────────

  /// All translations supported by this app.
  /// Key = short code used by the app (cache key, UI label).
  /// Value = Flutter asset path.
  static const Map<String, String> availableTranslations = {
    'KJV': 'assets/bible/kjv.json',
    'NIV': 'assets/bible/niv.json',
    'NLT': 'assets/bible/nlt.json',
    'AMP': 'assets/bible/amp.json',
  };

  static const Map<String, String> translationFullNames = {
    'KJV': 'King James Version',
    'NIV': 'New International Version',
    'NLT': 'New Living Translation',
    'AMP': 'Amplified Bible',
  };

  final Map<String, Bible> _cache = {};

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Eagerly loads KJV (the default translation) at app startup.
  Future<void> init() => ensureLoaded('KJV');

  /// Loads and caches [translation] if it is not already in memory.
  ///
  /// Safe to call multiple times for the same key — subsequent calls are
  /// instant no-ops.
  Future<void> ensureLoaded(String translation) async {
    final key = translation.toUpperCase();
    if (_cache.containsKey(key)) return;

    final path = availableTranslations[key];
    if (path == null) {
      throw ArgumentError(
        'Translation "$translation" is not configured. '
        'Available: ${availableTranslations.keys.join(', ')}',
      );
    }

    final rawJson = await rootBundle.loadString(path);
    // Use the app's cache key — not the JSON `translation` field — because
    // some dataset files are incorrectly labelled (NLT/AMP say "KJV").
    _cache[key] = Bible.fromJson(jsonDecode(rawJson) as Map<String, dynamic>);
  }

  /// Whether [translation] has already been loaded into memory.
  bool isLoaded(String translation) =>
      _cache.containsKey(translation.toUpperCase());

  // ── Translation-level ─────────────────────────────────────────────────────

  /// Returns all supported translation codes (e.g. ['KJV', 'NIV', 'NLT', 'AMP']).
  List<String> getTranslations() => availableTranslations.keys.toList();

  /// Returns translations currently loaded in memory.
  List<String> getLoadedTranslations() => _cache.keys.toList(growable: false);

  /// Human-readable full name for a [translation] code.
  String getFullName(String translation) =>
      translationFullNames[translation.toUpperCase()] ?? translation;

  // ── Testament-level ───────────────────────────────────────────────────────

  /// All testaments for [translation]. Throws [StateError] if not loaded.
  List<BibleTestament> getTestaments(String translation) =>
      _require(translation).testaments;

  // ── Book-level ────────────────────────────────────────────────────────────

  /// All books belonging to [testamentName] in [translation].
  List<BibleBook> getBooks(String translation, String testamentName) {
    return _require(translation)
        .testaments
        .firstWhere(
          (t) => t.name.toLowerCase() == testamentName.toLowerCase(),
          orElse: () =>
              throw ArgumentError('Testament "$testamentName" not found.'),
        )
        .books;
  }

  // ── Chapter-level ─────────────────────────────────────────────────────────

  /// All [BibleChapter] objects for [bookName] in [translation].
  List<BibleChapter> getChapters(String translation, String bookName) =>
      List.unmodifiable(
        _require(translation).getBook(bookName)?.chapters ?? const [],
      );

  /// Ordered list of chapter numbers (1-based) for [bookName].
  List<int> getChapterNumbers(String translation, String bookName) =>
      getChapters(translation, bookName).map((c) => c.chapter).toList();

  // ── Verse-level ───────────────────────────────────────────────────────────

  /// All verses inside a given chapter, or an empty list if not found.
  List<BibleVerse> getVerses(
    String translation,
    String bookName,
    int chapterNumber,
  ) =>
      List.unmodifiable(
        _require(translation).getChapter(bookName, chapterNumber)?.verses ??
            const [],
      );

  BibleChapter? getChapter(
    String translation,
    String bookName,
    int chapterNumber,
  ) =>
      _require(translation).getChapter(bookName, chapterNumber);

  BibleVerse? getVerse(
    String translation,
    String bookName,
    int chapterNumber,
    int verseNumber,
  ) =>
      _require(translation).getVerse(bookName, chapterNumber, verseNumber);

  // ── Convenience ───────────────────────────────────────────────────────────

  /// All book names across all testaments (KJV order, always available after
  /// [init]).
  List<String> get allBookNames => _require('KJV')
      .testaments
      .expand((t) => t.books)
      .map((b) => b.name)
      .toList(growable: false);

  // ── Internal ──────────────────────────────────────────────────────────────

  Bible _require(String translation) {
    final key = translation.toUpperCase();
    final bible = _cache[key];
    if (bible == null) {
      throw StateError(
        'Translation "$translation" is not loaded. '
        'Await bibleRepo.ensureLoaded("$translation") first.',
      );
    }
    return bible;
  }
}
