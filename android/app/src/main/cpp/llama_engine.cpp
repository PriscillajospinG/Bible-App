// llama_engine.cpp
// Bridge between Flutter FFI and llama.cpp.
//
// Compile-time behaviour:
//   WITH llama.cpp  (llama.cpp/CMakeLists.txt present) → real inference
//   WITHOUT         → safe stub that returns a canned string so the app
//                     remains runnable on a build host that lacks the library.
//
// API pinned to llama.cpp b3447+ (sampler-chain API).
// Place llama.cpp as a git submodule at:
//   android/app/src/main/cpp/llama.cpp/

#include "llama_engine.h"

#include <cstring>
#include <mutex>
#include <string>
#include <vector>

#if __has_include("llama.cpp/include/llama.h")
  #include "llama.cpp/include/llama.h"
  #define HAVE_LLAMA_CPP 1
#elif __has_include("llama.h")
  #include "llama.h"
  #define HAVE_LLAMA_CPP 1
#else
  #define HAVE_LLAMA_CPP 0
#endif

// ── Runtime state ────────────────────────────────────────────────────────────

static std::mutex    g_mutex;

#if HAVE_LLAMA_CPP
static llama_model*   g_model   = nullptr;
static llama_context* g_ctx     = nullptr;

// ── Generation parameters (tuned for a 270M chat model) ──────────────────────
static constexpr int   kMaxNewTokens   = 512;
static constexpr float kTemperature    = 0.7f;
static constexpr float kTopP           = 0.9f;
static constexpr int32_t kTopK         = 40;
static constexpr float kRepeatPenalty  = 1.1f;
static constexpr int32_t kRepeatLastN  = 64;
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
                                    int32_t     threads,
                                    int32_t     context_size,
                                    int32_t     batch_size) {
    std::lock_guard<std::mutex> lock(g_mutex);

#if HAVE_LLAMA_CPP
    // Already initialised — idempotent.
    if (g_model != nullptr && g_ctx != nullptr) return 1;

    llama_backend_init();

    // Load model weights from the GGUF file.
    llama_model_params mparams = llama_model_default_params();
    g_model = llama_load_model_from_file(model_path, mparams);
    if (g_model == nullptr) return 0;

    // Create inference context.
    llama_context_params cparams = llama_context_default_params();
    cparams.n_ctx          = static_cast<uint32_t>(context_size);
    cparams.n_batch        = static_cast<uint32_t>(batch_size);
    cparams.n_threads      = threads;
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
    return 1; // stub: always reports success
#endif
}

extern "C" const char* llama_generate_text(const char* prompt) {
    std::lock_guard<std::mutex> lock(g_mutex);

#if HAVE_LLAMA_CPP
    if (g_model == nullptr || g_ctx == nullptr || prompt == nullptr) {
        return heap_string("[Error] Model not initialised.");
    }

    // ── 1. Tokenise the prompt ────────────────────────────────────────────
    const bool add_bos  = llama_should_add_bos_token(g_model);
    const bool parse_special = true;

    // Measure required buffer size first.
    int n_prompt_tokens = -llama_tokenize(
        g_model, prompt, static_cast<int32_t>(strlen(prompt)),
        nullptr, 0, add_bos, parse_special);

    if (n_prompt_tokens <= 0) {
        return heap_string("[Error] Tokenisation failed.");
    }

    std::vector<llama_token> prompt_tokens(n_prompt_tokens);
    llama_tokenize(
        g_model, prompt, static_cast<int32_t>(strlen(prompt)),
        prompt_tokens.data(), n_prompt_tokens, add_bos, parse_special);

    // ── 2. Decode the prompt tokens in one batch ──────────────────────────
    llama_kv_cache_clear(g_ctx);

    // Feed all prompt tokens except the last; the last is fed with decode.
    if (n_prompt_tokens > 1) {
        llama_batch batch = llama_batch_get_one(
            prompt_tokens.data(), n_prompt_tokens - 1);
        if (llama_decode(g_ctx, batch) != 0) {
            return heap_string("[Error] Prompt decode failed.");
        }
    }

    // ── 3. Build sampler chain ────────────────────────────────────────────
    llama_sampler* sampler = llama_sampler_chain_init(
        llama_sampler_chain_default_params());

    llama_sampler_chain_add(sampler,
        llama_sampler_init_top_k(kTopK));
    llama_sampler_chain_add(sampler,
        llama_sampler_init_top_p(kTopP, /*min_keep=*/1));
    llama_sampler_chain_add(sampler,
        llama_sampler_init_temp(kTemperature));
    llama_sampler_chain_add(sampler,
        llama_sampler_init_penalties(
            kRepeatLastN, kRepeatPenalty,
            /*alpha_frequency=*/0.0f, /*alpha_presence=*/0.0f));
    llama_sampler_chain_add(sampler,
        llama_sampler_init_dist(/*seed=*/LLAMA_DEFAULT_SEED));

    // ── 4. Autoregressive generation loop ────────────────────────────────
    std::string output;
    output.reserve(512);

    llama_token cur_token = prompt_tokens.back();

    for (int i = 0; i < kMaxNewTokens; ++i) {
        // Decode single token.
        llama_batch step_batch = llama_batch_get_one(&cur_token, 1);
        if (llama_decode(g_ctx, step_batch) != 0) break;

        // Sample next token.
        cur_token = llama_sampler_sample(sampler, g_ctx, -1);

        // Stop on EOS.
        if (llama_token_is_eog(g_model, cur_token)) break;

        // Detokenise and append.
        char piece_buf[256];
        int piece_len = llama_token_to_piece(
            g_model, cur_token, piece_buf, sizeof(piece_buf),
            /*special=*/false, /*lstrip=*/false);
        if (piece_len > 0) {
            output.append(piece_buf, static_cast<size_t>(piece_len));
        }

        // Accept into sampler state (tracks repetition history).
        llama_sampler_accept(sampler, cur_token);
    }

    llama_sampler_free(sampler);

    return heap_string(output.empty() ? "[No output generated]" : output);

#else
    // ── Stub path: used when llama.cpp is not linked ──────────────────────
    // Returns a clearly-marked placeholder so developers can distinguish
    // stub output from real inference during integration testing.
    std::string stub = "[Gemma stub — add llama.cpp submodule to enable real inference] ";
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
    if (g_ctx != nullptr)   { llama_free(g_ctx);        g_ctx   = nullptr; }
    if (g_model != nullptr) { llama_free_model(g_model); g_model = nullptr; }
    llama_backend_free();
#endif
}
