import '../data/models/bible_verse.dart';
import '../data/models/panic_response.dart';

class GemmaPromptBuilder {
  /// Builds a RAG-style spiritual guidance prompt using API-fetched verses.
  ///
  /// Used by [SpiritualGuidanceService] for the Panic / Guidance screen.
  static String buildGuidancePrompt({
    required String userMessage,
    required String emotion,
    required List<BibleVerse> verses,
  }) {
    final verseBlock = verses.isEmpty
        ? 'No scripture passages available.'
        : verses
            .map((v) => '${v.reference}\n"${v.text.trim()}"')
            .join('\n\n');

    return '''
You are a compassionate Christian spiritual guide.

User problem:
"$userMessage"

Detected emotional state: $emotion

Relevant Bible verses:
$verseBlock

Based on these scriptures, provide:
1. A warm understanding of their situation (2–3 sentences).
2. Biblical encouragement drawing from the verses above (3–4 sentences).
3. A short prayer (2–3 sentences).

Be concise, warm, and pastoral. Do not invent scripture references not listed above.
'''.trim();
  }

  /// Builds a journal reflection prompt that generates numbered prayer points.
  ///
  /// Used by [JournalReflectionService].
  static String buildJournalPrompt({
    required String journalText,
    required String emotion,
    required List<BibleVerse> verses,
  }) {
    final verseBlock = verses.isEmpty
        ? 'No scripture passages available.'
        : verses
            .map((v) => '${v.reference}\n"${v.text.trim()}"')
            .join('\n\n');

    return '''
You are a Christian prayer guide helping someone reflect on their journal entry.

Journal entry:
"$journalText"

Detected emotional state: $emotion

Relevant Bible verses:
$verseBlock

Generate exactly 3 specific prayer points based on this entry and these scriptures.

Format your response as:
1. ...
2. ...
3. ...

Keep each point concise (1–2 sentences). Ground them in the scriptures above.
'''.trim();
  }

  /// Legacy: rewrite structured JSONL guidance in a warm natural tone.
  ///
  /// Kept for backward-compatible fallback in [GemmaModelService.generateResponse].
  static String buildPanicRewritePrompt({
    required String userMessage,
    required PanicResponse panicResponse,
  }) {
    final c = panicResponse.response;
    final guidance = '''
Understanding the Situation:
${c.understandingUserQuery}

Biblical Explanation:
${c.biblicalExplanation}

Biblical Story Example:
${c.biblicalStoryExample}

Recommended Verses:
${c.recommendedVerses.join(', ')}

Short Prayer:
${c.shortPrayer}
''';

    return '''
You are a compassionate Christian spiritual guide.

Rewrite the following structured guidance in a warm and natural way.

User message:
$userMessage

Guidance:
$guidance

Respond in a supportive and pastoral tone.
Keep it concise (120-220 words), include 1 short prayer sentence, and do not invent any new facts.
''';
  }
}
