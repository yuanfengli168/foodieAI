# Fuzzy Search Test Query Set (MVP0)

> Status: Locked 2026-07-21
> Owner: Jacky
> Purpose: 20 queries that prove the fuzzy search algorithm works across all 3 input modes (EN, ZH, transliteration) and edge cases. Use as a unit test for `FuzzyIndex`.

---

## How to use

Each query has:
- **Input** — what the user types
- **Expected top-1** — the dish it should return
- **Mode** — which code path it exercises

For MVP0 to be considered "search working", all 20 queries must return the expected top-1.

---

## Test queries

### Group A: Exact EN (5)

| # | Input | Expected top-1 | Notes |
|---|---|---|---|
| 1 | `Mapo Tofu` | `mapo_tofu` | Case insensitive |
| 2 | `kung pao chicken` | `kung_pao_chicken` | All lowercase |
| 3 | `Hainanese Chicken Rice` | `hainanese_chicken_rice` | Two-word dish |
| 4 | `Truffle Mushroom Soup` | `truffle_mushroom_soap` | From SG Menu A |
| 5 | `Beef Noodle Soup` | `beef_noodle_soup` | Generic EN |

### Group B: Exact ZH (5)

| # | Input | Expected top-1 | Notes |
|---|---|---|---|
| 6 | `麻婆豆腐` | `mapo_tofu` | Full ZH |
| 7 | `宫保鸡丁` | `kung_pao_chicken` | ZH chars |
| 8 | `海南鸡饭` | `hainanese_chicken_rice` | From SG Menu A (alt name) |
| 9 | `炸酱面` | `zha_jiang_mian` | From Beijing Menu B |
| 10 | `糖醋里脊` | `tang_cu_li_ji` | Sweet-and-sour |

### Group C: Pinyin transliteration (5)

| # | Input | Expected top-1 | Notes |
|---|---|---|---|
| 11 | `ma po dou fu` | `mapo_tofu` | Standard pinyin, spaces |
| 12 | `gongbaojiding` | `kung_pao_chicken` | No spaces |
| 13 | `hainanji fan` | `hainanese_chicken_rice` | 3-syllable dish |
| 14 | `zhajiangmian` | `zha_jiang_mian` | No spaces, 4-syllable |
| 15 | `char kway teow` | `char_kway_teow` | Singlish spelling (teochew) |

### Group D: Typo / fuzzy recovery (5)

| # | Input | Expected top-1 | Notes |
|---|---|---|---|
| 16 | `spicy tofy` | `mapo_tofu` | The classic from D-001 — 1-char deletion |
| 17 | `kng pao chicken` | `kung_pao_chicken` | 1-char deletion |
| 18 | `mapotofu` | `mapo_tofu` | No space, run-together |
| 19 | `hainanes chicken rice` | `hainanese_chicken_rice` | Transposed letter |
| 20 | `hakien mee` | `hokkien_mee` | Hokkien romanization typo |

---

## How scoring should rank these

A correctly-tuned `FuzzyIndex` should give each query a score ≥0.7 for the expected top-1. Lower than that and the user sees a "no confident match" UI, which is the worst-case UX.

### Score targets per group

| Group | Min score for top-1 | Pass criterion |
|---|---|---|
| A (Exact EN) | ≥0.95 | Top-1 should be unambiguous |
| B (Exact ZH) | ≥0.95 | Top-1 should be unambiguous |
| C (Pinyin) | ≥0.85 | One miss is acceptable if pinyin table is incomplete |
| D (Typo) | ≥0.70 | Fuzzy recovery is best-effort |

---

## Out-of-scope cases (don't include in MVP0 tests)

These are intentionally excluded to keep the test set focused. They'll be added in MVP1 when the search index grows.

- Synonym-only queries (e.g. `tofu` → 麻婆豆腐) — tested separately via synonym unit tests
- Multi-word queries with stop words (e.g. `i want mapo tofu`) — pre-processing not in MVP0
- Pinyin with tone marks (e.g. `má pó dòu fǔ`) — strip tones before search
- Mixed-script queries (e.g. `麻婆 tofu`) — pre-processing not in MVP0
- Partial word matches (e.g. `chicken` matches `Kung Pao Chicken`, `Hainanese Chicken Rice`, `Chicken Tikka`) — returns multiple, no single top-1
- Empty query — show empty state, no search

---

## Synonym unit tests (separate file)

Beyond the 20 main queries, the synonym map needs its own tests:

| Input | Expected | Synonym used |
|---|---|---|
| `tofu soup` | `mapo_tofu` (top match for "tofu") | `tofu` → matches all tofu dishes |
| `fried rice` | `yangzhou_fried_rice` (if it exists) | `fried` → `chao` |
| `hot and sour` | `hot_and_sour_soup` | `hot` → null (decorative) |

---

## Failure cases to verify

For completeness, the index should also return "no confident match" for:

| Input | Expected behavior |
|---|---|
| `xyzabc nonsense` | No top-1 above 0.5 → show "no match" UI |
| Empty string | Don't run search, show empty state |
| Single char `a` | Don't run search, too short |
| Only spaces/punctuation | Don't run search, show empty state |

---

## How to run these tests

1. Add `FuzzyIndexTests.swift` to the test target
2. Load bundled `dishes.jsonl` into a `DishRepository` in `setUp()`
3. Build a `FuzzyIndex` from the repository
4. For each of the 20 queries, assert `index.search(query).first?.dish.id == expected`
5. CI target: must pass before any merge to main

---

## When to add more queries

MVP0 ships with these 20. After MVP0 is on device and you have real user queries, add a "regression test" set:
- The 5 most common actual user inputs (not the 5 most common theoretical ones)
- Any query that returned the wrong dish on device
- Any query that returned no results when it should have

This grows the test set organically. Aim for 50-100 queries by MVP1 ship.
