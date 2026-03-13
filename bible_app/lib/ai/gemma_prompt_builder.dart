import '../data/models/panic_response.dart';

class GemmaPromptBuilder {
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
