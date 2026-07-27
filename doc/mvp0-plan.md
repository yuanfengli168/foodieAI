# FoodieAI MVP0 — End-to-End Spike

> Status: Planning (locked scope 2026-07-21, updated 2026-07-25 Round 5)
> Owner: Jacky
> Target: ship a working iOS-native full-stack app on iPhone 17 Pro Max in 7-10 days
> Goal: prove the entire pipeline (OCR → fuzzy index → LLM card gen → UI) on 2 real menus before locking MVP1 architecture

---

## 1. Scope (locked 2026-07-21, updated 2026-07-25)

| | |
|---|---|
| **Platform** | iOS native, SwiftUI, iOS 18 deployment target |
| **Test device** | iPhone 17 Pro Max (A19 Pro, 12GB RAM) |
| **Menus** | 2 restaurants, 86 + 40 = 126 dishes total |
| **Menu A** | Noodle Gourmet NJ — Chinese-American, EN-only, 86 dishes |
| **Menu B** | Zhang Gui 掌櫃 SG — Northern Chinese, ZH+EN, 40 visible dishes |
| **DB** | Bundled JSON, read-only, 126 cards in `dishes.jsonl` |
| **LLM** | **Apple Foundation Models (iOS 26 system, primary)** + Qwen 2.5 4B (bundled fallback) + Qwen 2.5 3B (thermal fallback). Runtime picker in Settings. |
| **LLM priority** | **Apple Foundation Models → Qwen 4B → Qwen 3B** (R6 Q2: Apple FM for free + zero app size, Qwen for richer ZH / stricter JSON, 3B for thermals) |
| **OCR** | Apple `Vision` framework, `.accurate`, `.revision3` (iOS 26) |
| **OCR UX** | **Auto-start on capture → dish list (no review screen in MVP0)**. D-012 review screen deferred to MVP1. Hidden long-press hook for "Re-edit OCR results" in MVP0. |
| **Search** | Fuzzy (EN / ZH / pinyin transliteration), no exact-match mode |
| **Card source tags** | 📖 Wikipedia/百度百科, 📷 Menu-verified, 🤖 LLM-only. **🤖 cards are HIDDEN from the list entirely** when the Settings toggle is off (R5 Q3). |
| **Schema enforcement** | Simple: 1 retry on bad JSON, generic error after |
| **Failure visibility** | Xcode console only (no on-device log viewer in MVP0) |
| **UI design** | Warm foodie notebook: cream bg + terracotta accent + sage + gold. See `ui-design-brief.md` |
| **Photos** | Emoji-only fallback in MVP0 (per R5 Q1). No Wikimedia downloads. |
| **MVP0 pass criteria** | All 126 dishes return cards, OCR + fuzzy match works on both menus, all 3 LLMs produce valid JSON for ≥90% of dishes, **user (Jacky) personally judges the app "good"** (R5 Q14) across all 4 axes: speed, card quality, OCR accuracy, fun to use. |

### Out of scope for MVP0 (deferred to MVP1+)
- Live camera preview with region detection
- Per-line OCR review screen (D-012 → MVP1, R5 Q1)
- Apple Maps / restaurant finder
- Allergens / dietary
- Multi-language beyond EN/ZH
- User-contributed content
- **Recipe generation → MVP1+** (R5 Q8; brainstorm originally said MVP1, was logged as MVP3 in R4 summary, corrected to MVP1+ here)
- Cook-along mode
- Voice input
- DB updates
- App Store IAP
- Dark mode (light only)
- iPad-specific layout (iPhone only; iPad runs in compat)
- Custom hand-drawn sketches (emoji only in MVP0)
- Synonym map for fuzzy search → MVP1 (R5 Q5)
- OCR real-menu benchmark → MVP1 (R5 Q12)

---

## 2. File / folder structure

