import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/bible_verse.dart';

/// Local cache for API-fetched Bible passages.
///
/// Persists fetched verses to [SharedPreferences] so the app can display
/// previously loaded scripture without an internet connection.
class VerseCacheService {
  static const _prefsKey = 'verse_cache_v1';

  final Map<String, BibleVerse> _cache = {};
  SharedPreferences? _prefs;

  /// Load persisted entries from device storage.
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs!.getString(_prefsKey);
      if (raw == null) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in map.entries) {
        try {
          _cache[entry.key] =
              BibleVerse.fromJson(entry.value as Map<String, dynamic>);
        } catch (_) {}
      }
      debugPrint('VerseCacheService: loaded ${_cache.length} cached passages');
    } catch (e) {
      debugPrint('VerseCacheService: init failed: $e');
    }
  }

  /// Returns the cached [BibleVerse] for [reference], or null if not cached.
  BibleVerse? getCached(String reference) => _cache[reference];

  /// Stores [verse] in both the in-memory cache and device storage.
  Future<void> cache(String reference, BibleVerse verse) async {
    _cache[reference] = verse;
    await _persist();
  }

  int get cachedCount => _cache.length;

  Future<void> _persist() async {
    try {
      final encoded =
          jsonEncode(_cache.map((k, v) => MapEntry(k, v.toJson())));
      await _prefs?.setString(_prefsKey, encoded);
    } catch (e) {
      debugPrint('VerseCacheService: persist failed: $e');
    }
  }
}
