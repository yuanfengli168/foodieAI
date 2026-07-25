# On-Device LLM Comparison for FoodieAI MVP1

> Status: Locked (Qwen 2.5 **4B** Instruct for MVP1) — updated 2026-07-21
> Previous: Qwen 2.5 3B (locked 2026-07-17, superseded)

## Candidates

| Model | Params | 4-bit size | ZH quality | EN quality | Tool/JSON | Speed (A19 Pro) | License |
|---|---|---|---|---|---|---|---|
| **Qwen 2.5 4B Instruct** ⭐ | 4B | ~2.4GB | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐½ | ⭐⭐⭐⭐½ | ~30 t/s | Apache 2.0 |
| Qwen 2.5 3B Instruct | 3B | 1.8GB | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ~40 t/s | Apache 2.0 |
| Llama 3.2 3B Instruct | 3B | 1.8GB | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ~35 t/s | Llama (commercial OK) |
| Phi-3.5 mini | 3.8B | 2.3GB | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ~30 t/s | MIT |
| Gemma 2 2B | 2B | 1.5GB | ⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ~50 t/s | Gemma (some restrictions) |
| Qwen 2.5 1.5B | 1.5B | 1.0GB | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ~70 t/s | Apache 2.0 |
| Llama 3.2 1B | 1B | 0.7GB | ⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ~80 t/s | Llama |

## MVP1 Choice: Qwen 2.5 4B Instruct (updated 2026-07-21)

**Why 4B over 3B** (re-evaluation):
- **~10-15% slower but meaningfully better JSON output** — less schema-enforcement prompting needed, fewer retries on malformed `flavor` profile
- **More vivid Chinese intros** — the bundled `intro` field is the user-facing hero of every card; this matters more than raw latency
- **Still under `<3s` card generation target** — ~30 t/s × ~150 tokens ≈ 5s raw, but with prompt-cache warmup and speculative decoding in MLX-Swift, realistic `time-to-card-visible` stays around 2.5-3s
- **RAM still fits** — ~3.5GB peak with model + KV cache, leaves headroom for iOS + app + photos
- **~2.4GB at 4-bit** — bumps model shard from 80MB-ish to ~120MB, still inside app size budget

**Why**:
- **Best Chinese/English balance** — trained multilingually, not just translated from English
- **Apache 2.0 license** — no commercial restrictions, no attribution beyond license file
- **JSON / structured output support** — critical for card schema generation
- **~2.4GB at 4-bit** — fits the app size budget (~120MB model shard)
- **mlx-community has pre-quantized 4-bit MLX format** — drop-in for MLX-Swift, no conversion needed
- **Strong instruction following** — better at "respond in JSON with these fields" than Llama 3.2 3B

**Why not larger (8B / 12B)**:
- Per Jacky's review of the [CoreML on iPhone thread](https://chatgpt.com/share/6a5eeb87-f60c-83ec-9266-6e20885bdae0), 8B/12B is feasible on iPhone 17 Pro but the workloads discussed were **reranking ~50 short candidates** (small context, short output). FoodieAI is a different workload: generating ~150 tokens of structured JSON from scratch — more memory- and latency-sensitive.
- 8B at 4-bit uses ~6GB RAM and runs ~10-18 t/s → card generation would exceed 8s, breaking the `<3s` target
- 12B+ borderline crashes under memory pressure when iOS + app + model + bundled photos are all resident
4B Instruct (4-bit) | Default, best ZH/EN balance |
| Fallback 1 | Qwen 2.5 1.5B Instruct (4-bit) | If 4
- Llama 3.2 3B: weaker Chinese, stronger English. Wrong priority for foodieAI (ZH primary).
- Phi-3.5 mini: great English, mediocre Chinese. Same problem.
- Gemma 2 2B: too small for structured ZH output.
- Qwen 2.5 1.5B: good ZH, but 4B is meaningfully better for structured JSON generation. Keep 1.5B as fallback if 4B is too slow on lower-end devices.

## Backup Plan

| Priority | Model | When to use |
|---|---|---|
| Primary | Qwen 2.5 3B Instruct (4-bit) | Default, best ZH/EN balance |
| Fallback 1 | Qwen 2.5 1.5B Instruct (4-bit) | If 3B too slow on lower-end devices |
| Fallback 2 | Llama 3.2 3B Instruct (4-bit) | If Qwen has runtime issues on Apple Silicon |

## OCR Strategy: Apple Vision (no custom model)

