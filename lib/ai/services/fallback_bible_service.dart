import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../data/models/bible_verse.dart';

/// Serves Bible verses from the bundled KJV flat-lookup JSON.
///
/// Used as an offline fallback when [BibleApiService] cannot reach the network.
/// The asset at [_assetPath] is a map of `"Book Ch:V" → "verse text"`.
class FallbackBibleService {
  static const _assetPath = 'assets/bible/kjv.json';

  Map<String, String> _verses = {};
  bool _loaded = false;

  Future<void> init() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _verses = decoded.map((k, v) => MapEntry(k, v as String));
      _loaded = true;
      debugPrint('FallbackBibleService: loaded ${_verses.length} KJV verses');
    } catch (e) {
      debugPrint('FallbackBibleService: init failed: $e');
    }
  }

  /// Returns a [BibleVerse] for [reference] if it exists in the local dataset.
  ///
  /// Handles single verses ("Philippians 4:6") and simple ranges
  /// ("Philippians 4:6-7") by collecting all matching verse entries.
  BibleVerse? lookup(String reference) {
    // Direct match first.
    final direct = _verses[reference];
    if (direct != null) {
      return BibleVerse.fromApiPassage(reference: reference, text: direct);
    }

    // Range match: "Book Ch:start-end"
    final rangeMatch = RegExp(r'^(.+)\s(\d+):(\d+)-(\d+)$').firstMatch(reference.trim());
    if (rangeMatch != null) {
      final book = rangeMatch.group(1)!;
      final chapter = rangeMatch.group(2)!;
      final start = int.parse(rangeMatch.group(3)!);
      final end = int.parse(rangeMatch.group(4)!);

      final parts = <String>[];
      for (var v = start; v <= end; v++) {
        final key = '$book $chapter:$v';
        final text = _verses[key];
        if (text != null) parts.add(text);
      }
      if (parts.isNotEmpty) {
        return BibleVerse.fromApiPassage(
          reference: reference,
          text: parts.join(' '),
        );
      }
    }

    return null;
  }

  bool get isLoaded => _loaded;
}
