# Fuzzy Search Test Queries (MVP0)

> Status: **Reworked 2026-07-26 (Day 2)**
> Owner: AI
> Purpose: 32 test queries that prove the `FuzzyIndex` works across all 3 input modes (EN, ZH, pinyin transliteration) and edge cases. Use as a unit test for `FuzzyIndex` (see `ios/FoodieAITests/FuzzyIndexTests.swift`).

---

## Important context

The 20 original test queries in this file were designed for the planned MVP1 200-dish DB, which would include iconic Cantonese/Singapore dishes like Mapo Tofu, Hainanese Chicken Rice, Char Kway Teow, and Kung Pao Chicken. **None of those dishes are in the MVP0 126-dish DB** (Noodle Gourmet NJ + Zhang Gui SG). So the original queries were reworked for Day 2 to use dishes that actually exist in the 126-dish DB.

When the DB changes (MVP1 adds 200+ new dishes), revisit these tests per the stale-docs checklist in `doc/testing-guidelines.md` §4.

---

## How scoring works (locked Day 2)

| Channel | Trigger | Score |
|---|---|---|
| Exact EN match | `name_en.lowercased() == query` | 1.0 (+ 0.01 tiebreak) |
| Exact pinyin match | `pinyin == query` | 1.0 (+ 0.01 tiebreak) |
| Substring EN (perfect coverage) | `name_en.contains(query)` with coverage ≥ 0.999 | 0.95 (+ 0.005 tiebreak) |
| Substring EN (partial) | `name_en.contains(query)` with coverage < 0.999 | 0.6 + 0.3 × coverage (+ 0.005 tiebreak) |
| Substring ZH | `name_zh.contains(query)` | 0.6 (+ 0.005 tiebreak) |
| Edit-distance EN | Levenshtein ≤ 2 | 1.0 − dist/max(len) |
| Edit-distance pinyin | Levenshtein ≤ 2 | (1.0 − dist/max(len)) + 0.3 |
| **Bonus** | `is_menu_verified` | +0.2 |

**Min query length**: 2 chars (1-char queries return empty).
**Top N**: 10.
**Min confident score**: 0.5.

---

## Test queries (32)

### Group A: Exact EN (4)

| # | Input | Expected top-1 | Notes |
|---|---|---|---|
| 1 | `Sesame Chicken` | `sesame_chicken` | Exact match; beats `sesame_chicken_rice` (substring) |
| 2 | `General Tso's Chicken` | `general_tsos_chicken` | Apostrophe in canonical name |
| 3 | `Beef with Broccoli` | `beef_with_broccoli` | Multi-word; stop word "with" |
| 4 | `CURRY FISH BALLS` (uppercase) | `curry_fish_balls` | Case-insensitive |

### Group B: Exact ZH (3)

| # | Input | Expected top-1 |
|---|---|---|
| 5 | `京味烤鸭` | `beijing_roast_duck` |
| 6 | `老北京炸酱面` | `old_beijing_zhajiangmian` |
| 7 | `葱油饼` | `scallion_pancake` |

### Group C: Pinyin transliteration (4)

| # | Input | Expected top-1 | Notes |
|---|---|---|---|
| 8 | `lan zhou niu rou la mian` | `lanzhou_beef_noodles` | Full pinyin with spaces |
| 9 | `dongbeiliangpi` | `dongbei_liangpi` | No spaces |
| 10 | `jing wei kao ya` | `beijing_roast_duck` | Pinyin -> ZH |
| 11 | `lao bei jing zha jiang mia` | `old_beijing_zhajiangmian` (top 3) | 1-edit pinyin typo |

### Group D: Typo / edit distance recovery (2)

| # | Input | Expected top-1 | Notes |
|---|---|---|---|
| 12 | `sesme chicken` (1 deletion) | `sesame_chicken` | |
| 13 | `beef with brocoli` (1 transposition) | `beef_with_broccoli` | |

### Group E: Edge cases (5)

| # | Input | Expected | Notes |
|---|---|---|---|
| 14 | `` (empty) | `[]` | Empty query |
| 15 | `   ` (whitespace only) | `[]` | Whitespace only |
| 16 | `a` (1 char) | `[]` | Below minQueryLength |
| 17 | `xyzabc nonsense` | top score < 0.5 | Nonsense |
| 18 | `Sesame Chicken` exact | `reason == .exactEn` | Reason verification |

### Group F: Scoring behavior (4)

| # | Input | Expected behavior |
|---|---|---|
| 19 | `chicken` | Results sorted by score desc |
| 20 | `rice` | Up to 10 results |
| 21 | `Sesame Chicken` | Top reason is `exactEn` |
| 22 | `Sesame Chicken` (matched dish) | `top.dish.isMenuVerified` |

### Group G: Levenshtein unit tests (5)

| # | Function | Test |
|---|---|---|
| 23 | `levenshtein("abc", "abc", 5)` | returns 0 |
| 24 | `levenshtein("abc", "abd", 5)` | returns 1 |
| 25 | `levenshtein("abc", "xyz", 2)` | returns 3 (exceeds max) |
| 26 | `levenshtein("", "", 5)` | returns 0 |
| 27 | `levenshtein("abc", "abcdefghij", 2)` | returns 3 (length diff > max) |

### Group H: Normalize unit tests (5)

| # | Function | Test |
|---|---|---|
| 28 | `normalize("HELLO")` | returns "hello" |
| 29 | `normalize("hello, world!")` | returns "hello world" |
| 30 | `normalize("麻婆豆腐")` | returns "麻婆豆腐" (kept) |
| 31 | `normalize("  hello   world  ")` | returns "hello world" |
| 32 | `normalize("hello 麻婆 world")` | returns "hello 麻婆 world" |

---

## Coverage targets (from `doc/testing-guidelines.md`)

- All 4 channels tested: exact EN/ZH, substring, edit-distance, pinyin
- All 5 edge cases tested: empty, whitespace, 1-char, nonsense, long-query
- All 3 scoring behaviors tested: sort order, top-N cap, reason population
- `levenshtein` and `normalize` are pure functions with 5 unit tests each

---

## How to run

```bash
cd ios
xcodebuild -project FoodieAI.xcodeproj -scheme FoodieAI \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -configuration Debug -only-testing:FuzzyIndexTests test
```

---

## What this doc does NOT cover

- Synonym map tests (deferred to MVP1 per R5 Q5)
- Real-pinyin library tests (MVP0 uses hand-rolled table)
- OCR-then-fuzzy integration tests (Day 5)
- UI-driven search tests (Day 6)
