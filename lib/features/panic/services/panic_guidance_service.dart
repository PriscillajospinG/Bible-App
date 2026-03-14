import '../../../ai/emotion_detection_service.dart';
import '../../../ai/gemma_model_service.dart';
import '../../../ai/gemma_prompt_builder.dart';
import '../../../data/models/panic_entry.dart';
import '../../../data/services/panic_search_service.dart';

class PanicGuidanceResult {
  final String emotion;
  final PanicEntry entry;
  final String responseText;
  final bool usedFallback;

  const PanicGuidanceResult({
    required this.emotion,
    required this.entry,
    required this.responseText,
    required this.usedFallback,
  });
}

/// End-to-end panic RAG pipeline service.
///
/// Flow:
///   user message -> emotion detection -> dataset retrieval -> prompt builder
///   -> Gemma model inference -> fallback to static dataset response on failure.
class PanicGuidanceService {
  PanicGuidanceService({
    required EmotionDetectionService emotionDetection,
    required PanicSearchService searchService,
    required GemmaModelService modelService,
  })  : _emotionDetection = emotionDetection,
        _searchService = searchService,
        _modelService = modelService;

  final EmotionDetectionService _emotionDetection;
  final PanicSearchService _searchService;
  final GemmaModelService _modelService;

  Future<PanicGuidanceResult> handleUserMessage(String message) async {
    final detectedEmotions = _emotionDetection.detectEmotions(message);
    final primaryEmotion = detectedEmotions.first;

    final entry = _searchService.findBestResponse(
      userMessage: message,
      detectedEmotions: detectedEmotions,
    );

    final prompt = GemmaPromptBuilder.buildPanicGuidancePrompt(
      userMessage: message,
      detectedEmotion: primaryEmotion,
      entry: entry,
    );

    try {
      final generated = await _modelService.generateFromPrompt(prompt);
      if (generated.trim().isNotEmpty) {
        return PanicGuidanceResult(
          emotion: primaryEmotion,
          entry: entry,
          responseText: generated.trim(),
          usedFallback: false,
        );
      }
    } catch (_) {
      // Fall back to dataset response below.
    }

    return PanicGuidanceResult(
      emotion: primaryEmotion,
      entry: entry,
      responseText: _buildFallback(entry),
      usedFallback: true,
    );
  }

  String _buildFallback(PanicEntry entry) {
    final c = entry.response;
    final verseLine = c.recommendedVerses.isEmpty
        ? ''
        : '\n\nRecommended verses: ${c.recommendedVerses.join(', ')}';

    return '${c.understandingUserQuery}\n\n${c.biblicalExplanation}\n\n${c.shortPrayer}$verseLine'
        .trim();
  }
}
