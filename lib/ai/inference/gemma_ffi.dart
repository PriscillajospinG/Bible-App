import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

typedef _InitModelNative = Int32 Function(Pointer<Utf8>, Int32, Int32, Int32);
typedef _InitModelDart = int Function(Pointer<Utf8>, int, int, int);

typedef _GenerateResponseNative = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _GenerateResponseDart = Pointer<Utf8> Function(Pointer<Utf8>);

typedef _FreeResponseNative = Void Function(Pointer<Utf8>);
typedef _FreeResponseDart = void Function(Pointer<Utf8>);

typedef _ReleaseModelNative = Void Function();
typedef _ReleaseModelDart = void Function();

class GemmaFfi {
  GemmaFfi._(DynamicLibrary dylib)
      : _initializeModel = _lookupInit(dylib),
        _generateResponse = _lookupGenerate(dylib),
        _freeResponse = _lookupFree(dylib),
        _releaseModel = _lookupRelease(dylib);

  final _InitModelDart _initializeModel;
  final _GenerateResponseDart _generateResponse;
  final _FreeResponseDart _freeResponse;
  final _ReleaseModelDart _releaseModel;

  static GemmaFfi? _instance;

  static GemmaFfi get instance {
    _instance ??= GemmaFfi._(_openLibrary());
    return _instance!;
  }

  static DynamicLibrary _openLibrary() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libllama_engine.so');
    }
    if (Platform.isIOS || Platform.isMacOS) {
      return DynamicLibrary.process();
    }
    throw UnsupportedError('Gemma FFI is only supported on mobile platforms.');
  }

  static _InitModelDart _lookupInit(DynamicLibrary dylib) {
    try {
      return dylib.lookupFunction<_InitModelNative, _InitModelDart>(
        'initialize_model',
      );
    } catch (_) {
      return dylib.lookupFunction<_InitModelNative, _InitModelDart>(
        'llama_init_model',
      );
    }
  }

  static _GenerateResponseDart _lookupGenerate(DynamicLibrary dylib) {
    try {
      return dylib.lookupFunction<_GenerateResponseNative, _GenerateResponseDart>(
        'generate_response',
      );
    } catch (_) {
      return dylib.lookupFunction<_GenerateResponseNative, _GenerateResponseDart>(
        'llama_generate_text',
      );
    }
  }

  static _FreeResponseDart _lookupFree(DynamicLibrary dylib) {
    try {
      return dylib.lookupFunction<_FreeResponseNative, _FreeResponseDart>(
        'free_response',
      );
    } catch (_) {
      return dylib.lookupFunction<_FreeResponseNative, _FreeResponseDart>(
        'llama_free_string',
      );
    }
  }

  static _ReleaseModelDart _lookupRelease(DynamicLibrary dylib) {
    try {
      return dylib.lookupFunction<_ReleaseModelNative, _ReleaseModelDart>(
        'release_model',
      );
    } catch (_) {
      return dylib.lookupFunction<_ReleaseModelNative, _ReleaseModelDart>(
        'llama_release_model',
      );
    }
  }

  bool initializeModel({
    required String modelPath,
    required int threads,
    required int contextSize,
    required int batchSize,
  }) {
    final modelPathPtr = modelPath.toNativeUtf8();
    try {
      final ok = _initializeModel(modelPathPtr, threads, contextSize, batchSize);
      return ok == 1;
    } finally {
      calloc.free(modelPathPtr);
    }
  }

  String generateResponse(String prompt) {
    final promptPtr = prompt.toNativeUtf8();
    try {
      final outPtr = _generateResponse(promptPtr);
      if (outPtr == nullptr) return '';
      final out = outPtr.toDartString();
      _freeResponse(outPtr);
      return out;
    } finally {
      calloc.free(promptPtr);
    }
  }

  void release() {
    _releaseModel();
  }
}
