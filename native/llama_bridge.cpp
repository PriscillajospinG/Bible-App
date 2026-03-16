#include <cstdint>

#include "../android/app/src/main/cpp/llama_engine.h"

extern "C" int32_t initialize_model(
    const char* model_path,
    int32_t threads,
    int32_t context_size,
    int32_t batch_size) {
  return llama_init_model(model_path, threads, context_size, batch_size);
}

extern "C" const char* generate_response(const char* prompt) {
  return llama_generate_text(prompt);
}

extern "C" void free_response(const char* text_ptr) {
  llama_free_string(text_ptr);
}
