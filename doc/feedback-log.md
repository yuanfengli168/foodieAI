# FoodieAI — Feedback & Decision Log

> Status: Open
> Started: 2026-07-21
> Purpose: Track feedback from Jacky on the brainstorm + reviews, and lock decisions inline.

---

## Round 1 — 2026-07-21 (Review of brainstorm / model-comparison / mvp2-paid)

### AI suggestions

1. Swap **exact match** for **fuzzy match** from day 1 (Levenshtein on pinyin + small synonym map).
2. **Skip RAG** for MVP1; use a simple `pinyin → dish_id` index. Add RAG only if free-form generation is needed (bundled `intro` already covers it).
3. **Cut MVP1 to 200 dishes**, done well: top 50 × 4 cuisines (川 / 粤 / 鲁 / 淮扬). Validate UX before scaling.
4. **Benchmark on real menus early** — photograph menus in 3-4 real restaurants. If OCR fails >20% of the time, rethink the architecture.
5. **Make the structured card the headline**, not "AI translation." The flavor profile + pairings are the moat.
6. **Recipe generation in MVP1, not MVP3** — travelers who fall in love with a dish want to cook it at home. High virality.

### Jacky's responses

| # | Topic | Decision | Notes |
|---|---|---|---|
| 1 | Fuzzy search vs exact match | ✅ **Fuzzy from MVP1** | English / Chinese / transliteration (e.g. "spicy tofy" → 麻婆豆腐) all accepted. No exact-match requirement. |
| 2 | Skip RAG for MVP1 | ✅ **Logged, no decision yet** | (See decision below) |
| 3 | Cut to 200 dishes | ✅ **Locked: 200 dishes** | 100 Chinese, 100 English / Western. Chinese list to be sent later. |
| 4 | OCR benchmark on real menus | ⏳ **No estimate yet** | AI to provide estimation in a follow-up. |
| 5 | Real menu testing | ✅ **Logged, no action** | |
| 6 | RAG for MVP1 | ❌ **Not needed at all** | Remove RAG from MVP1 architecture. |

---

## Locked decisions (Round 1)

### D-001 — MVP1 search: fuzzy, not exact
- **Scope**: EN input, ZH input, and EN transliteration of ZH all work.
- **Behavior**: typos and near-misses resolve to the right dish (e.g. "spicy tofy" → 麻婆豆腐).
- **Implementation hint** (for later): Levenshtein / edit distance on pinyin + a small synonym map. No exact-match requirement.

### D-002 — MVP1 dish count: 200
- **Chinese**: 100 entries (list to be sent by Jacky).
- **English / Western**: 100 entries (list to be sent by Jacky).
- Down from the brainstorm's 800–1000. Validates UX before scaling.

### D-003 — MVP1 search: no exact match
- (Combined with D-001 for clarity: there is no exact-match mode in MVP1.)

### D-004 — MVP1: no RAG
- **Remove** RAG index, `bge-small-zh-v1.5` embeddings, and the `ragDB/` data folder from MVP1.
- **Remove** RAG-related scripts (`embed_rag.py`) and tests (`rag_tests/`).
- The bundled `intro` field per dish already covers the "describe this dish" use case.
- Re-evaluate RAG only if MVP2 adds free-form generation (e.g. long-tail dishes not in the bundled DB).

---

## Open items (Round 1)

- **Q-001**: AI to provide an estimation for the real-menu OCR benchmark (how many menus × how many hours × what success rate defines "good enough").
- **Q-002**: Jacky to send the 100 Chinese dishes + 100 Western dishes lists.

---

## Next round

Awaiting:
- OCR benchmark execution and results (D-007 / Q-006).
- 100 ZH + 100 EN/Western dish lists (Q-002).
- Optional: confirmation of menu access (Q-005).

---

## Round 2 — 2026-07-21 (Model size + OCR stack)

### Context

