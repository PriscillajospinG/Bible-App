import 'gemma_engine.dart';

class GemmaFfi {
  GemmaFfi._();

  static final GemmaFfi instance = GemmaFfi._();

  bool initializeModel({
    required String modelPath,
    required int threads,
    required int contextSize,
    required int batchSize,
  }) {
    return GemmaEngine.instance.initModel(
      modelPath: modelPath,
      threads: threads,
      contextSize: contextSize,
      batchSize: batchSize,
    );
  }

  String generateResponse(String prompt) {
    return GemmaEngine.instance.generateText(prompt);
  }

  void release() {
    GemmaEngine.instance.dispose();
  }
}
