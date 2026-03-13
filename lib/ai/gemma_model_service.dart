import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../data/models/panic_response.dart';
import 'gemma_engine.dart';
import 'gemma_prompt_builder.dart';

class GemmaModelService {
  static const _assetModelPath = 'assets/models/gemma-270m.gguf';
  static const _targetFileName = 'gemma-270m.gguf';

  bool _initialized = false;
  String? _modelFilePath;

  bool get isInitialized => _initialized;

  Future<void> initializeModel() async {
    if (_initialized) return;

    final modelPath = await _copyModelIfNeeded();
    final threads = Platform.numberOfProcessors.clamp(2, 8);

    final ok = GemmaEngine.instance.initModel(
      modelPath: modelPath,
      threads: threads,
      contextSize: 2048,
      batchSize: 512,
    );

    if (!ok) {
      throw StateError(
        'Gemma model initialization failed. Ensure GGUF model exists and native llama.cpp is linked.',
      );
    }

    _modelFilePath = modelPath;
    _initialized = true;
  }

  Future<String> generateResponse({
    required String userMessage,
    required PanicResponse panicResponse,
  }) async {
    if (!_initialized) {
      await initializeModel();
    }

    final prompt = GemmaPromptBuilder.buildPanicRewritePrompt(
      userMessage: userMessage,
      panicResponse: panicResponse,
    );

    // Run inference off the UI isolate.
    final output = await Isolate.run(() => GemmaEngine.instance.generateText(prompt));
    if (output.trim().isEmpty) {
      return _fallbackFromStructured(panicResponse);
    }
    return output.trim();
  }

  String get modelPathOrEmpty => _modelFilePath ?? '';

  Future<String> _copyModelIfNeeded() async {
    final dir = await getApplicationSupportDirectory();
    final modelDir = Directory('${dir.path}/models');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }

    final outFile = File('${modelDir.path}/$_targetFileName');
    if (await outFile.exists() && await outFile.length() > 1024) {
      return outFile.path;
    }

    try {
      final bytes = await rootBundle.load(_assetModelPath);
      await outFile.writeAsBytes(
        bytes.buffer.asUint8List(),
        flush: true,
      );
      return outFile.path;
    } catch (e) {
      throw StateError(
        'Model asset missing at $_assetModelPath. Add gemma-270m.gguf under assets/models/. Original error: $e',
      );
    }
  }

  String _fallbackFromStructured(PanicResponse response) {
    final c = response.response;
    return '${c.understandingUserQuery}\n\n${c.biblicalExplanation}\n\n${c.shortPrayer}';
  }
}
