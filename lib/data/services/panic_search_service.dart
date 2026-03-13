import '../models/panic_response.dart';
import '../repositories/panic_response_repository.dart';

/// Offline similarity-based retrieval service.
///
/// Scores every [PanicResponse] entry against a free-text [userMessage] using
/// weighted word-overlap across four dataset fields, then multiplies by each
/// entry's [PanicResponse.priorityWeight].
///
/// Scoring table (per entry):
///   trigger_examples match  → +3 per example that shares ≥1 token
///   emotion_tags match      → +2 per tag that shares ≥1 token
///   situation_tags match    → +2 per tag that shares ≥1 token
///   search_text overlap     → +1 per shared word
///
/// Final score = raw score × priority_weight
class PanicSearchService {
  PanicSearchService({required PanicResponseRepository repository})
      : _repo = repository;

  final PanicResponseRepository _repo;

  // ---------------------------------------------------------------------------
  // Stopwords — filtered out before comparison so they don't inflate scores.
  // ---------------------------------------------------------------------------
  static const _stopwords = <String>{
    'i', 'a', 'an', 'the', 'is', 'am', 'are', 'was', 'were', 'be', 'been',
    'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would',
    'could', 'should', 'may', 'might', 'must', 'can', 'feel', 'feeling',
    'felt', 'just', 'very', 'so', 'too', 'really', 'get', 'got', 'like',
    'me', 'my', 'you', 'your', 'we', 'our', 'they', 'their', 'it', 'its',
    'this', 'that', 'these', 'those', 'and', 'or', 'but', 'not', 'no',
    'from', 'to', 'for', 'in', 'on', 'at', 'by', 'with', 'about', 'of',
    'up', 'out', 'if', 'as', 'into', 'through', 'before', 'after', 'each',
    'more', 'other', 'some', 'than', 'then', 'when', 'where', 'who', 'how',
    'all', 'any', 'both', 'because', 'due', 'seeking', 'biblical', 'guidance',
    'since', 'while', 'during', 'such',
  };

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns the [PanicResponse] that best matches [userMessage].
  ///
  /// Falls back to the highest [PanicResponse.priorityWeight] entry when no
  /// tokens overlap (e.g. a very short or unusual input).
  PanicResponse findBestResponse(String userMessage) {
    final entries = _repo.getAllPanicResponses();
    if (entries.isEmpty) throw StateError('Panic dataset is empty.');

    PanicResponse? best;
    double bestScore = -1;

    for (final entry in entries) {
      final score = calculateScore(userMessage, entry);
      if (score > bestScore) {
        bestScore = score;
        best = entry;
      }
    }

    // Fallback: no meaningful word overlap — return highest-priority entry.
    if (bestScore == 0) {
      return entries.reduce(
        (a, b) => a.priorityWeight >= b.priorityWeight ? a : b,
      );
    }

    return best!;
  }

  // ---------------------------------------------------------------------------
  // Scoring — public so it can be unit-tested independently
  // ---------------------------------------------------------------------------

  /// Computes a weighted relevance score between [userMessage] and [entry].
  double calculateScore(String userMessage, PanicResponse entry) {
    final userTokens = _tokenize(userMessage);
    if (userTokens.isEmpty) return 0;

    double score = 0;

    // trigger_examples: +3 per example sharing ≥1 token with the user message.
    for (final trigger in entry.triggerExamples) {
      if (userTokens.intersection(_tokenize(trigger)).isNotEmpty) {
        score += 3;
      }
    }

    // emotion_tags: +2 per tag sharing ≥1 token.
    for (final tag in entry.emotionTags) {
      if (userTokens.intersection(_tokenize(tag)).isNotEmpty) {
        score += 2;
      }
    }

    // situation_tags: +2 per tag sharing ≥1 token.
    for (final tag in entry.situationTags) {
      if (userTokens.intersection(_tokenize(tag)).isNotEmpty) {
        score += 2;
      }
    }

    // search_text: +1 per shared word.
    final searchOverlap =
        userTokens.intersection(_tokenize(entry.searchText));
    score += searchOverlap.length;

    // Weight by dataset-provided priority.
    return score * entry.priorityWeight;
  }

  // ---------------------------------------------------------------------------
  // Text preprocessing
  // ---------------------------------------------------------------------------

  /// Lowercases [text], strips punctuation, splits on whitespace and removes
  /// short words and stopwords.
  Set<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r"[^\w\s]"), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2 && !_stopwords.contains(word))
        .toSet();
  }
}