```
foodieAI/
├── README.md
├── LICENSE
├── doc/
│   ├── brainstorm.md            (existing)
│   ├── model-comparison.md      (existing, updated)
│   ├── mvp2-paid.md             (existing)
│   ├── feedback-log.md          (existing, append-only)
│   ├── ocr-benchmark-plan.md    (existing)
│   ├── mvp0-plan.md             ← you are here
│   └── data-sourcing.md         (TODO: card authoring rules)
├── data/
│   ├── menus/
│   │   ├── menu-a-sg-en.json   (50 dishes, EN-only Singapore)
│   │   └── menu-b-bj-zh.json   (50 dishes, ZH-only Beijing)
│   ├── dishes/
│   │   └── dishes.jsonl         (all 100 dishes, one JSON per line, single source of truth)
│   ├── photos/                  (1 photo per dish where available; emoji fallback otherwise)
│   ├── synonyms.json            (small hand-curated synonym map, e.g. "tofu" ↔ "doufu")
│   └── ground-truth/            (manually-transcribed menu text + per-line dish mapping)
├── ios/
│   ├── FoodieAI.xcodeproj
│   ├── FoodieAI/
│   │   ├── App/
│   │   │   └── FoodieAIApp.swift
│   │   ├── Models/
│   │   │   ├── Dish.swift                  (Codable mirror of dishes.jsonl schema)
│   │   │   ├── FlavorProfile.swift
│   │   │   ├── CardSource.swift            (enum: wikipedia, baidu_baike, menuVerified, llmOnly)
│   │   │   └── LLMBackend.swift            (enum: appleFoundation, qwen4b, qwen3b) |
│   │   ├── Data/
│   │   │   ├── DishRepository.swift        (loads + indexes bundled JSON)
│   │   │   ├── FuzzyIndex.swift            (Levenshtein on pinyin, EN substring, ZH substring)
│   │   │   ├── PinyinConverter.swift       (ZH → pinyin without tones, hand-rolled lookup table)
│   │   │   └── SynonymMap.swift            (loads synonyms.json)
│   │   ├── OCR/
│   │   │   ├── OCRService.swift            (wraps VNRecognizeTextRequest, returns per-line confidence)
│   │   │   └── OCRLine.swift               (struct: text, confidence, bbox, isPrice)
│   │   ├── LLM/
│   │   │   ├── LLMService.swift            (protocol, picks backend)
│   │   │   ├── MLXQwenBackend.swift        (Qwen 2.5 3B/4B via MLX-Swift)
│   │   │   ├── AppleIntelligenceBackend.swift  (iOS 26 Foundation Models)
│   │   │   ├── CardGenerator.swift         (prompt template + JSON parser + 1-retry logic)
│   │   │   └── PromptTemplates.swift       (system + user prompt for card generation)
│   │   ├── Camera/
│   │   │   ├── CameraService.swift         (AVCaptureSession wrapper, live capture)
│   │   │   └── PhotoPickerService.swift    (PHPickerViewController wrapper)
│   │   ├── Views/
│   │   │   ├── ContentView.swift           (root: search bar + camera + plus + list)
│   │   │   ├── DishListRow.swift           (name_zh (name_en), source tag)
│   │   │   ├── DishCardView.swift          (full card: photo, intro, flavor, pair_with, source)
│   │   │   ├── OCRReviewView.swift         (per-line confidence UI + edit-before-confirm)
│   │   │   ├── SettingsView.swift          (LLM picker, about, version)
│   │   │   └── Components/
│   │   │       ├── SourceTag.swift         (📖📷🤖 badge)
│   │   │       ├── FlavorBar.swift         (5-bar flavor visualization)
│   │   │       └── ErrorBanner.swift       (top-of-screen error toast)
│   │   ├── Errors/
│   │   │   ├── FoodieAIError.swift         (typed error enum, all 20+ cases)
│   │   │   └── ErrorMessages.swift         (user-facing strings per case)
│   │   ├── Resources/
│   │   │   ├── models/
│   │   │   │   ├── Qwen2.5-4B-Instruct-4bit/
│   │   │   │   └── Qwen2.5-3B-Instruct-4bit/
│   │   │   ├── Assets.xcassets              (icons, app icon)
│   │   │   └── Info.plist                   (camera + photo library usage strings)
│   │   └── Logging/
│   │       └── Log.swift                    (os_log wrapper, console-only in MVP0)
│   └── FoodieAITests/
│       ├── FuzzyIndexTests.swift           (50 known queries, expected top match)
│       ├── OCRServiceTests.swift           (golden test photos with known output)
│       ├── CardGeneratorTests.swift        (mock backend returns canned JSON)
│       └── DishRepositoryTests.swift       (bundle loading, schema validation)
└── scripts/
    ├── build_dishes.py         (merges menu JSONs + sources + LLM-generated intros → dishes.jsonl)
    ├── llm_batch_cards.py      (Qwen 3.5 cloud batch to fill in 70 LLM-only cards)
    └── download_photos.py      (Wikipedia Commons for verified dishes)
```

