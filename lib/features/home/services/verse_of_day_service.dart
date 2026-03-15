import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../journal/models/verse_of_day.dart';
import '../../journal/services/verse_suggestion_service.dart';

/// Resolves and caches a single Verse of the Day per calendar date.
///
/// The chosen verse remains stable for the whole day and refreshes the next day.
class VerseOfDayService {
  VerseOfDayService({required VerseSuggestionService verseSuggestionService})
      : _verseSuggestionService = verseSuggestionService;

  static const _dateKey = 'daily_verse_date';
  static const _verseKey = 'daily_verse_payload';

  final VerseSuggestionService _verseSuggestionService;

  Future<VerseOfDay> getVerseForToday(List<String> emotions) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateOnly(DateTime.now());

    final storedDate = prefs.getString(_dateKey);
    final storedPayload = prefs.getString(_verseKey);
    if (storedDate == today && storedPayload != null && storedPayload.isNotEmpty) {
      try {
        final data = jsonDecode(storedPayload) as Map<String, dynamic>;
        return VerseOfDay.fromJson(data);
      } catch (_) {
        // Fall through to refresh verse when cache payload is invalid.
      }
    }

    final emotion = emotions.isEmpty ? 'peace' : emotions.first;
    final resolved = emotion.toLowerCase() == 'reflection' ? 'peace' : emotion;
    final verse = await _verseSuggestionService.getVerseForEmotion(resolved);

    await prefs.setString(_dateKey, today);
    await prefs.setString(_verseKey, jsonEncode(verse.toJson()));
    return verse;
  }

  String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