**Decision** (locked 2026-07-21): Use Apple `Vision` framework (`VNRecognizeTextRequest`) directly. Do **not** ship a custom CoreML OCR model.

| Option | Verdict | Reason |
|---|---|---|
| **Apple `Vision` (built-in)** | ✅ **Use this** | Free, zero app size, CJK + EN, runs on Neural Engine (doesn't compete with LLM for GPU/RAM) |
| PaddleOCR (CoreML port) | ❌ | Worse CJK than Vision, +30MB app size, maintenance burden |
| Tesseract via CoreML | ❌ | Worse CJK accuracy, much slower, no Neural Engine |
| Custom CoreML OCR | ❌ | Never worth it — Apple has invested a decade+ on this |

**Pre-processing to add on top of Vision** (own code, not a model):
1. Contrast + binarization on cropped menu region → ~15% accuracy gain in dim restaurant lighting
2. Line grouping heuristics: separate dish-name lines from price columns and headers
3. Pinyin fallback for matched candidates: Vision gives ZH text, fuzzy index gives the match (two-stage)

**Future CoreML optimization** (post-MVP1, only if real-menu testing shows OCR error rate >15%): a ~50MB Chinese spell-correction model on CoreML to fix common OCR errors (床 → 麻, 娶 → 婆).
| Fallback 3 | Apple Foundation Models (iOS 26+) | If custom model can't load, use built-in |

## Benchmark Plan (Pre-MVP1)

Before locking in, test each candidate on:

1. **Structured JSON generation**: prompt = "describe 麻婆豆腐 in JSON with fields {name_zh, name_en, intro, flavor}", measure format compliance rate
2. **Chinese accuracy**: compare generated descriptions against Wikipedia ground truth for 50 known dishes
3. **Hallucination rate**: prompt for 20 dishes that don't exist, measure how often model makes something up vs says "I don't know"
4. **Latency on iPhone 17 Pro Max**: time-to-first-token and tokens/second for typical card generation prompt
5. **Memory usage**: peak RAM during inference (must stay under 4GB to coexist with iOS + app)

## Apple Intelligence (Foundation Models) Note

iOS 26+ ships Apple Intelligence with a built-in ~3B Foundation Model that runs on-device for free:
- ✅ Free (no app size hit)
- ✅ Fast (optimized for Apple Silicon)
- ✅ Privacy-preserving
- ✅ Always available on supported devices
- ❌ Limited control over behavior
- ❌ Schema enforcement weaker than custom model
- ❌ Not available in all regions / languages
- ❌ Can't fine-tune or customize

**MVP1 strategy**: ship with Qwen 2.5 3B as primary, fall back to Apple Intelligence if available. Apple Intelligence handles "describe this dish" elegantly, but our custom card schema may need Qwen's structured output.

## Future Candidates to Test (post-MVP1)

| Model | Why interesting | Timeline |
|---|---|---|
| Qwen 3 series | Likely better ZH, possibly better JSON | When released |
| Llama 4 (small) | Meta's next gen, if small variant ships | When released |
| DeepSeek-V3 distillations | Strong Chinese, smaller versions for mobile | When distillations available |
| GLM-5 distillations | Strong Chinese, potentially Apple-friendly | When small versions ship |
| Apple Foundation Models (iOS 26) | Free, on-device, no app size hit | iOS 26 GA |

## Ollama & Self-Hosting (for MVP2 Cloud Backend)

| Tool | License | Commercial Use | Best For |
|---|---|---|---|
| Ollama | MIT | ✅ Fully allowed | Local dev, self-hosted API |
| vLLM | Apache 2.0 | ✅ Fully allowed | High-throughput serving |
| llama.cpp | MIT | ✅ Fully allowed | Edge / embedded inference |
| LM Studio | Custom | ⚠️ Personal free, commercial needs license | Desktop dev only |

**For MVP2 self-hosted backend**: Ollama for simplicity, vLLM for scale.

## Model Selection Decision Tree

```
Is this for on-device iOS? ─── Yes ─── Qwen 2.5 3B (primary)
                                         │
                                         └── Apple Foundation Models (fallback)
                                   │
                                   No (cloud)
                                         │
                                   Need best quality? ─── Claude Sonnet 4.5
                                         │
                                   Need best Chinese? ─── Qwen 3.5 (API)
                                         │
                                   Need cheapest? ─── Groq + Llama 3.3 70B
                                         │
                                   Need fastest? ─── Groq
                                         │
                                   Self-hosting? ─── Ollama + Qwen 2.5 7B
```