---

## 3. Dish card JSON schema (frozen for MVP0)

Each line in `data/dishes/dishes.jsonl` is one dish:

```json
{
  "id": "mapo_tofu",
  "name_zh": "麻婆豆腐",
  "name_en": "Mapo Tofu",
  "pinyin": "ma po dou fu",
  "aliases_en": ["pockmarked grandmother tofu", "spicy tofu"],
  "aliases_zh": [],
  "photo_path": "photos/mapo_tofu.jpg",
  "emoji_fallback": "🌶️",
  "source": "wikipedia",
  "source_url": "https://en.wikipedia.org/wiki/Mapo_tofu",
  "is_menu_verified": true,
  "intro": "Silken tofu in fiery chili-bean sauce with ground pork and numbing Sichuan peppercorns.",
  "flavor": {
    "spicy": 4,
    "sour": 0,
    "salty": 3,
    "sweet": 1,
    "numbing": 5
  },
  "pair_with": ["steamed rice", "jasmine tea"],
  "region": "Sichuan",
  "category": "main",
  "tags": ["vegetarian-option", "spicy", "rice-pair"]
}
```

**`source` enum**: `wikipedia` | `baidu_baike` | `wikipedia+baidu` | `menu_verified` | `llm_only`
**`is_menu_verified`**: `true` if the dish appears in one of the 2 MVP0 menus (independent of source enum)
**`flavor` values**: 0-5 scale (0 = none, 5 = extreme)
**`photo_path`**: empty string → fall back to `emoji_fallback` in UI

---

## 4. Fuzzy search algorithm

### Pipeline

```
User types "spicy tofy"
    ↓
1. Normalize: lowercase, strip punctuation, trim whitespace
    ↓
2. Apply synonym map: "tofu" → "doufu" (or vice versa)
    ↓
3. Candidate generation (run all 3, take union):
    a. EN substring match against name_en + aliases_en
    b. EN Levenshtein(≤2) against name_en + aliases_en
    c. Pinyin Levenshtein(≤2) against pinyin (input converted via same lookup)
    d. ZH substring match against name_zh + aliases_zh (if input has CJK chars)
    ↓
4. Score each candidate:
    score = (1.0 if exact match else 0.0)
          + (0.5 if substring match else 0.0)
          + (1.0 - edit_distance / max(len(input), len(target)))
          + 0.3 if pinyin match else 0.0
          + 0.2 if menu_verified else 0.0
    ↓
5. Return top N (configurable, default 10), sorted by score desc
    ↓
6. If top result score < 0.5: show "no confident match" UI
```

### Pinyin conversion

- **Hand-rolled lookup table** for the 100 MVP0 dishes (bundled in `PinyinConverter.swift` as a `[String: String]` map of `name_zh → pinyin`)
- **No runtime pinyin conversion** in MVP0 (avoids 5MB+ pinyin library)
- Synonyms file has parallel `pinyin: "..."` field for the same dish, so even if user types "ma po" we get it
- MVP1 can add a proper pinyin library (`Pinyin-Swift`, MIT) for the full 100-dish DB

### Synonym map (`synonyms.json`)

```json
{
  "tofu": "doufu",
  "chicken": "ji",
  "rice": "fan",
  "noodle": "mian",
  "noodles": "mian",
  "spicy": null,
  "hot": null,
  "fried": "chao"
}
```

- `value: null` = decorative word, ignore in search
- `value: "..."` = treat as equivalent to this word

---

## 5. OCR pipeline (MVP0: auto-start, no review screen)

```
User taps 📷 (camera) or + (library)
    ↓
1. Capture / pick photo
    ↓
2. **AUTO-START: immediately run OCR + fuzzy match** (R5 Q1; no review screen in MVP0)
    ↓
3. UIImage → CGImage (already in CIImage-compatible form)
    ↓
4. VNRecognizeTextRequest with:
    - recognitionLevel: .accurate
    - revision: VNRecognizeTextRequestRevision3  (iOS 26) — better CJK accuracy, R6 update
    - usesLanguageCorrection: true
    - recognitionLanguages: ["en-US", "zh-Hans"]
    ↓
5. Receive VNRecognizedTextObservation array
    ↓
6. For each observation:
    - topCandidates(1) → OCRLine(text, confidence, bbox)
    - heuristic price detection: if text matches /^\d+(\.\d+)?[元¥$]?$/
      → mark isPrice=true
    ↓
7. Group lines into menu rows:
    - sort by bbox.minY, group within 20pt vertical tolerance
    - same-row price: attach to nearest non-price line on right
    ↓
8. **Fuzzy match each row against the dish DB** (skip the per-line confidence display)
    ↓
9. Push to DishListView with matched dishes
    ↓
10. DishListView shows matched dishes, tap → DishCardView
```

