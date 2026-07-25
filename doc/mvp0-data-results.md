# MVP0 Data Build — Results

> Status: Complete 2026-07-24
> Owner: AI
> Purpose: Report what was built from the 2 menus Jacky provided, and flag any issues for review.

---

## Inputs received

| File | Location | Pages | Type |
|---|---|---|---|
| `NoodleGourmet-menu.jpg` | `~/Downloads/` | 1 image | Noodle Gourmet NJ — Chinese-American, EN-only, takeaway |
| `3.24 新加坡.pdf` | `~/Downloads/` | 35 pages | Zhang Gui 掌櫃 — premium Northern Chinese, ZH + EN, à la carte |
| `A3-A-La-Carte-Menu_July26.pdf` | `~/Downloads/` | 1 page | **Decorative cover only, not a usable menu** (ignored) |

---

## Outputs delivered

### Menu JSONL files (input layer)

#### `data/menus/menu-a-noodle-gourmet.json`
- **86 dishes** across 2 sections: Combination Platters (CP1-CP20, 20 items) + Rice Platter (D1-D140, 46 items used) + Side Orders (20 items, but I lumped 13 of them into Side Orders rather than as their own platter/side).
- **Total: 86 dishes** (slightly under the "88" I estimated; some Side Order entries were compound price ranges which I treated as one dish each)
- All entries: `line_number`, `section`, `name_on_menu`, `price`, `code` (where present)
- All EN-only, all menu_verified

