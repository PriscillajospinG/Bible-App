#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

int32_t llama_init_model(const char* model_path, int32_t threads, int32_t context_size, int32_t batch_size);
const char* llama_generate_text(const char* prompt);
void llama_free_string(const char* text_ptr);
void llama_release_model();

#ifdef __cplusplus
}
#endif