### MVP0 behavior (locked Round 5)
- **No OCR review screen.** D-012 (per-line confidence + edit-before-confirm) is **deferred to MVP1**.
- Capture itself triggers the entire pipeline. User sees a spinner for ~2 seconds, then the dish list.
- **Hidden MVP1 hook**: long-press a dish row → "Re-edit OCR results" (disabled in MVP0, but the data model supports it so the hook can be enabled in MVP1 without refactoring).

### MVP1 behavior (out of MVP0 scope)
- Insert a `OCRReviewView` between step 9 and step 10 of the above pipeline
- Per-line confidence display, color-coded, edit-in-place for low-confidence lines
- See `mvp0-plan.md` historical version (pre-2026-07-25) for the original MVP0 OCR review spec — that's the MVP1 spec now

### Confidence thresholds (deferred to MVP1, kept here for reference)
- ≥0.85: green, auto-confirm on "Use list" tap
- 0.60-0.85: yellow, show but flag for review
- <0.60: red, require user edit or explicit "include anyway" tap


---

## 6. LLM glue

### Backend selection (priority order locked Round 6 — 2026-07-26)
- `LLMBackend.appleFoundation` → iOS 26 system model via `LanguageModelSession`. **PRIMARY** — free, zero app size, instant, runs on ANE.
- `LLMBackend.qwen4b` → load `Qwen2.5-4B-Instruct-4bit/` via MLX-Swift. **BUNDLED FALLBACK** — best ZH/JSON quality, ~2.4GB app size cost.
- `LLMBackend.qwen3b` → load `Qwen2.5-3B-Instruct-4bit/` via MLX-Swift. **THERMAL FALLBACK** — auto-switch if 4B is OOMing or device is hot.

User picks the backend in Settings; the picker is runtime-switchable without restart (R5 Q5).

### Why Apple Foundation Models is now primary (R6 rationale)
See [`model-comparison.md`](model-comparison.md) §MVP1 Choice for full reasoning. TL;DR: iOS 26 ships a free on-device ~3B model that any app can call. Zero app size, zero first-launch cost, better thermals, easier App Store review. Qwen 4B is bundled as fallback for cases where Apple FM gives weaker JSON or less vivid Chinese.

### Backend auto-fallback (if selected backend fails)
1. Try the user-selected backend
2. If it throws (model not loaded, OOM, schema fail) → fall through the priority list
3. Apple FM → Qwen 4B → Qwen 3B (in that order)
4. If all fail → show `Couldn't generate card. Tap to retry.`

### Per-backend behavior notes
- **Apple Foundation Models**: best-effort, may say "I don't know" for obscure dishes. Lenient JSON parsing (strip markdown fences, look for first `{...}` block).
- **Qwen 4B**: strict JSON mode works, schema enforcement via prompt. ~2.5s first-token, ~30 t/s after.
- **Qwen 3B**: same as 4B but ~1.8s first-token, ~40 t/s. Lower thermals.

### Card generation prompt (system)

```
You are a food encyclopedia. Given a dish name, respond with ONLY a JSON object matching this schema. No prose, no markdown fences.

{
  "intro": "string, 2-4 sentences vivid description",
  "flavor": {"spicy": 0-5, "sour": 0-5, "salty": 0-5, "sweet": 0-5, "numbing": 0-5},
  "pair_with": ["string", "string"],
  "region": "string",
  "category": "main|side|soup|noodle|rice|dessert|drink"
}

Constraints:
- intro: at least 20 words, at most 80 words
- flavor: all 5 fields required, integers 0-5
- pair_with: 1-4 items
- region: most common region for this dish
- category: pick exactly one
- If you don't know the dish, return {"error": "unknown_dish"}
```

### Card generation prompt (user)

```
Dish: 麻婆豆腐
English: Mapo Tofu
Region hint: Sichuan
Menu context: <only included if is_menu_verified>
```

