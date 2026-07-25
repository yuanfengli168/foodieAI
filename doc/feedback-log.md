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
