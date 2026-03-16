#include "llama_engine.h"

#include <android/log.h>

#include <cstring>
#include <mutex>
#include <string>
#include <vector>

#if __has_include("llama.h")
#include "llama.h"
#define HAVE_LLAMA_CPP 1
#else
#define HAVE_LLAMA_CPP 0
#endif

#define LOG_TAG "llama_bridge"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

static std::mutex g_mutex;

#if HAVE_LLAMA_CPP
static llama_model* g_model = nullptr;
static llama_context* g_ctx = nullptr;
static const llama_vocab* g_vocab = nullptr;

static constexpr int kMaxNewTokens = 512;
static constexpr float kTemperature = 0.7f;
static constexpr float kTopP = 0.9f;
static constexpr int32_t kTopK = 40;
static constexpr float kRepeatPenalty = 1.1f;
static constexpr int32_t kRepeatLastN = 64;
#endif

static char* heap_string(const std::string& s) {
  char* p = new char[s.size() + 1];
  std::copy(s.begin(), s.end(), p);
  p[s.size()] = '\0';
  return p;
}

extern "C" int32_t initialize_model(const char* model_path,
                                     int32_t threads,
                                     int32_t context_size,
                                     int32_t batch_size) {
  std::lock_guard<std::mutex> lock(g_mutex);

#if HAVE_LLAMA_CPP
  if (g_model != nullptr && g_ctx != nullptr) return 1;

  LOGI("Loading Gemma model...");
  llama_backend_init();

  llama_model_params mparams = llama_model_default_params();
  g_model = llama_model_load_from_file(model_path, mparams);
  if (g_model == nullptr) {
    LOGE("Failed to load model file: %s", model_path == nullptr ? "<null>" : model_path);
    return 0;
  }

  llama_context_params cparams = llama_context_default_params();
  cparams.n_ctx = static_cast<uint32_t>(context_size);
  cparams.n_batch = static_cast<uint32_t>(batch_size);
  cparams.n_threads = threads;
  cparams.n_threads_batch = threads;

  g_ctx = llama_init_from_model(g_model, cparams);
  if (g_ctx == nullptr) {
    LOGE("Failed to create llama context");
    llama_model_free(g_model);
    g_model = nullptr;
    return 0;
  }

  g_vocab = llama_model_get_vocab(g_model);
  if (g_vocab == nullptr) {
    LOGE("Failed to resolve model vocabulary");
    llama_free(g_ctx);
    g_ctx = nullptr;
    llama_model_free(g_model);
    g_model = nullptr;
    return 0;
  }

  LOGI("Gemma model initialized successfully");
  return 1;
#else
  (void)model_path;
  (void)threads;
  (void)context_size;
  (void)batch_size;
  LOGE("llama.cpp is not linked");
  return 0;
#endif
}

extern "C" const char* generate_response(const char* prompt) {
  std::lock_guard<std::mutex> lock(g_mutex);

#if HAVE_LLAMA_CPP
  if (g_model == nullptr || g_ctx == nullptr || g_vocab == nullptr || prompt == nullptr) {
    LOGE("generate_response called before model initialization");
    return heap_string("[Error] Model not initialised.");
  }

    const bool add_bos = llama_vocab_get_add_bos(g_vocab);
  const bool parse_special = true;

  int n_prompt_tokens = -llama_tokenize(
      g_vocab,
      prompt,
      static_cast<int32_t>(strlen(prompt)),
      nullptr,
      0,
      add_bos,
      parse_special);

  if (n_prompt_tokens <= 0) {
    LOGE("Prompt tokenization failed");
    return heap_string("[Error] Tokenisation failed.");
  }

  LOGI("Prompt tokens: %d", n_prompt_tokens);

  std::vector<llama_token> prompt_tokens(n_prompt_tokens);
  llama_tokenize(
      g_vocab,
      prompt,
      static_cast<int32_t>(strlen(prompt)),
      prompt_tokens.data(),
      n_prompt_tokens,
      add_bos,
      parse_special);

  llama_memory_clear(llama_get_memory(g_ctx), true);

  if (n_prompt_tokens > 1) {
    llama_batch batch = llama_batch_get_one(prompt_tokens.data(), n_prompt_tokens - 1);
    if (llama_decode(g_ctx, batch) != 0) {
      LOGE("Prompt decode failed");
      return heap_string("[Error] Prompt decode failed.");
    }
  }

  llama_sampler* sampler =
      llama_sampler_chain_init(llama_sampler_chain_default_params());
  llama_sampler_chain_add(sampler, llama_sampler_init_top_k(kTopK));
  llama_sampler_chain_add(sampler, llama_sampler_init_top_p(kTopP, 1));
  llama_sampler_chain_add(sampler, llama_sampler_init_temp(kTemperature));
  llama_sampler_chain_add(
      sampler,
      llama_sampler_init_penalties(kRepeatLastN, kRepeatPenalty, 0.0f, 0.0f));
  llama_sampler_chain_add(sampler, llama_sampler_init_dist(LLAMA_DEFAULT_SEED));

  LOGI("Running inference...");

  std::string output;
  output.reserve(1024);

  llama_token cur_token = prompt_tokens.back();
  int generated_tokens = 0;

  for (int i = 0; i < kMaxNewTokens; ++i) {
    llama_batch step = llama_batch_get_one(&cur_token, 1);
    if (llama_decode(g_ctx, step) != 0) break;

    cur_token = llama_sampler_sample(sampler, g_ctx, -1);
    if (llama_vocab_is_eog(g_vocab, cur_token)) break;

    char piece_buf[256];
    int piece_len = llama_token_to_piece(
      g_vocab,
        cur_token,
        piece_buf,
        sizeof(piece_buf),
      0,
      false);

    if (piece_len > 0) {
      output.append(piece_buf, static_cast<size_t>(piece_len));
      generated_tokens++;
    }

    llama_sampler_accept(sampler, cur_token);
  }

  llama_sampler_free(sampler);

  LOGI("Generated tokens: %d", generated_tokens);
  LOGI("Response complete");

  return heap_string(output.empty() ? "[Error] No output generated." : output);
#else
  (void)prompt;
  return heap_string("[Error] llama.cpp is not linked.");
#endif
}

extern "C" void free_response(const char* text_ptr) {
  delete[] text_ptr;
}

extern "C" void release_model() {
  std::lock_guard<std::mutex> lock(g_mutex);
#if HAVE_LLAMA_CPP
  if (g_ctx != nullptr) {
    llama_free(g_ctx);
    g_ctx = nullptr;
  }
  if (g_model != nullptr) {
    llama_model_free(g_model);
    g_model = nullptr;
  }
  g_vocab = nullptr;
  llama_backend_free();
#endif
}

// Backward-compatible exports expected by existing Dart code.
extern "C" int32_t llama_init_model(const char* model_path,
                                     int32_t threads,
                                     int32_t context_size,
                                     int32_t batch_size) {
  return initialize_model(model_path, threads, context_size, batch_size);
}

extern "C" const char* llama_generate_text(const char* prompt) {
  return generate_response(prompt);
}

extern "C" void llama_free_string(const char* text_ptr) {
  free_response(text_ptr);
}

extern "C" void llama_release_model() {
  release_model();
}