### JSON parsing + retry

```swift
func generateCard(for dish: Dish) async throws -> Card {
    let prompt = makePrompt(for: dish)
    var attempt = 0
    while attempt < 2 {
        let raw = try await backend.complete(prompt: prompt)
        if let card = try? parseCard(raw) { return card }
        attempt += 1
    }
    throw FoodieAIError.llmSchemaFailure(dish: dish.id, attempts: 2)
}
```

### Fallback chain (card generation)
1. Try selected backend
2. If throws (model not loaded, OOM, schema fail) → try next backend in priority list
3. After 2 backends fail → show "Couldn't generate card. Tap to retry."

---

## 7. UI wireframes

> **Note (2026-07-25 R5)**: The full visual design (colors, typography, layout, mood) is now in [`ui-design-brief.md`](ui-design-brief.md). The wireframes below are kept as a quick ASCII reference; the brief is the source of truth.

### ContentView (root)

```
┌────────────────────────────────────────┐
│  🔍 [Search dishes...]    [⚙️]         │
├────────────────────────────────────────┤
│                                        │
│  📷 Take photo         [BIG BUTTON]    │
│  ➕ Upload photo                      │
│                                        │
│  ── Recent dishes ──                   │
│  麻婆豆腐 (Mapo Tofu)          📖       │
│  宫保鸡丁 (Kung Pao Chicken)  📖       │
│  ...                                  │
│                                        │
└────────────────────────────────────────┘
```

### OCRReviewView (after photo capture)

```
┌────────────────────────────────────────┐
│  ← Back           [Retake]  [Use list] │
├────────────────────────────────────────┤
│  Detected menu lines (3/12 need review)│
│                                        │
│  🟢 Hainanese Chicken Rice             │
│     ✓ matches "海南鸡饭"               │
│                                        │
│  🟡 Bak Chor Mee      (78% confident) │
│     [edit]  no DB match found         │
│                                        │
│  🔴 Chai Tow Kway     (45% confident) │
│     [edit]  no DB match found         │
│                                        │
│  ⚪ $5.50   (price, ignored)          │
│  ⚪ $4.00   (price, ignored)          │
│                                        │
└────────────────────────────────────────┘
```

### DishCardView

```
┌────────────────────────────────────────┐
│  [Photo of dish, or 🌶️ if no photo]  │
│                                        │
│  麻婆豆腐          📖 Wikipedia        │
│  Mapo Tofu                              │
│  má pó dòu fú                           │
│                                        │
│  ─── A Taste ───                        │
│  Silken tofu in fiery chili-bean sauce │
│  with ground pork and numbing Sichuan  │
│  peppercorns. Born in 1860s Chengdu.   │
│                                        │
│  ─── Flavor ───                         │
│  🌶️ Spicy   ████░ 4/5                 │
│  🍋 Sour    ░░░░░ 0/5                 │
│  🧂 Salty   ███░░ 3/5                 │
│  🍯 Sweet   █░░░░ 1/5                 │
│  🥜 Numbing █████ 5/5                 │
│                                        │
│  ─── Pair with ───                      │
│  Steamed rice, jasmine tea             │
│                                        │
│  ─── Region ───                         │
│  Sichuan · main                        │
└────────────────────────────────────────┘
```

### SettingsView

```
┌────────────────────────────────────────┐
│  ← Settings                             │
├────────────────────────────────────────┤
│  LLM backend                            │
│  ○ Apple Foundation Models (default)   │
│  ○ Qwen 2.5 4B (bundled)               │
│  ○ Qwen 2.5 3B (lower thermals)        │
│                                        │
│  About                                  │
│  foodieAI MVP0 · v0.1.0                │
│  126 dishes · 2 menus                  │
└────────────────────────────────────────┘
```

---

## 8. Error handling matrix