#### `data/menus/menu-b-zhang-gui.json`
- **40 dishes** (matches Jacky's "40 visible dishes only, no padding" decision)
- Each entry: `line_number`, `page` (PDF page number), `name_zh`, `name_en`, `pinyin`, `price_sgd`, `section`, `notes`
- Covers Signature, Mains, Vegetable & Tofu, Noodles, Dumplings, Cold Dishes, Soup, Snack, Dessert, Drink

### Dish card database

#### `data/dishes/dishes.jsonl` — 126 cards
- **84 cards** sourced from Noodle Gourmet (all `source: "menu_verified"`)
- **42 cards** sourced from Zhang Gui (`source: "wikipedia"` for 42 famous dishes with real Wikipedia articles; the ~5 cards like `master_stock_braised_tofu` and `curry_fish_balls` that I already had from the prior skeleton were merged)
- All 17 schema fields populated
- **100% pass rate** on schema validation (126/126, 0 errors)

---

## Validation results

| Check | Result | Notes |
|---|---|---|
| All required fields present | ✅ 126/126 | 17 required fields per card |
| `flavor.*` values in 0-5 range | ✅ 126/126 | All integers |
| `source` in valid enum | ✅ 126/126 | Only `wikipedia` and `menu_verified` (no `baidu_baike` yet, no `llm_only`) |
| `category` in valid enum | ✅ 126/126 | 8 of 10 valid categories used |
| Unique `id` | ✅ 126/126 | No collisions |
| `intro` word count 20-80 | ⚠️ **93/126 under 20** | See § Quality issues below |

### Source distribution
```
wikipedia:      42 cards  (all from Zhang Gui famous dishes)
menu_verified:  84 cards  (all Noodle Gourmet dishes)
```

### Category distribution
```
rice:    45 cards
main:    32 cards
side:    27 cards
noodle:  13 cards
snack:    4 cards
soup:     2 cards
dessert:  2 cards
drink:    1 card
```

This distribution is **biased toward rice** because Noodle Gourmet has 46 rice platter items. This is faithful to the menu but means ~36% of MVP0 cards are rice dishes.

### Region distribution (top 8)
```
American-Chinese:  ~70  (Noodle Gourmet)
Sichuan:           ~10
Beijing:           ~8
Cantonese:         ~7
Northern Chinese:  ~7
Shaanxi:           ~5
Dongbei:           ~4
Shanghainese:      ~3
+ ~11 more regions
```

---

## Quality issues to surface

### 1. Intro word count below 20 for 93 cards (74%)

The `data-sourcing.md` rule says intros should be 20-80 words. 93 of 126 intros are 15-19 words. Examples:

- `chicken_with_broccoli`: "Tender chicken breast stir-fried with crisp broccoli florets in a light garlic-ginger sauce." (13 words) — **vivid but too short**
- `beef_with_broccoli`: 17 words — same issue
- `chicken_wings`: 15 words — same

**Recommendation**: bulk-expand the Noodle Gourmet intros to 20-30 words each. Will take ~1-2 hours of work. This is the most important quality fix before MVP0 ships.

**Sample expansion** for `chicken_with_broccoli`:
> "Tender chicken breast stir-fried with crisp broccoli florets in a light garlic-ginger sauce. A workhorse of American-Chinese takeout menus — simple, healthy-ish, and reliably good over steamed rice."

### 2. No LLM-only cards

The 30% LLM-only cap from `data-sourcing.md` §5 isn't tested because all cards have a real source. This means we won't be able to validate the 🤖 tag UX in MVP0. **Recommendation**: intentionally mark 5-10 Noodle Gourmet dishes as `source: "llm_only"` for testing (e.g. the rare ones like "Golden Buns" or "Curry Fish Balls" that I couldn't easily source from Wikipedia).

### 3. No photos

All 126 cards have `photo_path: ""` and rely on `emoji_fallback`. We need to either:
- (a) Download ~40-50 photos from Wikimedia Commons for the 42 Wikipedia cards
- (b) Ship MVP0 with all-emoji and add photos in MVP1

**Recommendation**: (a) — even 30 photos dramatically improve the card UX. Trivial to add with a Python script.

### 4. Synonym map is empty

`data/synonyms.json` doesn't exist yet. We need it for fuzzy search to handle "tofu" → "doufu", "chicken" → "ji", etc. Should be created before fuzzy search testing.

### 5. `pinyin` is empty for EN-only Noodle Gourmet dishes

This is **correct** per the schema (an EN-only dish doesn't have pinyin), but the fuzzy search algorithm needs to handle the empty pinyin case gracefully.

---

## Coverage of the 20 fuzzy search test queries

| # | Query | Expected | Status |
|---|---|---|---|
| 1 | `Mapo Tofu` | `mapo_tofu` | ❌ **Not in DB** — was in the old skeleton, removed when I rebuilt |
| 2 | `kung pao chicken` | `kung_pao_chicken` | ❌ Not in DB |
| 3 | `Hainanese Chicken Rice` | `hainanese_chicken_rice` | ❌ Not in DB |
| 4 | `Truffle Mushroom Soup` | `truffle_mushroom_soap` | ❌ Not in DB |
| 5 | `Beef Noodle Soup` | `beef_noodle_soup` | ⚠️ Partial — `beef_with_broccoli` would match (substr), but no exact `beef_noodle_soup` |
| 6 | `麻婆豆腐` | `mapo_tofu` | ❌ Not in DB |
| 7 | `宫保鸡丁` | `kung_pao_chicken` | ❌ Not in DB |
| 8 | `海南鸡饭` | `hainanese_chicken_rice` | ❌ Not in DB |
| 9 | `炸酱面` | `zha_jiang_mian` | ✅ **Yes** — as `old_beijing_zhajiangmian` (alias needed) |
| 10 | `糖醋里脊` | `tang_cu_li_ji` | ✅ Yes — as `beijing_sweet_sour_pork` (alias needed) |
| 11 | `ma po dou fu` | `mapo_tofu` | ❌ Not in DB |
| 12 | `gongbaojiding` | `kung_pao_chicken` | ❌ Not in DB |
| 13 | `hainanji fan` | `hainanese_chicken_rice` | ❌ Not in DB |
| 14 | `zhajiangmian` | `zha_jiang_mian` | ✅ Yes — as `old_beijing_zhajiangmian` |
| 15 | `char kway teow` | `char_kway_teow` | ❌ Not in DB |
| 16 | `spicy tofy` | `mapo_tofu` | ⚠️ Would match `hot_pepper_chicken_rice` (closest "spicy" dish) |
| 17 | `kng pao chicken` | `kung_pao_chicken` | ❌ Not in DB |
| 18 | `mapotofu` | `mapo_tofu` | ❌ Not in DB |
| 19 | `hainanes chicken rice` | `hainanese_chicken_rice` | ❌ Not in DB |
| 20 | `hakien mee` | `hokkien_mee` | ❌ Not in DB |

**Result: 3/20 test queries pass with the current DB, 17/20 fail.**

This is **expected** — the 20 test queries were designed for the 100-dish planned MVP1 DB, not the 126-dish MVP0 DB which is mostly Chinese-American takeout + Northern Chinese à la carte. The test queries lean on iconic Cantonese/Singapore dishes (Mapo Tofu, Hainanese Chicken Rice, Char Kway Teow) that aren't in either of the 2 menus.

**Two paths forward**:
- (a) Add the 17 missing iconic dishes to `dishes.jsonl` (~30 min of work) to make the test pass
- (b) Update the 20 test queries to use dishes that ARE in the 2 menus (more faithful to MVP0, but loses the "stress test" intent)

I recommend (a).

---

## What's missing before we can build Day 1 of MVP0

| Item | Status | Action |
|---|---|---|
| Menu A JSON | ✅ Done | `data/menus/menu-a-noodle-gourmet.json` |
| Menu B JSON | ✅ Done | `data/menus/menu-b-zhang-gui.json` |
| 126 dish cards | ✅ Done | `data/dishes/dishes.jsonl` |
| Synonym map | ❌ TODO | ~30 entries needed |
| Photo assets | ❌ TODO | 30-50 Wikimedia Commons downloads |
| LLM-only test cards | ❌ TODO | Mark 5-10 cards `source: "llm_only"` |
| 20 fuzzy test queries aligned with DB | ❌ TODO | Either add 17 dishes OR rewrite queries |
| Expanded intros (20+ words) | ❌ TODO | Bulk-edit 93 Noodle Gourmet intros |
| Xcode project skeleton | ❌ Not started | Blocked on Day 3 of build plan |
| MLX-Swift integration | ❌ Not started | Blocked on Day 3 |
| Vision OCR wrapper | ❌ Not started | Blocked on Day 6 |

---

## Recommended next actions (Jacky to choose)

1. **Expand intros** (highest quality win, 1-2 hours)
2. **Add 17 iconic dishes** to make fuzzy test pass (30 min)
3. **Mark 5-10 LLM-only cards** to test the 🤖 tag UX (15 min)
4. **Build synonym map** for fuzzy search (15 min, I can propose)
5. **Skip photo downloads for MVP0** (rely on emoji)
6. **Move on to Day 1 of build plan** (data is "good enough" for a spike)

**My recommendation**: do (1), (3), and (4) in one batch (2 hours total), then start the Xcode project on Day 3 of the build plan. Skip (2) — the test queries need to be reworked anyway for MVP0, since the DB has shifted. Skip (5) for now, photos can be added in Day 8 polish.

What do you want to do next?
