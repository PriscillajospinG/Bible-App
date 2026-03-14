import '../data/models/bible_verse.dart';
import 'bible_api_service.dart';
import 'emotion_verses_repository.dart';
import 'emotion_detection_service.dart';
import 'gemma_model_service.dart';
import 'gemma_prompt_builder.dart';
import 'verse_cache_service.dart';

/// Result returned by [JournalReflectionService.analyzeEntry].
class JournalReflectionResult {
  final List<String> emotions;
  final List<BibleVerse> verses;
  final List<String> prayerPoints;
  final String? aiReflection;

  const JournalReflectionResult({
    required this.emotions,
    required this.verses,
    required this.prayerPoints,
    this.aiReflection,
  });
}

///   journal text
///   → EmotionDetectionService
///   → emotion → verse references (from emotion_verses.json)
///   → BibleApiService / VerseCacheService
///   → GemmaPromptBuilder.buildJournalPrompt
///   → GemmaModelService (or rule-based fallback)
///   → JournalReflectionResult
class JournalReflectionService {
  JournalReflectionService({
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

  /// Analyses [journalText] and returns prayer points + relevant scripture.
  Future<JournalReflectionResult> analyzeEntry(String journalText) async {
    // 1. Detect emotions
    final emotions = _emotionDetection.detectEmotions(journalText);
    final primaryEmotion = emotions.first;

    // 2. Get verse references for the dominant emotion
    final references = _emotionVerses.versesFor(primaryEmotion);

    // 3. Fetch top 2 verses (cache-first, API fallback)
    final verses = await _fetchVerses(references.take(2).toList());

    // 4. Generate prayer points
    List<String> prayerPoints;
    String? aiReflection;

    if (_modelService.isInitialized && verses.isNotEmpty) {
      try {
        final prompt = GemmaPromptBuilder.buildJournalPrompt(
          journalText: journalText,
          emotion: primaryEmotion,
          verses: verses,
        );
        aiReflection = await _modelService.generateFromPrompt(prompt);
        prayerPoints = _parsePrayerPoints(aiReflection);
      } catch (_) {
        prayerPoints = _buildRuleBasedPoints(primaryEmotion, verses);
      }
    } else {
      prayerPoints = _buildRuleBasedPoints(primaryEmotion, verses);
    }

    return JournalReflectionResult(
      emotions: emotions,
      verses: verses,
      prayerPoints: prayerPoints,
      aiReflection: aiReflection,
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
        // Skip verses that fail to load; others may still succeed.
      }
    }
    return verses;
  }

  List<String> _parsePrayerPoints(String aiText) {
    final points = <String>[];
    for (final line in aiText.split('\n')) {
      final match = RegExp(r'^\d+\.\s+(.+)').firstMatch(line.trim());
      if (match != null) {
        points.add(match.group(1)!);
      }
    }
    return points.isEmpty ? [aiText.trim()] : points;
  }

  List<String> _buildRuleBasedPoints(
      String emotion, List<BibleVerse> verses) {
    final ref0 = verses.isNotEmpty ? ' (${verses.first.reference})' : '';
    final ref1 =
        verses.length > 1 ? ' (${verses[1].reference})' : '';
    return [
      'Ask God for comfort and peace in your season of $emotion$ref0.',
      verses.length > 1
          ? 'Pray for strength to trust God\'s word$ref1.'
          : 'Pray for strength to hold onto God\'s promises.',
      'Thank God for His presence and ask for guidance in your next steps.',
    ];
  }
}