| # | Error | When | User message | Retry? | Logged? |
|---|---|---|---|---|---|
| E-001 | `cameraPermissionDenied` | User denied camera | "Camera access is needed. Open Settings to enable." | No (link to Settings) | ✅ |
| E-002 | `photoLibraryPermissionDenied` | User denied photos | "Photo access is needed. Open Settings to enable." | No (link to Settings) | ✅ |
| E-003 | `ocrNoTextFound` | OCR returned empty | "Couldn't read any text. Try a clearer, well-lit photo." | Yes (back to capture) | ✅ |
| E-004 | `ocrLowConfidence` | <50% lines above 0.6 | "Photo might be blurry. Review lines marked in red." | No (user can edit) | ✅ |
| E-005 | `dishNotFound` | Fuzzy match returns <0.5 | "Dish not found. Try a different spelling or check our 100 dishes." | No (link to full list) | ✅ |
| E-006 | `fuzzyNoConfidentMatch` | Top score <0.5 | "No close matches. Did you mean ...? (top 3 shown)" | No (user picks) | ✅ |
| E-007 | `llmModelNotLoaded` | MLX model failed to load | "Couldn't load AI model. Restart the app." | Yes (auto) | ✅ |
| E-008 | `llmSchemaFailure` | LLM returned bad JSON after 2 attempts | "Couldn't generate card. Tap to retry." | Yes (user) | ✅ |
| E-009 | `llmBackendOOM` | Out of memory during inference | "Memory low. Try closing other apps, or switch to 3B in Settings." | No (auto fallback) | ✅ |
| E-010 | `llmTimeout` | Generation >10s | "AI is taking too long. Tap to retry with 3B." | Yes (user) | ✅ |
| E-011 | `photoLoadFailed` | Picked photo can't be decoded | "Couldn't open this photo. Try another." | Yes (back to picker) | ✅ |
| E-012 | `dbCorrupted` | dishes.jsonl parse error | "Database error. Please reinstall the app." | No | ✅ |
| E-013 | `networkUnavailable` | (not in MVP0) | — | — | — |
| E-014 | `appleIntelligenceUnavailable` | iOS 26 FM not on device | "Apple Intelligence unavailable. Using Qwen 4B." | No (auto fallback) | ✅ |
| E-015 | `pinyinMissing` | Dish has no pinyin in lookup | "Search index incomplete for this dish." | No (skip in results) | ✅ |
| E-016 | `photoMissing` | photo_path empty | (UI uses emoji fallback, no error) | No | — |
| E-017 | `cardParseFailed` | LLM JSON parses but fields wrong types | "AI returned an invalid card. Tap to retry." | Yes (user) | ✅ |
| E-018 | `ocrRevisionUnsupported` | Older iOS without `.revision2` | "OCR requires iOS 18+. Please update." | No | ✅ |
| E-019 | `diskFull` | Can't write to local cache | "Storage full. Free up space and retry." | Yes (user) | ✅ |
| E-020 | `unknown` | Catch-all | "Something went wrong. Please try again." | Yes (user) | ✅ |

### Error display rules
- All errors show in `ErrorBanner` (top-of-screen toast, 3s auto-dismiss for warnings, manual dismiss for blocking errors)
- Blocking errors (E-001, E-002, E-007, E-012, E-018) use full-screen modal
- All errors logged to console via `os.log` (no on-device log viewer in MVP0)

---

## 9. Step-by-step build order

Total: ~7-10 days of focused work.

> **Note 2026-07-27 (R10):** Day-numbering in this section originally assumed
> Day 1 = data build (see `mvp0-data-results.md`), Day 2 = polish,
> Day 3 = Xcode skeleton. We collapsed the schedule and made it through
> data + skeleton + search + LLM glue by Day 3 of practice. The actual
> mapping is:
>
> | Plan day | What it describes | Our actual day | Status |
> |---|---|---|---|
> | Day 3 | Project skeleton | Our Day 1 | ✅ commit `fbe45aa` |
> | Day 4 | Search + index | Our Day 2 | ✅ commit `f35200c` |
> | Day 5 | LLM + cards | Our Day 3 | ✅ commit `559a200` |
> | Day 6 | OCR pipeline | Our Day 5 | ⏳ |
> | Day 7 | Polish + error handling | Our Day 7 | ⏳ |
>
> The list below preserves the original numbering because feedback-log R6/D-010
> and downstream docs reference these labels. Read with the table above.

### Day 1-2: Data foundation
- [ ] Manually transcribe 2 menus into `data/menus/menu-*.json` (50 dishes each)
- [ ] Hand-write 30 cards from real sources (Wikipedia/百度百科) — 15 EN, 15 ZH
- [ ] Use Qwen 3.5 cloud batch to generate 70 LLM-only cards → review each for sanity
- [ ] Build `data/dishes/dishes.jsonl` (100 entries)
- [ ] Download 40-50 photos from Wikimedia Commons (rest get emoji fallback)
- [ ] Build `data/synonyms.json` (~30 entries)

