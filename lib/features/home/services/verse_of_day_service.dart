import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../ai/services/bible_api_service.dart';
import '../../journal/models/verse_of_day.dart';

/// Resolves and caches a single Verse of the Day per calendar date.
///
/// The chosen verse remains stable for the whole day and refreshes the next day.
class VerseOfDayService {
  VerseOfDayService({required BibleApiService bibleApi}) : _bibleApi = bibleApi;

  static const _dateKey = 'last_verse_date';
  static const _referenceKey = 'last_verse_reference';
  static const _textKey = 'last_verse_text';

  static const List<String> _versePool = [
    'Isaiah 41:10',
    'John 3:16',
    'Matthew 11:28',
    'Proverbs 3:5',
    'Romans 8:28',
    'Joshua 1:9',
    'Philippians 4:6',
    '2 Timothy 1:7',
    'Psalm 23:1',
    'Lamentations 3:22',
  ];

  final BibleApiService _bibleApi;

  Future<VerseOfDay> getVerseOfTheDay() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateOnly(DateTime.now());

    final storedDate = prefs.getString(_dateKey);
    final storedReference = prefs.getString(_referenceKey);
    final storedText = prefs.getString(_textKey);
    if (storedDate == today &&
        storedReference != null &&
        storedReference.isNotEmpty &&
        storedText != null &&
        storedText.isNotEmpty) {
      return VerseOfDay(
        reference: storedReference,
        text: storedText,
        emotion: 'daily',
      );
    }

    final yesterdayReference = prefs.getString(_referenceKey);
    final reference = _pickReference(excluding: yesterdayReference);
    final verse = await _bibleApi.fetchVerse(reference);

    await prefs.setString(_dateKey, today);
    await prefs.setString(_referenceKey, verse.reference);
    await prefs.setString(_textKey, verse.text);

    return VerseOfDay(
      reference: verse.reference,
      text: verse.text,
      emotion: 'daily',
    );
  }

  String _pickReference({String? excluding}) {
    if (_versePool.length == 1) return _versePool.first;
    final random = Random();
    var candidate = _versePool[random.nextInt(_versePool.length)];
    if (excluding == null || excluding.isEmpty) return candidate;
    while (candidate == excluding) {
      candidate = _versePool[random.nextInt(_versePool.length)];
    }
    return candidate;
  }

  String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
