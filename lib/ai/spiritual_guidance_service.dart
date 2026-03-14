import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/models/bible_verse.dart';
import 'bible_api_service.dart';
import 'emotion_verses_repository.dart';
import 'emotion_detection_service.dart';
import 'gemma_model_service.dart';
import 'gemma_prompt_builder.dart';
import 'verse_cache_service.dart';

/// Result returned by [SpiritualGuidanceService.generateGuidance].
class GuidanceResult {
  final String emotion;
  final List<BibleVerse> verses;
  final String guidance;

  /// Whether the guidance text was produced by the local Gemma model.
  /// False means a template-based fallback was used.
  final bool usedAiModel;

  const GuidanceResult({
    required this.emotion,
    required this.verses,
    required this.guidance,
    this.usedAiModel = false,
  });
import '../data/models/bible_verse.dart';
///   user message
///   → EmotionDetectionService
///   → emotion → verse references (emotion_verses.json)
///   → VerseCacheService / BibleApiService
///   → GemmaPromptBuilder.buildGuidancePrompt
///   → GemmaModelService (or template fallback)
///   → GuidanceResult
class SpiritualGuidanceService {
  SpiritualGuidanceService({
    required EmotionDetectionService emotionDetection,
    required BibleApiService bibleApi,
    required VerseCacheService verseCache,
    required GemmaModelService modelService,
    required EmotionVersesRepository emotionVerses,
  })  : _emotionDetection = emotionDetection,
        _bibleApi = bibleApi,
        _verseCache = verseCache,
        _modelService = modelService,
        _emotionVerses = emotionVerses;

  final EmotionDetectionService _emotionDetection;
  final BibleApiService _bibleApi;
  final VerseCacheService _verseCache;
  final GemmaModelService _modelService;
  final EmotionVersesRepository _emotionVerses;

  /// Runs the full RAG pipeline for [userMessage].
  Future<GuidanceResult> generateGuidance(String userMessage) async {
    // 1. Detect primary emotion
    final emotions = _emotionDetection.detectEmotions(userMessage);
    final primaryEmotion = emotions.first;

    // 2. Get verse references mapped to the detected emotion
    final references = _emotionVerses.versesFor(primaryEmotion);

    // 3. Fetch top 2 verses (cache-first, API fallback)
    final verses = await _fetchVerses(references.take(2).toList());

    // 4. Build RAG prompt
    final prompt = GemmaPromptBuilder.buildGuidancePrompt(
      userMessage: userMessage,
      emotion: primaryEmotion,
      verses: verses,
    );

    // 5. Generate with Gemma; fall back to template if model unavailable
    String guidance;
    bool usedAi = false;
    try {
      final output = await _modelService.generateFromPrompt(prompt);
      if (output.isNotEmpty) {
        guidance = output;
        usedAi = true;
      } else {
        guidance = _templateGuidance(primaryEmotion, verses);
      }
    } catch (_) {
      guidance = _templateGuidance(primaryEmotion, verses);
    }

    return GuidanceResult(
      emotion: primaryEmotion,
      verses: verses,
      guidance: guidance,
      usedAiModel: usedAi,
    );
  }

  Future<List<BibleVerse>> _fetchVerses(List<String> references) async {
    final verses = <BibleVerse>[];
    for (final ref in references) {
      try {
        var verse = _verseCache.getCached(ref);
        if (verse == null) {
          verse = await _bibleApi.fetchPassage(ref);
          await _verseCache.cache(ref, verse);
        }
        verses.add(verse);
      } catch (_) {
        // Skip verses that fail; others may still succeed.
      }
    }
    return verses;
  }

  String _templateGuidance(String emotion, List<BibleVerse> verses) {
    final scriptureLines = verses.isEmpty
        ? ''
        : verses
            .map((v) => '"${v.text.trim()}"\n— ${v.reference}')
            .join('\n\n');

    return '''
Based on your $emotion, God's Word offers these words of comfort:

$scriptureLines

Remember that God sees you and cares deeply about what you are going through. Bring your heart to Him in prayer, trusting that He hears every word.
'''.trim();
  }
}

