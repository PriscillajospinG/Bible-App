import '../../../ai/services/bible_api_service.dart';
import '../../../ai/services/emotion_detection_service.dart';
import '../../../ai/services/gemma_model_service.dart';
import '../../../ai/prompt_builders/gemma_prompt_builder.dart';
import 'package:flutter/foundation.dart';
import '../../../data/models/bible_verse.dart';
import '../../../data/models/panic_entry.dart';
import '../../../data/datasources/panic_search_service.dart';

class PanicGuidanceResult {
  final String emotion;
  final PanicEntry entry;
  final String responseText;
  final bool usedFallback;
  /// Verse texts fetched from [BibleApiService] for the recommended references.
  final List<BibleVerse> fetchedVerses;

  const PanicGuidanceResult({
    required this.emotion,
    required this.entry,
    required this.responseText,
    required this.usedFallback,
    this.fetchedVerses = const [],
  });
}

/// End-to-end panic RAG pipeline service.
///
/// Flow:
///   user message -> emotion detection -> dataset retrieval -> verse fetch
///   (via [BibleApiService]) -> prompt builder -> Gemma model inference
///   -> fallback to static dataset response on failure.
class PanicGuidanceService {
  PanicGuidanceService({
    required EmotionDetectionService emotionDetection,
    required PanicSearchService searchService,
    required GemmaModelService modelService,
    BibleApiService? bibleApi,
  })  : _emotionDetection = emotionDetection,
        _searchService = searchService,
        _modelService = modelService,
        _bibleApi = bibleApi;

  final EmotionDetectionService _emotionDetection;
  final PanicSearchService _searchService;
  final GemmaModelService _modelService;
  final BibleApiService? _bibleApi;

  Future<PanicGuidanceResult> handleUserMessage(String message) async {
    final detectedEmotions = _emotionDetection.detectEmotions(message);
    final primaryEmotion = detectedEmotions.first;

    final entry = _searchService.findBestResponse(
      userMessage: message,
      detectedEmotions: detectedEmotions,
    );

    // Fetch actual verse text for up to 2 recommended verses from the API.
    final fetchedVerses = <BibleVerse>[];
    if (_bibleApi != null) {
      for (final ref in entry.response.recommendedVerses.take(2)) {
        try {
          fetchedVerses.add(await _bibleApi!.fetchVerse(ref));
        } catch (_) {
          // Skip verses that fail to fetch; fallback references still in prompt.
        }
      }
    }

    final prompt = GemmaPromptBuilder.buildPanicGuidancePrompt(
      userMessage: message,
      detectedEmotion: primaryEmotion,
      detectedEmotions: detectedEmotions,
      entry: entry,
      fetchedVerses: fetchedVerses,
    );
    debugPrint('Gemma generating response...');
    debugPrint('Prompt length: ${prompt.length}');

    try {
      final generated = await _modelService.generateResponse(prompt);
      if (generated.trim().isNotEmpty) {
        return PanicGuidanceResult(
          emotion: primaryEmotion,
          entry: entry,
          responseText: generated.trim(),
          usedFallback: false,
          fetchedVerses: fetchedVerses,
        );
      }
    } catch (_) {
      // Fall back to dataset response below.
      debugPrint('Gemma generation failed. Falling back to contextual template.');
    }

    return PanicGuidanceResult(
      emotion: primaryEmotion,
      entry: entry,
      responseText: _buildFallback(entry, fetchedVerses),
      usedFallback: true,
      fetchedVerses: fetchedVerses,
    );
  }

  String _buildFallback(PanicEntry entry, List<BibleVerse> fetchedVerses) {
    final c = entry.response;
    final emotionHint = entry.emotionTags.isEmpty
        ? 'overwhelmed'
        : entry.emotionTags.first;

    final String verseLine;
    if (fetchedVerses.isNotEmpty) {
      final lines = fetchedVerses
          .map((v) => '${v.reference} — ${v.text.trim()}')
          .join('\n');
      verseLine = '\n\nVerses:\n$lines';
    } else if (c.recommendedVerses.isEmpty) {
      verseLine = '';
    } else {
      verseLine = '\n\nRecommended verses: ${c.recommendedVerses.join(', ')}';
    }

    return 'It sounds like you\'re experiencing $emotionHint, and your feelings matter deeply before God. '
        '${c.biblicalExplanation} '
        'Remember this biblical picture: ${c.biblicalStoryExample}. '
        '${c.shortPrayer}$verseLine';
  }
}
