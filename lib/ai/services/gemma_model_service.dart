import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/panic_response.dart';
import '../inference/gemma_ffi.dart';
import '../prompt_builders/gemma_prompt_builder.dart';

class GemmaModelService {
  static const _assetModelPath = 'assets/models/gemma-270m.gguf';
  static const _targetFileName = 'gemma-270m.gguf';

  bool _initialized = false;
  bool _isReady = false;
  String? _modelFilePath;

  bool get isInitialized => _initialized;
  bool get isReady => _isReady;

  Future<void> initialize() => initializeModel();

  Future<void> initializeModel() async {
    if (_initialized) return;

    try {
      debugPrint('Loading Gemma model...');
      final modelPath = await _copyModelIfNeeded();
      if (modelPath == null) {
        debugPrint('Gemma model unavailable. AI features will be disabled until model is packaged.');
        _isReady = false;
        return;
      }
      final threads = Platform.numberOfProcessors.clamp(2, 8);

      debugPrint('Initializing llama.cpp context...');
      final ok = await Isolate.run(
        () => GemmaFfi.instance.initializeModel(
          modelPath: modelPath,
          threads: threads,
          contextSize: 2048,
          batchSize: 512,
        ),
      );

      if (!ok) {
        debugPrint('Gemma model initialization failed. Ensure GGUF model exists and native llama.cpp is linked.');
        _isReady = false;
        return;
      }

      _modelFilePath = modelPath;
      _initialized = true;
      _isReady = true;
      debugPrint('Gemma model initialized successfully');
    } catch (e) {
      _isReady = false;
      _initialized = false;
      debugPrint('Gemma initialization error: $e');
    }
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
      throw Exception('AI is still initializing. Please try again in a moment.');
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

  Future<String?> _copyModelIfNeeded() async {
    final dir = await getApplicationDocumentsDirectory();
    final modelPath = '${dir.path}/$_targetFileName';
    final outFile = File(modelPath);

    if (outFile.existsSync() && await outFile.length() > 1024) {
      return outFile.path;
    }

    debugPrint('Copying model to device storage...');
    try {
      final bytes = await rootBundle.load(_assetModelPath);
      final modelBytes = bytes.buffer.asUint8List();
      await Isolate.run(
        () => _writeModelBytes(modelPath, modelBytes),
      );
    } catch (e) {
      debugPrint('Gemma model missing in Flutter assets at $_assetModelPath: $e');
      return null;
    }

    if (!outFile.existsSync()) {
      debugPrint('Gemma model missing at $modelPath');
      return null;
    }

    return outFile.path;
  }

  static void _writeModelBytes(String modelPath, Uint8List bytes) {
    File(modelPath).writeAsBytesSync(bytes, flush: true);
  }
}
