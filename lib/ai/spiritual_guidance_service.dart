import '../data/models/panic_response.dart';
import 'gemma_model_service.dart';

/// High-level AI guidance service that wraps local model generation.
class SpiritualGuidanceService {
  SpiritualGuidanceService({required GemmaModelService modelService})
      : _modelService = modelService;

  final GemmaModelService _modelService;

  Future<String> generateGuidance({
    required String userMessage,
    required PanicResponse panicResponse,
  }) {
    return _modelService.generateResponse(
      userMessage: userMessage,
      panicResponse: panicResponse,
    );
  }
}
