// llama_engine.mm
// iOS / macOS native bridge for llama.cpp — mirrors Android llama_engine.cpp.
//
// Symbols are statically linked into the Runner binary, so Flutter FFI can
// resolve them via DynamicLibrary.process().
//
// Setup:
//   1. Add this file to the Runner target in Xcode.
//   2. Add llama.cpp sources to the Runner target (or via a CocoaPod/SPM).
//   3. Set "Enable C++ Exception Handling" = YES in Runner Build Settings.
//   4. Confirm Minimum Deployment Target ≥ iOS 14.

#import <Foundation/Foundation.h>
#include <mutex>
#include <string>
#include <vector>
#include <cstring>

// Detect llama.cpp presence. Place llama.cpp as a sibling folder or link via
// a CocoaPod that exposes the llama.h header.
#if __has_include("llama.h")
  #include "llama.h"
  #define HAVE_LLAMA_CPP 1
#else
  #define HAVE_LLAMA_CPP 0
#endif

// ── Runtime state ─────────────────────────────────────────────────────────────

static std::mutex g_mutex;

#if HAVE_LLAMA_CPP
static llama_model*   g_model = nullptr;
static llama_context* g_ctx   = nullptr;

static constexpr int   kMaxNewTokens  = 512;
static constexpr float kTemperature   = 0.7f;
static constexpr float kTopP          = 0.9f;
static constexpr int32_t kTopK        = 40;
static constexpr float kRepeatPenalty = 1.1f;
static constexpr int32_t kRepeatLastN = 64;
#endif

// ── Helpers ───────────────────────────────────────────────────────────────────

static char* heap_string(const std::string& s) {
    char* p = new char[s.size() + 1];
    std::copy(s.begin(), s.end(), p);
    p[s.size()] = '\0';
    return p;
}

// ── Public C API ──────────────────────────────────────────────────────────────

extern "C" int32_t llama_init_model(const char* model_path,
                                    int32_t threads,
                                    int32_t context_size,
                                    int32_t batch_size) {
    std::lock_guard<std::mutex> lock(g_mutex);

#if HAVE_LLAMA_CPP
    if (g_model != nullptr && g_ctx != nullptr) return 1;

    llama_backend_init();

    llama_model_params mparams = llama_model_default_params();
    g_model = llama_load_model_from_file(model_path, mparams);
    if (g_model == nullptr) return 0;

    llama_context_params cparams = llama_context_default_params();
    cparams.n_ctx           = static_cast<uint32_t>(context_size);
    cparams.n_batch         = static_cast<uint32_t>(batch_size);
    cparams.n_threads       = threads;
    cparams.n_threads_batch = threads;

    g_ctx = llama_new_context_with_model(g_model, cparams);
    if (g_ctx == nullptr) {
        llama_free_model(g_model);
        g_model = nullptr;
        return 0;
    }
    return 1;
#else
    (void)model_path; (void)threads; (void)context_size; (void)batch_size;
    return 1;
#endif
}

extern "C" const char* llama_generate_text(const char* prompt) {
    std::lock_guard<std::mutex> lock(g_mutex);

#if HAVE_LLAMA_CPP
    if (g_model == nullptr || g_ctx == nullptr || prompt == nullptr) {
        return heap_string("[Error] Model not initialised.");
    }

    // 1. Tokenise prompt.
    const bool add_bos      = llama_should_add_bos_token(g_model);
    const bool parse_special = true;

    int n_prompt = -llama_tokenize(
        g_model, prompt, static_cast<int32_t>(strlen(prompt)),
        nullptr, 0, add_bos, parse_special);
    if (n_prompt <= 0) return heap_string("[Error] Tokenisation failed.");

    std::vector<llama_token> tokens(n_prompt);
    llama_tokenize(g_model, prompt, static_cast<int32_t>(strlen(prompt)),
                   tokens.data(), n_prompt, add_bos, parse_special);

    // 2. Decode prompt tokens.
    llama_kv_cache_clear(g_ctx);
    if (n_prompt > 1) {
        llama_batch batch = llama_batch_get_one(tokens.data(), n_prompt - 1);
        if (llama_decode(g_ctx, batch) != 0) {
            return heap_string("[Error] Prompt decode failed.");
        }
    }

    // 3. Build sampler chain.
    llama_sampler* sampler = llama_sampler_chain_init(
        llama_sampler_chain_default_params());
    llama_sampler_chain_add(sampler, llama_sampler_init_top_k(kTopK));
    llama_sampler_chain_add(sampler, llama_sampler_init_top_p(kTopP, 1));
    llama_sampler_chain_add(sampler, llama_sampler_init_temp(kTemperature));
    llama_sampler_chain_add(sampler,
        llama_sampler_init_penalties(kRepeatLastN, kRepeatPenalty, 0.0f, 0.0f));
    llama_sampler_chain_add(sampler,
        llama_sampler_init_dist(LLAMA_DEFAULT_SEED));

    // 4. Generation loop.
    std::string output;
    output.reserve(512);
    llama_token cur = tokens.back();

    for (int i = 0; i < kMaxNewTokens; ++i) {
        llama_batch step = llama_batch_get_one(&cur, 1);
        if (llama_decode(g_ctx, step) != 0) break;

        cur = llama_sampler_sample(sampler, g_ctx, -1);
        if (llama_token_is_eog(g_model, cur)) break;

        char buf[256];
        int len = llama_token_to_piece(g_model, cur, buf, sizeof(buf), false, false);
        if (len > 0) output.append(buf, static_cast<size_t>(len));
        llama_sampler_accept(sampler, cur);
    }

    llama_sampler_free(sampler);
    return heap_string(output.empty() ? "[No output generated]" : output);

#else
    std::string stub = "[iOS stub — add llama.cpp to Runner target] ";
    if (prompt != nullptr) stub += prompt;
    return heap_string(stub);
#endif
}

extern "C" void llama_free_string(const char* text_ptr) {
    delete[] text_ptr;
}

extern "C" void llama_release_model() {
    std::lock_guard<std::mutex> lock(g_mutex);
#if HAVE_LLAMA_CPP
    if (g_ctx   != nullptr) { llama_free(g_ctx);        g_ctx   = nullptr; }
    if (g_model != nullptr) { llama_free_model(g_model); g_model = nullptr; }
    llama_backend_free();
#endif
}