### Day 3: Project skeleton
- [ ] Create Xcode project, set deployment target iOS 18
- [ ] Add MLX-Swift via Swift Package Manager
- [ ] Bundle Qwen 2.5 3B + 4B 4-bit models (download from mlx-community)
- [ ] Bundle `dishes.jsonl`, `synonyms.json`, photos as resources
- [ ] Write Codable models (Dish, FlavorProfile, CardSource, LLMBackend)
- [ ] Write `DishRepository` (load + parse + validate 100 dishes on launch)

### Day 4: Search + index
- [ ] Write `PinyinConverter` (hand-rolled table for 100 dishes)
- [ ] Write `SynonymMap`
- [ ] Write `FuzzyIndex` (Levenshtein + substring + pinyin scoring)
- [ ] Write 20+ unit tests for `FuzzyIndex` ("spicy tofy" → 麻婆豆腐, etc.)
- [ ] Wire search box to `ContentView` → live filter results

### Day 5: LLM + cards
- [ ] Write `LLMService` protocol + `MLXQwenBackend` (load model, complete prompt, stream tokens)
- [ ] Write `AppleIntelligenceBackend` (with availability check)
- [ ] Write `CardGenerator` (prompt + parse + 1-retry)
- [ ] Write 10+ unit tests for prompt → JSON parsing
- [ ] Wire `DishCardView` to show generated card

### Day 6: OCR pipeline
- [ ] Write `OCRService` (Vision wrapper, returns per-line confidence)
- [ ] Write `OCRLine` (text, confidence, bbox, isPrice)
- [ ] Write price-detection heuristic
- [ ] Write `OCRReviewView` (per-line UI with edit-in-place)
- [ ] Wire camera + photo library to `ContentView`

### Day 7: Polish + error handling
- [ ] Write `FoodieAIError` enum (all 20 cases)
- [ ] Write `ErrorMessages` (all 20 user-facing strings)
- [ ] Write `ErrorBanner` component
- [ ] Wire all 20 errors throughout the app
- [ ] Write `SettingsView` (LLM picker, about)
- [ ] Add app icon, launch screen, info.plist usage strings

### Day 8-9: Test on device
- [ ] Deploy to iPhone 17 Pro Max
- [ ] Test all 3 LLMs on 20 dishes, record latency + JSON validity
- [ ] Test OCR on 10 photos of the 2 menus, record confidence + match rate
- [ ] Test all 20 error cases (deny permissions, kill app mid-load, etc.)
- [ ] Fix the top 3 issues found

### Day 10: MVP0 sign-off
- [ ] Verify all pass criteria met
- [ ] Write `doc/mvp0-results.md` (what worked, what broke, MVP1 changes needed)
- [ ] Lock MVP1 scope

---

## 10. MVP0 pass criteria

MVP0 is "done" when **all** of the following are true:

1. **All 100 dishes** have a card that displays correctly (photo or emoji, intro, flavor, pair_with, region, source tag)
2. **Search** returns the right top-1 dish for ≥18/20 test queries, including:
   - Exact EN ("Mapo Tofu")
   - Exact ZH ("麻婆豆腐")
   - Transliteration ("ma po doufu")
   - Typo EN ("spicy tofy")
   - Synonym ("tofu" → "doufu")
3. **OCR** correctly recognizes ≥85% of dish lines on both menus (passing the benchmark from `ocr-benchmark-plan.md`)
4. **All 3 LLMs** produce valid JSON for ≥90% of dishes (test on 20 dishes × 3 backends = 60 runs)
5. **All 20 error cases** trigger their correct UI behavior
6. **No crashes** during a 30-minute walkthrough session
7. **Settings switcher** works at runtime (3B → 4B → Apple Intelligence, no restart)
8. **App launches to search-ready state in <5s** (cold start with model loaded)

---

## 11. What MVP0 will tell us (decision inputs for MVP1)

| Question MVP0 answers | How |
|---|---|
| Does Vision OCR work well enough on real menus? | Benchmark pass rate |
| Is Qwen 4B noticeably better than 3B for cards? | Side-by-side comparison in 60 test runs |
| Is Apple Intelligence usable as a fallback? | Latency + JSON validity on 20 test dishes |
| How long does a real card generation take end-to-end? | Stopwatch on 20 test dishes × 3 backends |
| Is the fuzzy search algorithm accurate enough? | 20 query test set pass rate |
| Does the ChatGPT-style UI work for the dish list use case? | Walkthrough session feedback |
| Are 100 dishes enough, or do users want more? | Walkthrough feedback |
| Is the source-tag UX honest/useful? | Walkthrough feedback |

