import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

typedef _InitModelNative = Int32 Function(
  Pointer<Utf8>,
  Int32,
  Int32,
  Int32,
);
typedef _InitModelDart = int Function(Pointer<Utf8>, int, int, int);

typedef _GenerateNative = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _GenerateDart = Pointer<Utf8> Function(Pointer<Utf8>);

typedef _FreeStringNative = Void Function(Pointer<Utf8>);
typedef _FreeStringDart = void Function(Pointer<Utf8>);

typedef _ReleaseNative = Void Function();
typedef _ReleaseDart = void Function();

class GemmaEngine {
  GemmaEngine._(DynamicLibrary lib)
      : _initModel = lib.lookupFunction<_InitModelNative, _InitModelDart>(
          'llama_init_model',
        ),
        _generate = lib.lookupFunction<_GenerateNative, _GenerateDart>(
          'llama_generate_text',
        ),
        _freeString = lib.lookupFunction<_FreeStringNative, _FreeStringDart>(
          'llama_free_string',
        ),
        _release = lib.lookupFunction<_ReleaseNative, _ReleaseDart>(
          'llama_release_model',
        );
  final _InitModelDart _initModel;
  final _GenerateDart _generate;
  final _FreeStringDart _freeString;
  final _ReleaseDart _release;

  static GemmaEngine? _instance;

  static GemmaEngine get instance {
    _instance ??= GemmaEngine._(_openLibrary());
    return _instance!;
  }

  static DynamicLibrary _openLibrary() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libllama_engine.so');
    }
    if (Platform.isIOS || Platform.isMacOS) {
      return DynamicLibrary.process();
    }
    throw UnsupportedError('GemmaEngine is only supported on mobile platforms.');
  }

  bool initModel({
    required String modelPath,
    required int threads,
    required int contextSize,
    required int batchSize,
  }) {
    final pathPtr = modelPath.toNativeUtf8();
    try {
      final ok = _initModel(pathPtr, threads, contextSize, batchSize);
      return ok == 1;
    } finally {
      calloc.free(pathPtr);
    }
  }

  String generateText(String prompt) {
    final promptPtr = prompt.toNativeUtf8();
    try {
      final outPtr = _generate(promptPtr);
      if (outPtr == nullptr) {
        return '';
      }
      final out = outPtr.toDartString();
      _freeString(outPtr);
      return out;
    } finally {
      calloc.free(promptPtr);
    }
  }

  void dispose() => _release();
}
