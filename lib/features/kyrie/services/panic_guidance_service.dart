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
  /// Verse texts fetched from [BibleApiService] for the recommended references.
  final List<BibleVerse> fetchedVerses;

  const PanicGuidanceResult({
    required this.emotion,
    required this.entry,
    required this.responseText,
    this.fetchedVerses = const [],
  });
}

/// End-to-end panic RAG pipeline service.
///
/// Flow:
///   user message -> emotion detection -> dataset retrieval -> verse fetch
///   (via [BibleApiService]) -> prompt builder -> Gemma model inference
///   -> generated response.
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

    final generated = await _modelService.generateResponse(prompt);
    if (generated.trim().isEmpty) {
      throw Exception('Gemma returned empty panic guidance output.');
    }

    debugPrint('PanicGuidanceService: using Gemma-generated response.');
    return PanicGuidanceResult(
      emotion: primaryEmotion,
      entry: entry,
      responseText: generated.trim(),
      fetchedVerses: fetchedVerses,
    );
  }
}
