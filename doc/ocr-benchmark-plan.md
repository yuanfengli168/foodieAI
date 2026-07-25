# Real-Menu OCR Benchmark Plan (MVP1)

> Status: Open
> Created: 2026-07-21
> Owner: Jacky
> Purpose: Validate Apple `Vision` OCR on real Chinese restaurant menus before locking the iOS architecture.

---

## Why this matters

The MVP1 architecture assumes `VNRecognizeTextRequest` will return clean CJK + EN text from a phone photo of a restaurant menu. If this assumption is wrong, the entire pipeline (OCR → fuzzy index → card) breaks at the first step. This benchmark must run **before** significant iOS code is written.

## Scope & pass criteria

| | |
|---|---|
| **Target device** | iPhone 17 Pro or Pro Max (A19 Pro) |
| **iOS version** | iOS 26+ |
| **OCR API** | `VNRecognizeTextRequest`, `.accurate` level, `.revision3` (iOS 26) |
| **Pass criterion** | ≥85% of dish-name lines correctly recognized on ≥80% of menus |
| **Re-evaluate trigger** | If <85% line accuracy OR <80% menu pass-rate → architecture rethink needed (custom CoreML OCR? Vision-only with stronger pre-processing? Different capture flow?) |

## Sample size

- **15-20 menus** total
- **5-6 cuisine types** (must include all 4 MVP1 cuisines + 1-2 stretch cases):
  - 川 (Sichuan) — 4 menus
  - 粤 (Cantonese) — 3 menus
  - 鲁 (Shandong) — 2 menus
  - 淮扬 (Huaiyang) — 2 menus
  - 西餐 (Western) — 2 menus (for EN coverage)
  - 火锅 / 烧烤 (stretch) — 2 menus
- **3-5 cities** to capture font/print variation
- **Mix of conditions**:
  - 50% printed plastic menu (best case)
  - 25% paper / handwritten specials board
  - 25% backlit LED board / dim lighting (worst case)

## Capture protocol

For each menu:
1. Photograph **straight-on** (top-down or eye-level) — no angle >15°
2. Photograph **with flash off** in restaurant lighting
3. Photograph **one full page** + **one zoomed crop** of a representative section
4. Note the **condition**: lighting, font style, presence of prices/photos/icons
5. Record **ground truth**: manually transcribe every dish line as `[zh_text, pinyin, en_translation]`

## Measurement methodology

For each menu photo, run it through the iOS prototype and measure:

| Metric | Definition | Pass threshold |
|---|---|---|
| **Line-level accuracy** | % of dish-name lines that appear in OCR output with the correct characters | ≥85% |
| **Menu-level pass rate** | % of menus where ≥80% of dish lines are correctly recognized | ≥80% |
| **CJK coverage** | % of menu lines that include at least one CJK character (sanity check) | ≥95% (excludes pure-price lines) |
| **Price-line bleed** | % of OCR lines that are prices mistakenly attached to dish names | <5% |
| **End-to-end latency** | Time from photo capture to dish list visible | <3s (matches MVP1 target) |

## Error taxonomy (categorize every miss)

To decide what to fix, classify each OCR error into one of:

| Error class | Example | Fix |
|---|---|---|
| Single-char misread | 麻婆 → 床婆 | Post-OCR spell correction (CoreML, post-MVP1) |
| Vertical/horizontal confusion | 麻 / 並 | Layout analysis in pre-processing |
| Photo-with-text confusion | 鸡 icon next to 宫保鸡丁 | Region segmentation |
| Price column merged | 麻婆豆腐 28元 → "麻婆豆腐 28元" as one line | Line grouping heuristic |
| Font too stylized | 麻辣烫 in cursive script | Reject and prompt user for clearer photo |
| Lighting too dark | (whole line missed) | Pre-processing: contrast/binarize |

## Time estimate

| Activity | Hours |
|---|---|
| Menu collection (visit 4-5 restaurants × ~1.5h each) | 6-8 |
| Photographing per menu (~15 min × 20 menus) | 5 |
| Manual transcription of ground truth (~30 min × 20 menus) | 10 |
| Run prototype on each photo + record metrics | 4-6 |
| Categorize errors | 2-3 |
| **Total** | **27-32 hours** (one weekend + 2 evenings) |

## Deliverables

1. `data/benchmark/menus/` — 20 captured photos + ground-truth JSON
2. `data/benchmark/results.csv` — per-menu metrics
3. `data/benchmark/error_taxonomy.md` — categorized misses with proposed fixes
4. **Go/No-go decision** for the MVP1 architecture (logged into `feedback-log.md`)

## When to run this

**Before** any meaningful iOS code is written. Best case: this weekend (2026-07-25/26).
Latest acceptable: before locking the 100 Chinese + 100 Western dish lists into the DB.

## Open questions

1. Does the user have access to 15-20 unique menus? (Likely yes if traveling or living in a Chinese-speaking city.)
2. Will any of the restaurants be the same across cuisines (helps control for menu-design variation)?
3. Should we include menus in vertical-traditional layouts (繁體中文) or stick to Simplified only?