---

## 12. Risks for MVP0

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| MLX-Swift setup pain on first build | Medium | High | Budget Day 3 entirely for toolchain + spike |
| Qwen 2.5 4-bit MLX weights unavailable | Low | High | Fallback: Qwen 2.5 3B + Apple Intelligence |
| Vision OCR fails benchmark (<85% lines) | Medium | Critical | Pre-process: contrast + binarize; accept lower pass threshold for MVP0 |
| Fuzzy search returns wrong dish | Medium | Medium | 20 test queries cover edge cases; iterate on scoring |
| LLM JSON parse fails often | Medium | High | Tighten prompt, 1-retry handles most cases |
| iOS 18 deployment target lacks Apple Intelligence | High | Low | Apple Intelligence is "nice to have", not required |
| Photo library permission UX confusion | Low | Low | Standard iOS permission copy |
| App Store review for permission strings | N/A | N/A | MVP0 is TestFlight, not App Store |

---

## 13. Open items for MVP0

- [ ] Jacky: send URLs/photos of the 2 menus (or I scrape them)
- [ ] Jacky: confirm which 30 dishes to hand-author vs which 70 to LLM-generate
- [ ] Jacky: provide Apple Developer account for TestFlight deployment
- [ ] Me: write `doc/data-sourcing.md` (card authoring rules: voice, length, what to include in intro)
- [ ] Me: draft the 20 fuzzy-search test queries

---

## 14. Sign-off

This plan is locked once you ack the following:
- [x] Scope: 2 menus, 100 dishes, iOS 18 deployment, MVP0 in 7-10 days
- [x] Stack: SwiftUI + MLX-Swift + Apple Vision
- [x] LLMs: Qwen 4B + 3B + Apple Intelligence (runtime picker)
- [x] UX: per-line OCR confidence + edit-before-confirm
- [x] Source tags on all cards (📖📷🤖)
- [x] Error handling: 20 typed cases, console logging only
- [x] Pass criteria: 8 checks above

Next deliverable: `doc/data-sourcing.md` (card authoring rules), then start Day 1.



## 15. D-001 to D-027 cheat sheet:
ID	Round	Decision (one line)
D-001	1	MVP1 search is fuzzy, not exact
D-002	1	MVP1 has 200 dishes (100 ZH + 100 EN)
D-003	1	No exact-match mode in MVP1
D-004	1	MVP1 has no RAG (remove bge-small, ragDB, embed_rag.py)
D-005	2	MVP1 LLM is Qwen 2.5 4B (bumped from 3B)
D-006	2	MVP1 OCR is Apple Vision, no custom CoreML OCR
D-007	2	Run real-menu OCR benchmark before MVP1 coding
D-008	3	Build MVP0 spike before MVP1
D-009	3	MVP0 = 2 menus × ~50 dishes = ~100 total
D-010	3	MVP0 = iOS native, iOS 18 deployment target
D-011	3	MVP0 LLMs = Qwen 4B + 3B + Apple Intelligence, runtime picker
D-012	3	MVP0 OCR UX = per-line confidence + edit-before-confirm
D-013	3	Card source tags on ALL cards (📖📷🤖❓)
D-014	3	100 cards AI-authored from menus
D-015	3	20 typed error cases, console logging only
D-016	3	Schema enforcement: 1 retry on bad JSON, then error
D-017	3	data-sourcing.md shipped (card authoring rules)
D-018	3	20 fuzzy-search test queries shipped
D-019	3	dishes.jsonl skeleton with 10 dishes
D-020	4	Noodle Gourmet is Menu A, 86 dishes
D-021	4	Zhang Gui is Menu B, 40 visible dishes
D-022	4	A3 cover PDF is decorative only, ignored
D-023	4	Beijing→SG scope deviation accepted (cuisine is what matters)
D-024	4	menu-a-noodle-gourmet.json shipped
D-025	4	menu-b-zhang-gui.json shipped
D-026	4	dishes.jsonl shipped with 126 validated cards
D-027	4	mvp0-data-results.md shipped (validation + recommendations)