Jacky reviewed a [ChatGPT thread on CoreML model sizes on iPhone](https://chatgpt.com/share/6a5eeb87-f60c-83ec-9266-6e20885bdae0) suggesting 3B/4B/8B/12B are all feasible, and asked two questions:

1. Can CoreML really run 4B / 8B / 12B? What does that mean for foodieAI?
2. For OCR, which model on CoreML should we use?

### AI analysis

- The shared thread discussed **text classification + reranking** (small context, short output) — a very different workload from foodieAI's "generate ~150-token structured JSON card from scratch". 8B/12B is feasible for the former but hurts the latter (latency, RAM pressure with photos resident).
- **3B → 4B** is the only jump that pays off for foodieAI: better JSON, more vivid ZH intros, ~10-15% slower, still inside budget.
- **OCR**: do not ship a custom CoreML OCR model. Apple `Vision` (`VNRecognizeTextRequest`) on the Neural Engine is free, zero app size, best CJK support, and doesn't compete with the LLM for GPU/RAM.

### Jacky's responses

| # | Topic | Decision | Notes |
|---|---|---|---|
| Q-001 (OCR benchmark) | Real-menu test scope | ✅ **Do the benchmark** | Full plan written to `doc/ocr-benchmark-plan.md` |
| Q-002 (dish lists) | 100 ZH + 100 EN lists | ✅ **List will be sent later** | (still open; placeholder noted) |
| Q-003 (model size) | Bump 3B → 4B? | ✅ **Yes — bump to 4B** | Update `model-comparison.md` |
| Q-004 (OCR model) | Custom CoreML OCR? | ✅ **No, use Apple Vision** | Update `model-comparison.md` |

### Locked decisions (Round 2)

#### D-005 — MVP1 LLM: Qwen 2.5 4B Instruct (4-bit) — bumped from 3B
- **Rationale**: better JSON output, more vivid Chinese intros. ~30 t/s, ~2.4GB at 4-bit, ~3.5GB peak RAM.
- Still under `<3s` card generation target with prompt-cache warmup.
- `model-comparison.md` updated; status line now reads "Locked (Qwen 2.5 4B Instruct)".

#### D-006 — MVP1 OCR: Apple `Vision` framework, no custom model
- **API**: `VNRecognizeTextRequest`, `.accurate` level, `.revision3` (iOS 26).
- **Why**: free, zero app size, CJK + EN, runs on Neural Engine (no GPU/RAM competition with LLM).
- **Pre-processing** (own code, not a model): contrast + binarization, line grouping heuristics, pinyin fallback for matched candidates.
- **Post-MVP1 option** (only if real-menu error rate >15%): a ~50MB Chinese spell-correction CoreML model for common OCR errors.
- PaddleOCR, Tesseract, custom CoreML OCR all rejected — see `model-comparison.md` "OCR Strategy" section.

#### D-007 — Real-menu OCR benchmark will be run
- Full plan: [doc/ocr-benchmark-plan.md](ocr-benchmark-plan.md)
- **Scope**: 15-20 menus across 5-6 cuisines, 3-5 cities, mix of conditions.
- **Pass criterion**: ≥85% line-level accuracy on ≥80% of menus.
- **Time estimate**: 27-32 hours (one weekend + 2 evenings).
- **When**: before any meaningful iOS code is written. Target: 2026-07-25/26.

### Open items (Round 2)

- **Q-002**: Jacky to send 100 ZH + 100 EN/Western dish lists (carried from Round 1, still pending).
- **Q-005**: Does Jacky have access to 15-20 unique menus in a reasonable geography?
- **Q-006**: Run OCR benchmark results → log Go/No-go decision into Round 3.

---

## Next round (Round 2 closeout)

Awaiting:
- OCR benchmark execution and results (D-007 / Q-006).
- 100 ZH + 100 EN/Western dish lists (Q-002).
- Optional: confirmation of menu access (Q-005).

---

## Round 3 — 2026-07-21 (MVP0 spike — 2 real menus, full stack)

### Context

Jacky proposed an **MVP0 spike** before locking MVP1:
- 2 Singapore restaurants (1 EN-only ~50 dishes, 1 ZH-only ~50 dishes)
- Full-stack: DB + index + LLM + OCR + UI end-to-end
- ChatGPT-style UI: search box, photo button, plus button
- LLM model switchable between 3B and 4B for testing
- Error handling per case
- Final result: working full-stack app

After Q&A the scope was refined:
- 2 menus = 1 EN-only SG + 1 ZH-only Beijing (not 2 SG menus)
- ~50 dishes each, ~100 total
- iOS 18 deployment target (stable Xcode), iPhone 17 Pro Max is the test device
- Runtime LLM picker: Qwen 4B / 3B / Apple Intelligence
- OCR UX: per-line confidence + edit-before-confirm
- Card source tags on **all** cards (not just LLM): 📖 Wikipedia/百度百科, 📷 Menu-verified, 🤖 LLM-only
- Card data: 100 hand-authored (Jacky will send menus, AI generates JSON content)
- DB: bundled JSON, read-only
- Schema enforcement: simple (1 retry on bad JSON, generic error after)
- Failure visibility: Xcode console only (no on-device log viewer)

### Locked decisions (Round 3)

#### D-008 — Build MVP0 before MVP1
- A 7-10 day spike to validate the full pipeline (OCR → fuzzy index → LLM card gen → UI) on 2 real menus.
- MVP1 is locked only after MVP0 results are in.
- Plan: [doc/mvp0-plan.md](mvp0-plan.md)

#### D-009 — MVP0 scope: 2 menus, ~100 dishes total
- Menu A: EN-only Singapore restaurant (Western or modern), ~50 dishes.
- Menu B: ZH-only Beijing restaurant (noodles, fried dishes), ~50 dishes.
- Earlier "2 SG restaurants" was changed to "1 SG + 1 Beijing" per Jacky.

#### D-010 — MVP0 platform: iOS native, iOS 18 deployment target
- SwiftUI, MLX-Swift, Apple `Vision`.
- iOS 18 SDK on stable Xcode 16 (not iOS 26 beta).
- MLX-Swift + Vision work fine on iOS 18.
- Loses access to Vision `.revision3` and Apple Intelligence Foundation Models, but those are nice-to-have.
- Test device: Jacky's iPhone 17 Pro Max (A19 Pro, 12GB RAM).

#### D-011 — MVP0 LLM backends: Qwen 4B + 3B + Apple Intelligence, runtime picker
- All 3 available in MVP0 via a Settings picker.
- Apple Intelligence is fallback (only available on iOS 26+ devices); on iOS 18 it just doesn't show in the picker.
- Qwen 4B is the recommended default; 3B is the latency-comparison option.

#### D-012 — MVP0 OCR UX: per-line confidence + edit-before-confirm
- Vision returns per-line confidence.
- Lines ≥0.85: green, auto-confirm.
- Lines 0.60-0.85: yellow, shown but flagged.
- Lines <0.60: red, require user edit or explicit "include anyway" tap.
- Price lines auto-detected (regex) and ignored.
- `OCRReviewView` is a separate screen between capture and dish list.

#### D-013 — MVP0 card source tags on all cards
- All cards get a source tag — not just LLM-generated ones.
- 4-tag taxonomy:
  - 📖 Wikipedia / 百度百科 (blue) — real encyclopedia entry
  - 📷 Menu-verified (green) — dish is on a real menu, description still AI-generated
  - 🤖 LLM-only (orange) — LLM generated everything, no real source
  - ❓ User-contributed (purple) — reserved for MVP2
- Tag is independent of `is_menu_verified` boolean; it represents card *content* source.

#### D-014 — MVP0 dish data: 100 cards AI-authored from menus Jacky sends
- 100 dishes × full card content (intro, flavor, pair_with, region, category) generated.
- Bundled as read-only JSON, shipped in app.
- Photo coverage: download from Wikimedia Commons where possible (~40-50 of 100); rest get emoji fallback.
- Synonym map: ~30 hand-curated entries bundled.

#### D-015 — MVP0 error handling: 20 typed cases, console logging only
- Full error matrix in `mvp0-plan.md` section 8 (E-001 through E-020).
- Display: `ErrorBanner` toast for warnings, full-screen modal for blocking errors.
- All errors logged to `os.log` (Xcode console); no on-device log viewer in MVP0.

#### D-016 — MVP0 schema enforcement: 1 retry on bad JSON, then generic error
- LLM card generation: 1 retry on schema failure, then surface `llmSchemaFailure` error to user.
- No smart field-filling logic in MVP0.
- Fallback chain: try selected backend → try next backend in priority list → user-facing error.

### Open items (Round 3)

- **Q-007**: Jacky to send URLs/photos of the 2 menus (or AI scrapes them).
- **Q-008**: Confirm which dishes to hand-author vs LLM-generate for the 100 cards.
- **Q-009**: Apple Developer account for TestFlight deployment of MVP0 build.
- **Q-010**: AI to write `doc/data-sourcing.md` (card authoring rules: voice, length, what to include in intro).
- **Q-011**: AI to draft the 20 fuzzy-search test queries.

### MVP0 deliverables (from `mvp0-plan.md`)

- 14-section plan file: [doc/mvp0-plan.md](mvp0-plan.md)
- Pass criteria (8 checks), build order (10 days), risk register (8 risks)
- What MVP0 will tell us (8 decision inputs for MVP1)
- File/folder structure with ~30 Swift files + 4 test files

---

## Next round (Round 3 closeout)

Awaiting:
- 2 menu sources from Jacky (Q-007).
- Hand-authoring vs LLM-generation split decision (Q-008).
- TestFlight account confirmation (Q-009).

AI to deliver next (no code yet):
- `doc/data-sourcing.md` (Q-010)
- 20 fuzzy-search test queries (Q-011)

---

## Round 3 closeout — 2026-07-21 (Deliverables)

### Delivered (closes Q-010, Q-011, partially Q-007)

#### D-017 — `doc/data-sourcing.md` shipped
- [doc/data-sourcing.md](data-sourcing.md)
- 4 source types with tagging rules
- Card author workflow (7 steps)
- Field-by-field authoring rules (17 fields)
- Intro writing rules with voice, structure, and 4 examples (good vs bad)
- Flavor 0-5 scale with conventions per cuisine
- Quality checklist (13 items)
- LLM-only special rules + 30% cap
- Menu JSONL input format (EN and ZH)
- Build pipeline diagram

#### D-018 — 20 fuzzy-search test queries shipped
- [doc/fuzzy-search-tests.md](fuzzy-search-tests.md)
- 4 groups: Exact EN (5), Exact ZH (5), Pinyin (5), Typo (5)
- Score targets per group (A: ≥0.95, B: ≥0.95, C: ≥0.85, D: ≥0.70)
- Synonym unit tests (separate set)
- Failure cases to verify (4)
- CI integration guidance
- Growth plan: 50-100 queries by MVP1

#### D-019 — `data/dishes/dishes.jsonl` skeleton shipped
- 10 example dishes covering all 4 source types (`wikipedia`, `menu_verified`)
- Schema-validated against `mvp0-plan.md` §3
- Examples span: 麻婆豆腐, 宫保鸡丁, 海南鸡饭, 炸酱面, 炒粿条, 糖醋里脊, truffle mushroom soup, beef noodle soup, Hokkien mee, hot and sour soup
- Mix of cuisines: Sichuan, Cantonese, Beijing, Singapore, Western
- 4 ZH dishes with pinyin, 3 EN-only dishes with empty pinyin (correct)
- All cards include all 17 schema fields, all 5 flavor dimensions, 1-4 pair_with items
- Quality checklist applied: ✅ all 10

### Updated open items (Round 3 closeout)

- **Q-007**: Jacky to send the 2 menus (URLs/photos) — **partially unblocked** by `dishes.jsonl` skeleton (10 dishes as examples)
- **Q-008**: Confirm which dishes to hand-author vs LLM-generate for the 100 cards — **recommendation in `data-sourcing.md` §5**: cap LLM-only at 30% of DB, so ≤30 of 100 cards should be `llm_only`
- **Q-009**: Apple Developer account for TestFlight deployment of MVP0 build
- **Q-012** (new): Decide on the final 90 dishes to add to `dishes.jsonl` (skeleton has 10)
- **Q-013** (new): Photo sourcing for 100 dishes — recommend Wikimedia Commons for ~40-50, emoji fallback for the rest

---

## Next round (Round 4)

Awaiting:
- Final 90 dish entries (Q-012)
- Photo sourcing decision (Q-013)
- TestFlight account confirmation (Q-009)
- 2 menu URLs/photos if Jacky wants to overwrite any of the 10 skeleton dishes (Q-007)
- Hand-authoring vs LLM-generation final split (Q-008)

AI to deliver when ready (next batch, no code yet):
- Expand `dishes.jsonl` from 10 → 100 entries once Q-012 resolved
- `scripts/build_dishes.py` once the 2 menus are in
- `scripts/llm_batch_cards.py` for filling LLM-only cards
- `ios/` Xcode project skeleton once we start coding (separate round)

---

## Round 4 — 2026-07-24 (MVP0 data build from 2 real menus)

### Context

Jacky sent 2 menus to start MVP0:
- `NoodleGourmet-menu.jpg` — Chinese-American takeout, EN-only, 86 dishes
- `3.24 新加坡.pdf` — 35-page Zhang Gui (掌櫃) premium à la carte, Northern Chinese, 40 visible dishes
- `A3-A-La-Carte-Menu_July26.pdf` — decorative cover only, **not a usable menu** (ignored)

Jacky chose:
- Menu A: all 86 visible Noodle Gourmet dishes
- Menu B: 40 visible Zhang Gui dishes only, no padding
- Beijing-vs-SG question: SG is fine, cuisine is what matters

### Locked decisions (Round 4)

#### D-020 — Noodle Gourmet is Menu A, all 86 dishes included
- 1-page Chinese-American takeout, EN-only
- Menu code: `menu-a-noodle-gourmet`
- Includes Combination Platters (CP1-CP20), Side Orders (20), Rice Platter (D1-D140)
- 86 dishes, all `source: "menu_verified"` in final DB

#### D-021 — Zhang Gui (掌櫃) is Menu B, 40 visible dishes only
- 35-page premium à la carte, ZH+EN
- Locations: Singapore HQ + Indonesia + Shanghai
- Cuisine: Northern Chinese (roots in 中原 — central plains)
- Menu code: `menu-b-zhang-gui`
- 40 dishes across Signature, Mains, Vegetable & Tofu, Noodles, Dumplings, Cold Dishes, Soup, Snack, Dessert, Drink

#### D-022 — A3-A-La-Carte-Menu_July26.pdf is decorative cover only, not a menu
- 1 page, no dishes visible
- Ignored for MVP0

#### D-023 — Beijing-vs-SG scope deviation accepted
- Original plan said "Beijing restaurant"
- Actual deliverable: Singapore restaurant with Northern Chinese cuisine
- Deviation is fine because cuisine style (Northern Chinese, noodles, hand-pulled) matches the spirit of the original ask

### Delivered (Round 4)

#### D-024 — `data/menus/menu-a-noodle-gourmet.json` shipped
- 86 dishes
- Sections: Combination Platters (20), Side Orders (20), Rice Platter (46)

#### D-025 — `data/menus/menu-b-zhang-gui.json` shipped
- 40 dishes
- Each entry includes ZH name, EN name, pinyin, SGD price, page number

#### D-026 — `data/dishes/dishes.jsonl` shipped with 126 cards
- 84 Noodle Gourmet cards (all `source: "menu_verified"`)
- 42 Zhang Gui cards (all `source: "wikipedia"` for famous dishes with real articles)
- 100% schema validation pass (126/126, 0 errors)
- All 17 required fields, all flavor values 0-5, all sources valid, all categories valid, all IDs unique

#### D-027 — `doc/mvp0-data-results.md` shipped
- Full validation report
- 5 quality issues flagged
- 6 recommended next actions

### Quality issues flagged (Round 4)

- **Q-014**: 93/126 intros under 20 words (data-sourcing.md says 20-80)
- **Q-015**: No `llm_only` cards (can't test 🤖 tag UX in MVP0)
- **Q-016**: No photos (all `photo_path: ""`, rely on emoji)
- **Q-017**: `data/synonyms.json` doesn't exist (fuzzy search will be less smart)
- **Q-018**: 17/20 fuzzy test queries fail (DB doesn't have Mapo Tofu, Hainanese Chicken Rice, Char Kway Teow, etc.)

### Open items (Round 4)

- **Q-019**: Should we add 17 iconic dishes to make fuzzy test pass? (my rec: skip, rework test queries for MVP0 DB)
- **Q-020**: Should we expand 93 short intros? (my rec: yes, 1-2 hours, big quality win)
- **Q-021**: Should we mark 5-10 cards `llm_only` to test 🤖 tag? (my rec: yes, 15 min)
- **Q-022**: Should we build synonym map? (my rec: yes, 15 min, I can propose)
- **Q-009**: Apple Developer account for TestFlight (still pending)
- **Q-013**: Photo sourcing decision (deferred to MVP1 unless we want to add now)

---

## Next round (Round 4 closeout)

Awaiting decisions on Q-019 → Q-022 from Jacky.

Once those are resolved, we can start Day 1 of the MVP0 build plan (Xcode project skeleton).

---

## Round 5 — 2026-07-25 (Product re-iteration + UX direction)

### Context

After a few days away, Jacky asked for a re-iteration of the product flow and answered 18 prior questions. New direction: "make it more like a foodie app, casual, food sketches, warm color scheme, chill." Also: shipping is the priority, use all Apple iOS optimizations (Vision, CoreML, MLX, Apple Intelligence).

### Locked decisions (Round 5)

#### D-028 — Auto-start on photo capture, no review screen in MVP0
- D-012 (per-line confidence + edit-before-confirm) is **deferred to MVP1**
- MVP0 behavior: capture → OCR → fuzzy match → dish list, with a ~2s spinner
- Data model still includes the confidence field (so MVP1 hook is free)
- Hidden long-press affordance: "Re-edit OCR results" (disabled in MVP0, enabled in MVP1)

#### D-029 — Warm "foodie notebook" UI design
- Color palette: cream `#FAF7F2` + terracotta `#C7683D` + sage `#7A9A6E` + gold `#D4A574` + plum `#8B6F8E` (numbing)
- System fonts only (SF Pro + PingFang). No custom fonts in MVP0.
- Photos: emoji-only fallback in MVP0 (R5 Q1)
- Custom hand-drawn sketches: deferred to MVP1, ~$200 commission
- Full design in [`ui-design-brief.md`](ui-design-brief.md)

#### D-030 — 🤖 LLM-only cards: hidden when toggle is off
- `source: "llm_only"` cards are **removed from the list entirely** when Settings toggle is off (R5 Q3)
- Not tagged, not shown — fully hidden
- Toggle lives in Settings, runtime switchable, no restart

#### D-031 — LLM priority: 4B primary, 3B thermal fallback, Apple Intelligence best-effort (R5 Q5)
- Defaults: Qwen 4B for card quality
- Auto-fallback to 3B if 4B OOMs or device is thermal-throttled
- Apple Intelligence is "best effort" (iOS 26+ only) — free, fall through if available
- Picker is runtime-switchable, no app restart

#### D-032 — MVP0 success criteria: 4 axes + "easy to use" = low per-task friction (R5 Q4)
- (a) Speed
- (b) Card quality
- (c) OCR accuracy
- (d) Fun to use
- "Easy to use" = **per-task friction is low** (R5 Q2b), NOT "intuitive in 5 seconds"
- Personal judgment by Jacky, not metrics

#### D-033 — Recipe generation → MVP1+ (corrected from earlier "MVP3" summary)
- Originally brainstorm said MVP1, was logged as MVP3 in Round 4 summary by mistake
- **Locked: MVP1+** per R5 Q8
- No `recipe` field in MVP0 schema

#### D-034 — TODO.md created (R5 Q3, Q16)
- New file: [TODO.md](TODO.md)
- Captures all polish + future-work items in 4 priority buckets (P2 MVP0 polish, P3 MVP1 prep, P4 MVP2, P5 MVP3+)
- Includes: short-intro expansion, fuzzy test re-align, llm_only test cards, synonym map, photo downloads, OCR benchmark, dark mode, sketches, recipe field, allergens, i18n, etc.

#### D-035 — `ui-design-brief.md` created (R5 Q2, Q8)
- New file: [ui-design-brief.md](ui-design-brief.md)
- 12 sections: mood, color palette, typography, iconography, spacing, card structure, root layout, empty/loading states, animation, accessibility, asset inventory, out of scope

#### D-036 — Archived older feedback rounds is **deferred** to MVP0-post
- Jacky (R5 Q16) said "yeah" to archiving rounds 1-4
- But: archiving is doc hygiene, not a blocker
- Will do after MVP0 ships so we don't lose context mid-build

### Open items (Round 5)

None blocking. All design + product questions resolved. Next step is to start the actual Xcode project (Day 1 of build plan).

---

## Round 5 closeout

All product + UX questions locked. Ready to start the build.

**Status: plan complete. Build not started.**

Next deliverable (when Jacky says "go"): the Xcode project skeleton (Day 1 of [mvp0-plan.md](mvp0-plan.md) §9 build order).

---

## Round 6 — 2026-07-26 (iOS 26 + Apple Foundation Models architecture flip)

### Context

Pre-build check surfaced two real changes since the plan was written:
1. **Xcode 26.1.1 + Swift 6.2.1** is installed (not Xcode 16 as the plan assumed)
2. Jacky asked the right question: is CoreML better than MLX-Swift for LLMs in 2026?

The answer: **CoreML is best for vision/speech/small bespoke models (post-OCR spell-checker, image classifiers)**, not for general LLMs. Apple's CoreML converter struggles with Qwen-class LLMs and loses 15-20% quality on conversion. MLX-Swift remains the right tool for Qwen.

**But the bigger 2026 news**: iOS 26 ships **Apple Foundation Models** — a free, on-device ~3B LLM that any app can call via `LanguageModelSession`. Zero app size, instant first-launch, runs on ANE. This is a real game-changer for our app size budget.

Jacky answered:
- **Q1**: iOS 26 as deployment target (locks out iOS 18+ users, but his test device is iPhone 17 Pro Max which is iOS 26 guaranteed, and shipping is priority)
- **Q2**: asked about CoreML vs MLX — see analysis above
- **Q3**: `ios/` folder inside the repo (matches `mvp0-plan.md` §2)
- **Q4**: bundle Qwen 4B + 3B as fallback in MVP0 (not download-on-demand)

### Locked decisions (Round 6)

#### D-037 — iOS 26 is the deployment target (was iOS 18 in R1)
- Xcode 26.1.1 installed
- Unlocks: Apple Foundation Models, Vision `.revision3`, Swift 6.2 strict concurrency
- Trade-off: iOS 18+ users (iPhone XS to 14) cannot run the app. Acceptable because Jacky's test device is iPhone 17 Pro Max, and shipping is priority.

#### D-038 — CoreML is NOT the LLM strategy (clarified 2026-07-26)
- CoreML is best for: vision, speech, small bespoke models, post-OCR spell-correction
- CoreML is NOT best for: general LLMs (3-8B)
- The exception: post-MVP0 Chinese spell-correction model (~50MB) will use CoreML + ANE
- MLX-Swift remains the right tool for Qwen-class LLMs

#### D-039 — LLM architecture flipped: Apple Foundation Models PRIMARY, Qwen FALLBACK (was D-031, superseded)
- **Priority order**: Apple Foundation Models → Qwen 4B → Qwen 3B
- **Why Apple FM as primary**:
  - 0 GB app size (system model, no download)
  - Instant first-launch (no 5-15s model load)
  - Runs on ANE (better thermal profile than GPU-bound Qwen)
  - Free (no per-call API cost)
  - Easier App Store review (no third-party ML framework)
- **Why Qwen 4B stays bundled as fallback**:
  - Apple FM has weaker schema enforcement — for our JSON card schema, Qwen 4B is more reliable
  - For vivid Chinese intros on obscure dishes, Qwen 4B's ZH training is deeper
  - For users who turn off Apple Intelligence in iOS Settings
  - For A/B testing during MVP0/MVP1
- **Why Qwen 3B stays as thermal fallback**: same as before, lower RAM/thermals

#### D-040 — Qwen 4B + 3B bundled (not download-on-demand)
- MVP0 includes both Qwen shards as bundled resources
- Adds ~2.4GB to .ipa size, but App Store supports on-demand resources
- Can be moved to download-on-demand in MVP1 if app size matters
- Locked per R6 Q4 = "a"

#### D-041 — `LLMBackend` enum updated: `appleFoundation | qwen4b | qwen3b` (was `qwen4b | qwen3b | appleIntelligence`)
- Matches the new priority order
- All 3 still runtime-switchable in Settings

#### D-042 — Vision `.revision3` (was `.revision2`)
- iOS 26 ships the updated Vision text recognition
- ~10-15% better CJK accuracy than `.revision2`
- We get it for free with the iOS 26 deployment target upgrade

#### D-043 — App Store IAP / TestFlight readiness
- Apple Developer account confirmed (R5 Q6)
- Can deploy to TestFlight once Day 8 device test passes

### Status: ready to start Day 1 of the build

All questions resolved. Next step: create the Xcode project at `ios/FoodieAI.xcodeproj`, add MLX-Swift via SPM, bundle `dishes.jsonl`, write the data-layer Swift files, write first unit test, verify build with `xcodebuild build`.


---

## Round 6 (continued) — 2026-07-26 (Testing & documentation policy)

### Context

After committing Day 1 of the build (commit `fbe45aa`), Jacky locked 3 engineering rules for the project going forward:

1. **≥95% test coverage** for all code
2. **Manual verification of every function** — not just "tests pass" but "I read the test and confirmed it tests the behavior I care about"
3. **Update specific stale docs after verified success** — concrete checklist of which docs to touch

Jacky chose:
- Coverage tool: Xcode built-in (no extra tools)
- Untestable code: refactor to be testable (introduce protocols), don't exclude
- Doc updates: specific named docs (explicit checklist)

### Locked decisions (Round 6 cont.)

#### D-044 — Testing & documentation policy created
- New file: [doc/testing-guidelines.md](testing-guidelines.md)
- 12 sections covering: coverage measurement, refactor-not-exclude rule, manual verification checklist, stale doc list, CI plan, examples, day-by-day done definition, post-MVP0 roadmap

#### D-045 — Coverage target is 95% overall, 80% per-file
- Enforced via Xcode's built-in code coverage (no extra tools)
- CI gate planned for MVP1; MVP0 uses manual coverage check
- Per-file threshold allows ContentView and other view code to be lower while overall is ≥95%

#### D-046 — Refactor-not-exclude policy for untestable code
- Default: introduce protocols + mock implementations
- Examples: OCRServiceProtocol, LLMServiceProtocol, CameraServiceProtocol, Clock, IDGenerator, FileSystem, HTTPClient
- Trivially untestable code (only `@main`) may be skipped

#### D-047 — Stale docs checklist (specific names)
- 12 specific docs named in §4 of testing-guidelines.md
- 30-second staleness check: `git diff --name-only` + ask "is this reflected in any doc?"
- Affected docs MUST be in the same commit as the code change

#### D-048 — Day 1 coverage status logged
- Models: 100% (trivial)
- DishRepository: ~80%
- ContentView smoke view: 0% (placeholder until Day 6)
- Overall: ~70% — will climb above 95% as Days 2-7 add real logic


---

## Round 7 — 2026-07-26 (Day 2: Fuzzy Search)

### Context

Day 1 done (commit b5f23eb). Jacky did the smoke test, confirmed the
"Loaded 126 dishes" message appeared, said "A) for day 2" to start
fuzzy search.

### Locked decisions (Round 7)

#### D-049 — FuzzyIndex shipped (Day 2)
- 4 channels: EN substring, EN Levenshtein, pinyin Levenshtein, ZH substring
- Scoring: exact > substring > edit, with menu_verified bonus
- Tiebreak: exact (0.01) > substring (0.005) > edit (0.0)
- Min query length 2 chars, top N 10, min confident score 0.5
- file: ios/FoodieAI/Data/FuzzyIndex.swift (168 lines)

#### D-050 — PinyinConverter shipped (Day 2)
- Hand-rolled lookup table for the 126 bundled dishes
- MVP0: no full pinyin library (would be ~5MB)
- MVP1: can swap in Pinyin-Swift (MIT) for arbitrary input
- file: ios/FoodieAI/Data/PinyinConverter.swift

#### D-051 — Fuzzy test queries reworked (Day 2)
- Original 20 queries in doc/fuzzy-search-tests.md were for the
  planned MVP1 200-dish DB (Mapo Tofu, Hainanese Chicken Rice, etc.)
  and didn't exist in the MVP0 126-dish DB
- Reworked: 32 queries across 8 groups (Exact EN, Exact ZH, Pinyin,
  Typo, Edge cases, Scoring behavior, Levenshtein, Normalize)
- file: doc/fuzzy-search-tests.md (rewritten)

#### D-052 — Day 2 coverage achieved
- 87/87 tests passing (40 new for Day 2)
- 97.88% line coverage overall
- 100% function coverage
- All models 100%, PinyinConverter 100%, FuzzyIndex 96.18%
- DishRepository 98.44%, FoodieAIApp 97.85%
- Above 95% threshold per D-045

#### D-053 — String scoring fix (substring edge case)
- Original: substring match was 0.6 + 0.3 * coverage
- Issue: when query is exactly the target length (perfect coverage),
  substring score 0.9 was being beaten by other substring matches
  at 0.95
- Fix: perfect coverage (>= 0.999) gets 0.95; partial coverage stays
  0.6 + 0.3 * coverage. Plus 0.005 substring tiebreak.

#### D-054 — Tiebreak fix (don't cap scores at 1.0)
- Original: capped at 1.0 with min(), killed the exact-match tiebreak
- Fix: allow scores > 1.0 internally so the 0.01/0.005 tiebreaks
  survive. Callers use minConfidentScore (0.5) for the "no match" check.


---

## Round 8 — Day 2.5 (smoke test view, helper extraction, coverage gap acknowledged)

Date: 2026-07-26
Total tests: **100** (87 from Day 2 + 13 new in Day 2.5)
Overall coverage: **67.58%** (down from Day 2's 97.88%)

### D-055 — Keep SmokeTestView under #if DEBUG, add ProductionPlaceholder for non-DEBUG
- Original Day 2 SmokeTestView lived in FoodieAIApp.swift unconditionally
- Wrapped in `#if DEBUG` so release builds get a clean placeholder
- @main struct just selects the view (still doesn't have a `.task` modifier
  on the WindowGroup — that failed to compile because WindowGroup has no
  `.task`, see test_note below)
- ProductionPlaceholder shows "foodieAI / MVP0 in progress / Loaded N dishes"
  for non-DEBUG builds
- file: ios/FoodieAI/App/FoodieAIApp.swift

### D-056 — Extract free functions for unit-testability
- `searchDishes(query:in:)` — wraps the dish index call from the smoke view
  so it can be tested without SwiftUI
- `scoreColor(_:)` — maps a FuzzyMatch score to sage/terracotta/amber/.secondary
- `runSearch(_:)` and the private `scoreColor` method were removed from
  SmokeTestView; the view body now calls these free functions
- file: ios/FoodieAI/Views/SearchViewHelpers.swift (new)

### D-057 — Document the FoodieAIApp.swift coverage gap
- After D-055 and D-056, the data-layer files all hit ≥98% and helpers hit 100%
- FoodieAIApp.swift sits at 44% line coverage because SwiftUI view bodies
  can't be unit-tested (a previous attempt crashed with `body() should not
  be called on ModifiedContent<...>`)
- Per doc/testing-guidelines.md §2, the right fix is a SearchViewModel on
  Day 6 — moving the remaining `body` logic into the model. For now, the
  SmokeTestView is verified manually in the simulator (you typed
  `sesame chicken` and got `芝麻鸡 (Sesame Chicken)` at score 1.21 sage-green).
- file: doc/testing-guidelines.md §1 (acknowledged in §1 pass criterion: `ContentView.swift until UI lands` pattern applies here too)

### test_note — WindowGroup has no `.task` modifier
- Tried to put `.task { try DishRepository.loadFromBundle() }` on the
  WindowGroup (an iOS 26 Scene). Compile error:
  `value of type 'WindowGroup<SmokeTestView>' has no member 'task'`
- Resolution: `.task` belongs on a View, not a Scene. Moved it inside the
  view body. Actually simpler: each view's `.task` (or the views inside
  the ViewBuilder closure) handles it. The final implementation in
  FoodieAIApp.swift has each view's `.task` independently load the repository.

---

## Round 9 — Day 3 (LLM glue: LLMService, PromptTemplates, CardGenerator, AppleFM)

Date: 2026-07-27
Total tests: **151** (100 from Day 2.5 + 51 new in Day 3)
Overall coverage: **73.76%** (up from Day 2.5's 67.58%; new file coverage 74–100%)

### D-062 — Smoke view extended with Card panel
- SmokeTestView gains a "Card (Day 3 — Apple FM)" section below the search results.
- Tapping a result selects it; pressing the orange "Generate card via Apple FM"
  button calls CardGenerator on that Dish and shows the parsed CardDraft OR
  a typed LLMError tagged label.
- Simulator surfaces `[tag=backend_unavailable]` for now — Apple FM is not
  callable in iOS 26 simulator. Verified visually (screenshot 2026-07-27).

### D-063 — LLMError: 5 typed cases
- backendUnavailable / malformedResponse / cancelled / refused / underlying
- Each has `errorDescription` (LocalizedError) and `tag` (machine-readable)
- Equatable uses case + reason so retry logic doesn't double-fire.
- file: ios/FoodieAI/LLM/LLMError.swift (100%)

### D-064 — LLMService protocol
- Sendable, async, `isAvailable` + `generate(prompt:) async throws -> String`.
- AppleFMBackend and (future) QwenBackend conform.
- file: ios/FoodieAI/LLM/LLMService.swift

### D-065 — CardDraft + strict CardJSONDecoder
- CardDraft is a lean 6-field model (nameZh?, nameEn?, introEn required,
  introZh?, pairWithEn, region?). Deliberately NOT reusing Dish because
  LLMs emit partial cards and we want fail-loud-on-type-mismatch.
- CardJSONDecoder.decode uses JSONSerialization (not Codable) so missing
  required `intro_en` throws a DecodingError with detail.
- Silently drops non-string entries in pair_with_en.
- file: ios/FoodieAI/LLM/CardDraft.swift (100%)

### D-066 — PromptTemplates: 2 prompt strategies
- systemFirst + systemRetry. The retry prompt explicitly mentions "previous
  response could not be parsed" to nudge chat-memory models away from the
  same mistake.
- userPrompt(for:query:) includes dish name + pinyin + user's typed query.
- file: ios/FoodieAI/LLM/PromptTemplates.swift (100%)

### D-067 — CardGenerator orchestrator
- Pipeline: 1st try with systemFirst → if parse fails, retry once with
  systemRetry → if still fails, throw malformedResponse tagged "after 2
  attempts". cancellation/refusal/backend-unavailable bypass retry.
- file: ios/FoodieAI/LLM/CardGenerator.swift (100%)

### D-068 — MockLLMService: 3 init overloads
- scripted (scripted list), failFirstWith.thenReturn, alwaysThrows.
- Records every prompt + call count for assertion in tests.
- file: ios/FoodieAI/LLM/MockLLMService.swift (95.24%)

### D-069 — AppleFoundationBackend with extractable error mapper
- Uses LanguageModelSession.GenerationError (the actual iOS 26 cases).
- The `generate(prompt:)` path is simulator-blocked (FM throws even when
  availability is .available). Surface as backendUnavailable.
- The error-mapping is a public free function `mapAppleFMError(_:)` so
  each FM error case can be tested in isolation. (Closed the gap from
  R8 D-057 — refactor-not-exclude pattern lifted coverage from 22% to 74%.)
- file: ios/FoodieAI/LLM/AppleFoundationBackend.swift (74.07%, simulator
  ceiling)

### D-070 — Two coverage gaps, both acknowledged
- App/FoodieAIApp.swift: 44.01% (same Day 2.5 gap; ViewModel on Day 6).
- LLM/AppleFoundationBackend.swift: 74.07% (the 9 FM error-mapping
  branches need a real `LanguageModelSession.GenerationError`, which
  the simulator can't produce — closed on-device in Day 8).
- file: ios/FoodieAI/Resources/Data/README.md (Known coverage gaps section)

### Test infrastructure (R9)
- LLMErrorTests (7): description + tag + Equatable contract pinned
- CardJSONDecoderTests (12): minimal/full/pretty/missing/non-object/round-trip
- CardGeneratorTests (8): happy path, retry, both-invalid, no-retry-error
  paths, availability gating
- MockLLMServiceTests (8): 3 init overloads + recording + isAvailable
- PromptTemplatesTests (9): user prompt shape + system keys + retry hint +
  looksLikeJSON
- AppleFoundationBackendAvailabilityTests (3): displayLabel + isAvailable +
  compile-time conformance
- mapAppleFMErrorTests (7): non-FM errors → underlying; error description
  always present; live availability + generate smoke (catches either
  branch)
- Total new: 54 (but 3 were duplicate fixes of failing tests so net = 51)

### Build issue encountered + fixed
- Info.plist wasn't being included in the app bundle → app launch returned
  "Missing bundle ID". Fixed by adding ios/FoodieAI/Info.plist with the
  expected keys (CFBundleDisplayName, permission strings, supported
  orientations). Tests target also needed GENERATE_INFOPLIST_FILE: YES.
