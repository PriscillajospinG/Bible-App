import '../data/models/panic_response.dart';
import 'gemma_prompt_builder.dart';

/// Backward-compatible prompt builder entrypoint for AI pipelines.
class PromptBuilder {
  static String buildPanicRewritePrompt({
    required String userMessage,
    required PanicResponse panicResponse,
  }) {
    return GemmaPromptBuilder.buildPanicRewritePrompt(
      userMessage: userMessage,
      panicResponse: panicResponse,
    );
  }
}
