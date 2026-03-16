import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/panic_response.dart';
import '../inference/gemma_ffi.dart';
import '../prompt_builders/gemma_prompt_builder.dart';

class GemmaModelService {
  static const _assetModelPath = 'assets/models/gemma-2b-it.Q4_K_M.gguf';
  static const _targetFileName = 'gemma-2b-it.Q4_K_M.gguf';

  bool _initialized = false;
  String? _modelFilePath;

  bool get isInitialized => _initialized;

  Future<void> initialize() => initializeModel();

  Future<void> initializeModel() async {
    if (_initialized) return;

    debugPrint('Loading Gemma model...');
    final modelPath = await _copyModelIfNeeded();
    final threads = Platform.numberOfProcessors.clamp(2, 8);

    final ok = GemmaFfi.instance.initializeModel(
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
    debugPrint('Gemma model initialized');
  }

  Future<String> rewriteStructuredResponse({
    required String userMessage,
    required PanicResponse panicResponse,
  }) async {
    final prompt = GemmaPromptBuilder.buildPanicRewritePrompt(
      userMessage: userMessage,
      panicResponse: panicResponse,
    );
    final output = await generateResponse(prompt);
    if (output.trim().isEmpty) {
      throw Exception('Gemma returned empty output.');
    }
    return output.trim();
  }

  /// Runs inference with a raw [prompt] string.
  ///
  /// Returns an empty string if the model is unavailable or produces no text.
  Future<String> generateResponse(String prompt) async {
    debugPrint('Gemma generating response...');
    debugPrint('Prompt length: ${prompt.length}');

    if (!_initialized) {
      throw Exception('Gemma model not initialized.');
    }

    debugPrint('Generating tokens...');
    // Run inference off the UI isolate.
    final output = await Isolate.run(() => GemmaFfi.instance.generateResponse(prompt));
    final trimmed = output.trim();
    if (trimmed.startsWith('[Error]') ||
        trimmed.toLowerCase().contains('gemma stub') ||
        trimmed.toLowerCase().contains('llama.cpp submodule')) {
      throw Exception('Native inference returned non-model output: $trimmed');
    }
    if (trimmed.isEmpty) {
      throw Exception('Gemma inference returned empty output.');
    }
    debugPrint('Gemma inference completed');
    return trimmed;
  }

  /// Backward-compatible wrapper used by older services.
  Future<String> generateFromPrompt(String prompt) async {
    return generateResponse(prompt);
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
      throw Exception('Gemma model file missing. AI system cannot start.');
    }
  }
}
