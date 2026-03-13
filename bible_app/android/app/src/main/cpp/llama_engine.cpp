#include "llama_engine.h"

#include <mutex>
#include <string>

#if __has_include("llama.h")
#include "llama.h"
#define HAVE_LLAMA_CPP 1
#else
#define HAVE_LLAMA_CPP 0
#endif

#if HAVE_LLAMA_CPP
static llama_model* g_model = nullptr;
static llama_context* g_ctx = nullptr;
#endif

static std::mutex g_mutex;

extern "C" int32_t llama_init_model(const char* model_path, int32_t threads, int32_t context_size, int32_t batch_size) {
  std::lock_guard<std::mutex> lock(g_mutex);

#if HAVE_LLAMA_CPP
  if (g_model != nullptr && g_ctx != nullptr) {
    return 1;
  }

  llama_backend_init();

  llama_model_params mparams = llama_model_default_params();
  g_model = llama_load_model_from_file(model_path, mparams);
  if (g_model == nullptr) {
    return 0;
  }

  llama_context_params cparams = llama_context_default_params();
  cparams.n_ctx = context_size;
  cparams.n_batch = batch_size;
  cparams.n_threads = threads;
  cparams.n_threads_batch = threads;

  g_ctx = llama_new_context_with_model(g_model, cparams);
  if (g_ctx == nullptr) {
    llama_free_model(g_model);
    g_model = nullptr;
    return 0;
  }

  return 1;
#else
  (void)model_path;
  (void)threads;
  (void)context_size;
  (void)batch_size;
  return 1;
#endif
}

extern "C" const char* llama_generate_text(const char* prompt) {
  std::lock_guard<std::mutex> lock(g_mutex);

#if HAVE_LLAMA_CPP
  // Placeholder generation path using llama.cpp runtime.
  // Integrate your full tokenization + sampling loop here against your pinned
  // llama.cpp version for production behavior.
  std::string out = "[Gemma local] ";
  if (prompt != nullptr) {
    out += prompt;
  }
#else
  std::string out = "[Gemma fallback] ";
  if (prompt != nullptr) {
    out += prompt;
  }
#endif

  char* heap = new char[out.size() + 1];
  std::copy(out.begin(), out.end(), heap);
  heap[out.size()] = '\0';
  return heap;
}

extern "C" void llama_free_string(const char* text_ptr) {
  if (text_ptr != nullptr) {
    delete[] text_ptr;
  }
}

extern "C" void llama_release_model() {
  std::lock_guard<std::mutex> lock(g_mutex);
#if HAVE_LLAMA_CPP
  if (g_ctx != nullptr) {
    llama_free(g_ctx);
    g_ctx = nullptr;
  }
  if (g_model != nullptr) {
    llama_free_model(g_model);
    g_model = nullptr;
  }
  llama_backend_free();
#endif
}
