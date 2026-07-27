# FoodieAI TODO

> Status: Active
> Started: 2026-07-25
> Purpose: Capture polish + future-work items that have come up but are NOT blockers for MVP0. Sorted by priority within each bucket.

---

## MVP0 polish (P2 — do if time, ship without if not)

- [ ] **Expand 93 short intros** in `dishes.jsonl` from <20 words to 20-30 words. Each Noodle Gourmet dish needs a "why this is interesting" sentence added. (Q-014) — est. 1-2 hours
- [ ] **Re-align 20 fuzzy test queries** in `fuzzy-search-tests.md` to match the 126-dish MVP0 DB, or add 17 iconic dishes (Mapo Tofu, Hainanese Chicken Rice, Char Kway Teow, etc.) to make existing queries pass. (Q-018) — est. 30 min
- [ ] **Mark 5-10 cards `source: "llm_only"`** so the 🤖 tag UX can be tested. (Q-015) — est. 15 min
- [ ] **Build `data/synonyms.json`** with ~30 entries (tofu↔doufu, chicken↔ji, rice↔fan, etc.) for smarter fuzzy search. (Q-017) — est. 15 min, **deferred to MVP1 per Jacky Round 5**
- [ ] **Download ~40 Wikimedia Commons photos** for the 42 Wikipedia cards. Currently all `photo_path: ""` and rely on emoji. (Q-016) — est. 1-2 hours, **deferred per Jacky Round 5 (use emoji only for MVP0)**

---

## MVP1 prep (P3 — do after MVP0 ships)

### OCR benchmark
- [ ] Run the 15-20 menu real-world OCR benchmark per `ocr-benchmark-plan.md` (D-007, Q-006). 27-32 hours total, one weekend + 2 evenings. **Defer to MVP1 per Jacky Round 5 Q12**
- [ ] If benchmark fails <85% line accuracy, design the post-OCR spell correction (CoreML, ~50MB) per `model-comparison.md` "OCR Strategy" section

### UX upgrades
- [ ] **OCR review screen** (per-line confidence + edit-before-confirm) — deferred to MVP1 per Jacky Round 5 (Q1). Add long-press hook now so the data model supports it
- [ ] **Dark mode** color tokens — light-only in MVP0, dark variant in MVP1
- [ ] **40 hand-drawn food sketches** — commission from Fiverr / Behance, ~$200. Replace emoji hero for the most-seen dishes
- [ ] **iPad layout** — iPad-specific grid for the dish list (currently iPhone-only)

### Data work
- [ ] **MVP1 dish DB: 100 ZH + 100 EN/Western** (D-002). MVP0's 126 cards are throwaway spike data; MVP1 starts fresh. **Lock: separate from MVP0, per Jacky Round 5 Q10**
  - **Note 2026-07-27 (R10):** the 126 MVP0 cards stay in the DB through the MVP0 spike — they are *not* discarded mid-build. The MVP1 rebuild happens *after* MVP0 ships, not before. Treat the MVP0 cards as the dataset the smoke-test view searches against.
- [ ] **Synonym map** (Q-017) — build before fuzzy search unit tests
- [ ] **Allergen tags** (`contains_peanut`, etc.) — out of MVP0, in MVP1+ per `data-sourcing.md` §8

---

## MVP2 (P4 — long-term)

- [ ] **Recipe generation** field (`recipe_ingredients`, `recipe_steps`) — out of MVP0, in MVP1+ per Jacky Round 5 Q8. Originally brainstorm said MVP1, was logged as MVP3 in Round 4 summary, **corrected to MVP1+** per Jacky
- [ ] **Allergens + dietary** (peanut, gluten, dairy, halal, kosher, vegan, etc.)
- [ ] **Multi-language beyond EN/ZH** (JP, KR, FR, ES, DE, RU, TH, VI, AR)
- [ ] **Restaurant finder** (Apple Maps integration)
- [ ] **Online cloud fallback** (OpenRouter, paid tier) — see `mvp2-paid.md`
- [ ] **User-contributed photos** + content
- [ ] **iCloud sync** of "Recently viewed" across devices

---

## MVP3+ (P5 — speculative)

- [ ] **Live AR overlay** (point camera, see translations floating)
- [ ] **Voice input** (audio menu reading)
- [ ] **Social features** (share discoveries, ratings)
- [ ] **Custom sketch set for 200+ dishes**
- [ ] **Cook-along mode** (step-by-step recipe with timers)
- [ ] **App Store listing** (screenshots, description, ASO)
- [ ] **Android version** (same Swift code with Kotlin Multiplatform? or full rewrite?)

---

## Doc hygiene (P3)

- [ ] **Archive older feedback rounds** to `archive-rounds-1-4.md` (per Jacky Round 5 Q16). Keep `feedback-log.md` for current + future rounds
- [ ] **Consolidate D-001 to D-027** into 5-7 bigger decisions (per Jacky Round 5 Q17). Will revisit after MVP0 ships
- [ ] **Update `data-sourcing.md`** to reflect "20-30 word intros are MVP0 acceptable" (the strict 20-80 rule was too rigid)

---

## Open questions from Round 5 (resolved)

These were answered in Round 5 and are now in `feedback-log.md` (D-028 → D-033):

- Q1: Auto-start on capture (no review screen) — **MVP0, defer review to MVP1** ✅
- Q2: Color scheme — **warm cream + terracotta + sage + gold** (see `ui-design-brief.md` §2) ✅
- Q3: LLM-only toggle behavior — **hide card entirely** when off ✅
- Q4: MVP0 success criteria — **all four (speed, quality, OCR, fun) + easy to use = low per-task friction** ✅
- Q5: LLM priority — **Qwen 4B primary, Qwen 3B thermal fallback, Apple Intelligence best-effort** ✅
- Q6: User journey — **take photo → app auto-runs full pipeline** ✅
- Q7: Hand-off — **MVP0 ship = end of current phase, no MVP1 planning yet** ✅
- Q8: Recipe — **MVP1+ (corrected from earlier MVP3 summary)** ✅
