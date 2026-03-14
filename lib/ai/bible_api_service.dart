import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../data/models/bible_verse.dart';
import 'fallback_bible_service.dart';
import 'verse_cache_service.dart';

/// Fetches Bible verse passages from the api.bible REST API.
///
/// The API key is loaded at runtime from the .env asset (BIBLE_API_KEY).
/// On any network failure the optional [FallbackBibleService] is queried first;
/// only when that also fails is an exception propagated.
///
/// Built-in caching: if [cache] is provided, verse results are persisted via
/// [VerseCacheService] (SharedPreferences) so repeat lookups skip the network.
class BibleApiService {
  /// [fallback] is queried when the REST API fails or is unreachable.
  /// [cache] is used to persist and retrieve previously fetched verses.
  BibleApiService({FallbackBibleService? fallback, VerseCacheService? cache})
      : _fallback = fallback,
        _cache = cache;

  final FallbackBibleService? _fallback;
  final VerseCacheService? _cache;

  /// World English Bible (WEB) — freely available on api.bible.
  static const _bibleId = '9879dbb7cfe39e4d-01';
  static const _baseUrl = 'https://api.scripture.api.bible/v1';
  static const _timeout = Duration(seconds: 10);

  /// API key resolved from the .env asset at runtime.
  String get _apiKey {
    try {
      return dotenv.maybeGet('BIBLE_API_KEY') ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Primary method: fetches [reference] using cache → API → fallback chain.
  ///
  /// Results are stored in [VerseCacheService] so subsequent calls for the
  /// same reference return instantly without a network round-trip.
  Future<BibleVerse> fetchVerse(String reference) async {
    final cached = _cache?.getCached(reference);
    if (cached != null) return cached;

    final verse = await fetchPassage(reference);
    await _cache?.cache(reference, verse);
    return verse;
  }

  /// Fetches a passage for [reference] such as "Philippians 4:6-7".
  ///
  /// Network failures are caught and routed through [FallbackBibleService].
  /// Prefer [fetchVerse] for individual verse lookups; it adds caching.
  Future<BibleVerse> fetchPassage(String reference) async {
    final passageId = _referenceToPassageId(reference);
    if (passageId == null) {
      // Try fallback for unparseable references before giving up.
      return _fallbackOrThrow(reference, 'Cannot parse Bible reference: "$reference"');
    }

    final uri = Uri.parse(
      '$_baseUrl/bibles/$_bibleId/passages/$passageId'
      '?content-type=text'
      '&include-notes=false'
      '&include-titles=false'
      '&include-chapter-numbers=false'
      '&include-verse-numbers=false'
      '&include-verse-spans=false',
    );

    final response = await http
        .get(uri, headers: {'api-key': _apiKey})
        .timeout(_timeout);

    if (response.statusCode != 200) {
      debugPrint('BibleApiService: HTTP ${response.statusCode} for "$reference"');
      return _fallbackOrThrow(
        reference,
        'Bible API ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final passage = data['data'] as Map<String, dynamic>;
    final content = (passage['content'] as String? ?? '').trim();
    final resolvedRef = passage['reference'] as String? ?? reference;

    debugPrint('BibleApiService: fetched "$resolvedRef"');
    return BibleVerse.fromApiPassage(reference: resolvedRef, text: content);
  }

  /// Queries [FallbackBibleService] if available; otherwise throws [reason].
  BibleVerse _fallbackOrThrow(String reference, String reason) {
    if (_fallback != null) {
      final local = _fallback!.lookup(reference);
      if (local != null) {
        debugPrint('BibleApiService: offline fallback served "$reference"');
        return local;
      }
    }
    throw Exception(reason);
  }

  /// Converts a human-readable reference to an api.bible passage ID.
  ///
  /// Examples:
  ///   "Philippians 4:6-7"  → "PHP.4.6-PHP.4.7"
  ///   "Isaiah 41:10"       → "ISA.41.10"
  ///   "1 Corinthians 10:13"→ "1CO.10.13"
  static String? _referenceToPassageId(String reference) {
    final colonIdx = reference.lastIndexOf(':');
    if (colonIdx == -1) return null;

    final bookAndChapter = reference.substring(0, colonIdx).trim();
    final verseRange = reference.substring(colonIdx + 1).trim();

    final parts = bookAndChapter.split(' ');
    if (parts.length < 2) return null;

    final chapter = parts.last;
    final bookName = parts.sublist(0, parts.length - 1).join(' ');
    final osisId = _bookNameToOsis(bookName);
    if (osisId == null) return null;

    if (verseRange.contains('-')) {
      final vParts = verseRange.split('-');
      final start = vParts[0].trim();
      final end = vParts[1].trim();
      return '$osisId.$chapter.$start-$osisId.$chapter.$end';
    }
    return '$osisId.$chapter.$verseRange';
  }

  /// Maps canonical English book names to OSIS abbreviations used by api.bible.
  static String? _bookNameToOsis(String name) {
    const map = <String, String>{
      // Old Testament
      'Genesis': 'GEN', 'Exodus': 'EXO', 'Leviticus': 'LEV',
      'Numbers': 'NUM', 'Deuteronomy': 'DEU', 'Joshua': 'JOS',
      'Judges': 'JDG', 'Ruth': 'RUT', '1 Samuel': '1SA', '2 Samuel': '2SA',
      '1 Kings': '1KI', '2 Kings': '2KI', '1 Chronicles': '1CH',
      '2 Chronicles': '2CH', 'Ezra': 'EZR', 'Nehemiah': 'NEH',
      'Esther': 'EST', 'Job': 'JOB', 'Psalm': 'PSA', 'Psalms': 'PSA',
      'Proverbs': 'PRO', 'Ecclesiastes': 'ECC', 'Song of Solomon': 'SNG',
      'Isaiah': 'ISA', 'Jeremiah': 'JER', 'Lamentations': 'LAM',
      'Ezekiel': 'EZK', 'Daniel': 'DAN', 'Hosea': 'HOS', 'Joel': 'JOL',
      'Amos': 'AMO', 'Obadiah': 'OBA', 'Jonah': 'JON', 'Micah': 'MIC',
      'Nahum': 'NAM', 'Habakkuk': 'HAB', 'Zephaniah': 'ZEP',
      'Haggai': 'HAG', 'Zechariah': 'ZEC', 'Malachi': 'MAL',
      // New Testament
      'Matthew': 'MAT', 'Mark': 'MRK', 'Luke': 'LUK', 'John': 'JHN',
      'Acts': 'ACT', 'Romans': 'ROM', '1 Corinthians': '1CO',
      '2 Corinthians': '2CO', 'Galatians': 'GAL', 'Ephesians': 'EPH',
      'Philippians': 'PHP', 'Colossians': 'COL',
      '1 Thessalonians': '1TH', '2 Thessalonians': '2TH',
      '1 Timothy': '1TI', '2 Timothy': '2TI', 'Titus': 'TIT',
      'Philemon': 'PHM', 'Hebrews': 'HEB', 'James': 'JAS',
      '1 Peter': '1PE', '2 Peter': '2PE',
      '1 John': '1JN', '2 John': '2JN', '3 John': '3JN',
      'Jude': 'JUD', 'Revelation': 'REV',
    };
    return map[name];
  }
}
