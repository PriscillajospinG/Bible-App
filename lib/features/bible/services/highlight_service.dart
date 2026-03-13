import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/bible_verse.dart';

/// Stores verse highlights locally with one of the supported colors.
class HighlightService {
  static const _prefsKey = 'bible_highlights';

  static const Map<String, Color> supportedColors = {
    'yellow': Color(0xFFFFF59D),
    'green': Color(0xFFC8E6C9),
    'blue': Color(0xFFBBDEFB),
    'pink': Color(0xFFF8BBD0),
  };

  final Map<String, String> _cache = {};

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? const [];
    for (final item in raw) {
      try {
        final data = jsonDecode(item) as Map<String, dynamic>;
        _cache[data['id'] as String] = data['color'] as String;
      } catch (_) {
        // Skip malformed rows.
      }
    }
  }

  Future<void> highlightVerse(BibleVerse verse, Color color) async {
    final id = _buildId(verse);
    final colorName = _nameFromColor(color);
    if (colorName == null) {
      throw ArgumentError('Unsupported highlight color.');
    }
    _cache[id] = colorName;
    await _persist();
  }

  Map<String, String> getHighlights() => Map.unmodifiable(_cache);

  Color? getHighlightColor(BibleVerse verse) {
    final name = _cache[_buildId(verse)];
    if (name == null) return null;
    return supportedColors[name];
  }

  Future<void> removeHighlight(BibleVerse verse) async {
    _cache.remove(_buildId(verse));
    await _persist();
  }

  String _buildId(BibleVerse verse) {
    if (verse.translation == null || verse.book == null || verse.chapter == null) {
      throw ArgumentError(
        'BibleVerse must include translation, book, and chapter for highlighting.',
      );
    }
    return '${verse.translation}_${verse.book}_${verse.chapter}_${verse.verse}';
  }

  String? _nameFromColor(Color color) {
    for (final e in supportedColors.entries) {
      if (e.value.toARGB32() == color.toARGB32()) return e.key;
    }
    return null;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final rows = _cache.entries
        .map((e) => jsonEncode({'id': e.key, 'color': e.value}))
        .toList(growable: false);
    await prefs.setStringList(_prefsKey, rows);
  }
}
