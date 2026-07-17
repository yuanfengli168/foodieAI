# On-Device LLM Comparison for FoodieAI MVP1

> Status: Locked (Qwen 2.5 3B for MVP1)
> Last updated: 2026-07-17

## Candidates

| Model | Params | 4-bit size | ZH quality | EN quality | Tool/JSON | Speed (A19 Pro) | License |
|---|---|---|---|---|---|---|---|
| **Qwen 2.5 3B Instruct** | 3B | 1.8GB | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ~40 t/s | Apache 2.0 |
| Llama 3.2 3B Instruct | 3B | 1.8GB | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ~35 t/s | Llama (commercial OK) |
| Phi-3.5 mini | 3.8B | 2.3GB | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ~30 t/s | MIT |
| Gemma 2 2B | 2B | 1.5GB | ⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ~50 t/s | Gemma (some restrictions) |
| Qwen 2.5 1.5B | 1.5B | 1.0GB | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ~70 t/s | Apache 2.0 |
| Llama 3.2 1B | 1B | 0.7GB | ⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ~80 t/s | Llama |

## MVP1 Choice: Qwen 2.5 3B Instruct

**Why**:
- **Best Chinese/English balance** — trained multilingually, not just translated from English
- **Apache 2.0 license** — no commercial restrictions, no attribution beyond license file
- **JSON / structured output support** — critical for card schema generation
- **1.8GB at 4-bit** — fits the app size budget (80MB-ish for model shard)
- **~40 tokens/sec on A19 Pro** — well under 2s target for card generation
- **mlx-community has pre-quantized 4-bit MLX format** — drop-in for MLX-Swift, no conversion needed
- **Strong instruction following** — better at "respond in JSON with these fields" than Llama 3.2 3B

**Why not others**:
- Llama 3.2 3B: weaker Chinese, stronger English. Wrong priority for foodieAI (ZH primary).
- Phi-3.5 mini: great English, mediocre Chinese. Same problem.
- Gemma 2 2B: too small for structured ZH output.
- Qwen 2.5 1.5B: good ZH, but 3B is better for structured JSON generation. Keep 1.5B as fallback if 3B is too slow on device.

## Backup Plan

| Priority | Model | When to use |
|---|---|---|
| Primary | Qwen 2.5 3B Instruct (4-bit) | Default, best ZH/EN balance |
| Fallback 1 | Qwen 2.5 1.5B Instruct (4-bit) | If 3B too slow on lower-end devices |
| Fallback 2 | Llama 3.2 3B Instruct (4-bit) | If Qwen has runtime issues on Apple Silicon |
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