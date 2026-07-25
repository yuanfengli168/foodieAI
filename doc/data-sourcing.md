# Data Sourcing & Card Authoring Rules

> Status: Locked 2026-07-21
> Owner: Jacky
> Purpose: Define how dish cards are researched, written, and tagged — so MVP0's 100 cards (and MVP1's eventual 200) come out consistent in voice, length, and quality.

---

## 1. The 4 sources of truth

| Source | Tag | When to use | Card fields it can fill |
|---|---|---|---|
| **Wikipedia (EN + ZH)** | 📖 | Dish has a real Wikipedia article (most famous dishes) | All fields, high confidence |
| **百度百科** | 📖 (alternate) | Dish is Chinese and Wikipedia is weak, or no EN article exists | All fields, high confidence |
| **Menu-verified + LLM-generated** | 📷 | Dish is on a real MVP0 menu but has no encyclopedia entry | All fields, medium confidence — `is_menu_verified: true` |
| **LLM-only** | 🤖 | Dish exists, no encyclopedia entry, also not on any MVP0 menu | All fields, low confidence — require AI to flag uncertainty |

### Mixed sources
A card can have its `intro` from Wikipedia and its `flavor` profile LLM-inferred. Tag is based on the **weakest** field — if any required field is LLM-only, the whole card is tagged 🤖 (unless it's on a real menu, then 📷).

---

## 2. Card author workflow

For each of the 100 MVP0 dishes:

1. **Check if dish is in `data/menus/menu-*.json`** → set `is_menu_verified: true`
2. **Search Wikipedia EN** for `{name_en}` → if article exists, harvest intro, region, pair_with
3. **Search 百度百科** for `{name_zh}` → if article exists, harvest Chinese intro details
4. **Search Wikimedia Commons** for a photo of the dish → download if found, else set `photo_path: ""` and pick an emoji
5. **If neither Wikipedia has it** → LLM-generate all fields, then manually review for accuracy
6. **Tag the card** based on the source rule above
7. **Quality check** against the rules in §3 and §4

---

## 3. Card field rules

### 3.1 `id`
- **Format**: `lowercase_underscore`, no spaces, no diacritics
- **Convention**: 拼音 (no tones, spaces → underscores) for ZH dishes, English for EN-only dishes
- **Examples**:
  - `mapo_tofu` ✅
  - `ma_po_dou_fu` ✅ (alternative)
  - `Mapo Tofu` ❌
  - `麻婆豆腐` ❌
- **No collisions**: if two dishes want the same id, append a region suffix (`kung_pao_chicken_us` vs `kung_pao_chicken_sichuan`)

### 3.2 `name_zh`
- Use the **canonical Simplified Chinese** name as it appears on the real menu
- No traditional characters in MVP0
- No English in parens
- Examples: `麻婆豆腐`, `宫保鸡丁`, `海南鸡饭`, `炸酱面`

### 3.3 `name_en`
- Use the **most common English name** as it appears on Wikipedia / common use
- Title case
- Examples: `Mapo Tofu`, `Kung Pao Chicken`, `Hainanese Chicken Rice`
- **Avoid**: literal translations (`Pockmarked Grandmother Tofu`) unless that's the established EN name

### 3.4 `pinyin`
- **All lowercase, no tones, spaces between syllables**
- Examples: `ma po dou fu`, `gong bao ji ding`, `hai nan ji fan`
- **Punctuation**: hyphens are OK if that's the Wikipedia convention (`char-siu` for 叉烧)
- **Singaporean / Cantonese exceptions**: where the dish is known by a non-Mandarin name (e.g. `Hokkien mee`, `char kway teow`), use the **local romanization** and add a note in `aliases_zh`

### 3.5 `aliases_en`
- 0-5 alternate English names the user might type
- Examples for `Mapo Tofu`: `["pockmarked grandmother tofu", "spicy tofu", "mabo tofu"]`
- Examples for `Hainanese Chicken Rice`: `["chicken rice", "hainan chicken rice", "singapore chicken rice"]`
- **No need** to be exhaustive — fuzzy search handles single-typo cases. Aliases are for **semantic** alternatives, not typo recovery.

### 3.6 `aliases_zh`
- 0-3 alternate Chinese names (traditional, regional, abbreviated)
- Examples for `麻婆豆腐`: `[]` (canonical only)
- Examples for `海南鸡饭`: `["白斩鸡饭"]` (alt Singapore name)

### 3.7 `photo_path`
- Relative to app bundle: `photos/<id>.jpg`
- **Empty string** = no photo, use emoji fallback
- Image spec: JPEG, ~80-100KB each, max 800×600px
- **No AI-generated photos** in MVP0 — risk of hallucinated dishes. Real photos from Wikimedia Commons only.

### 3.8 `emoji_fallback`
- 1-2 emojis that represent the dish visually
- **Examples**:
  - `🌶️🧊` for 麻婆豆腐 (chili + ice/tofu)
  - `🍗` for 海南鸡饭 (chicken)
  - `🍜` for 炸酱面 (noodles)
  - `🥟` for 饺子
- **Rules**:
  - Use the actual food emoji when one exists (`🍜`, `🥟`, `🍗`, `🍤`, `🥘`)
  - Use ingredient emojis for dishes without a food emoji
  - **Don't** use generic "🍽️" — too bland
  - **Don't** use fire emoji `🔥` for "spicy" — confusing next to a chili emoji

### 3.9 `source` (the enum)
Valid values: `wikipedia` | `baidu_baike` | `wikipedia+baidu` | `menu_verified` | `llm_only`

| Value | When |
|---|---|
| `wikipedia` | EN Wikipedia article used for content |
| `baidu_baike` | 百度百科 article used for content |
| `wikipedia+baidu` | Both used, content is cross-verified |
| `menu_verified` | Dish is on a real menu, content is LLM-generated (this is the 📷 tag) |
| `llm_only` | LLM-generated everything, no real source, not on a menu (this is the 🤖 tag) |

### 3.10 `source_url`
- For `wikipedia` / `baidu_baike`: the article URL
- For `menu_verified`: empty string (no online source)
- For `llm_only`: empty string
- Format: full URL, e.g. `https://en.wikipedia.org/wiki/Mapo_tofu`

### 3.11 `is_menu_verified`
- `true` if the dish appears in one of the 2 MVP0 menus (the JSONs in `data/menus/`)
- `false` otherwise
- Independent of `source` — a dish can be both `wikipedia` AND `is_menu_verified: true`

### 3.12 `intro` (the most important field)

**Voice rules**:
- **2-4 sentences**, 20-80 words (target: 40-60 words)
- **Vivid and sensory** — what does it look like, smell like, taste like, feel like
- **No marketing fluff** — no "delicious", "amazing", "must-try"
- **One cultural hook** if relevant (origin, name origin, where it's eaten) — keep to 1 sentence
- **First sentence is the strongest** — many users will only read the first line

**Structure** (recommended):
- Sentence 1: **What's in it** (main ingredients, form)
- Sentence 2: **How it's made / how it tastes** (cooking method, dominant flavor)
- Sentence 3 (optional): **Cultural hook** (where from, who invented it)
- Sentence 4 (optional): **Texture or sensory detail** (silken, crispy, numbing)

**Examples**:

✅ **Good**:
> "Silken tofu cubes simmered in a fiery chili-bean sauce with ground pork and numbing Sichuan peppercorns. Born in 1860s Chengdu at a restaurant run by a pockmarked grandmother whose name gave the dish its title."

✅ **Good**:
> "Tender poached chicken served over fragrant rice cooked in chicken fat and pandan, with three dipping sauces. Singapore's national dish, adapted from Hainanese immigrants in the early 1900s."

❌ **Bad** (too generic):
> "A delicious Chinese dish made with tofu and chili. Very popular and loved by many people."

❌ **Bad** (too long):
> "This iconic Sichuan dish, which originated in the city of Chengdu in the 1860s, is made from silken tofu that has been cut into small cubes and then gently simmered in a complex sauce..."

❌ **Bad** (marketing speak):
> "An unforgettable explosion of flavor that will leave you craving more."

**Language rules**:
- **Use simple present tense**: "simmered in" not "is simmered in" or "gets simmered"
- **Avoid passive voice** when possible: "the restaurant ran" not "the restaurant was run"
- **No emoji in intro** (UI adds them around the flavor bars)

**Translation rules** (when using a Chinese source for EN intro):
- Translate the **meaning**, not the words
- Add a cultural hook only if it's interesting, not just to fill space
- Don't pad with adjectives to hit a word count

### 3.13 `flavor` (the 5-dimension profile)

Each value: integer 0-5.

| Value | Meaning |
|---|---|
| 0 | None / not present |
| 1 | Hint / trace |
| 2 | Subtle |
| 3 | Moderate |
| 4 | Pronounced |
| 5 | Dominant / extreme |

**Rules**:
- **All 5 fields required**, even if 0
- **Be honest** — many dishes have `sour: 0` and `sweet: 0`; that's fine
- **For "spicy + numbing" Sichuan dishes**: usually `spicy: 4-5, numbing: 3-5`
- **For Cantonese**: usually `spicy: 0, sour: 0, sweet: 1-2, salty: 2-3`
- **For dessert**: usually `spicy: 0, sweet: 4-5`
- **The `numbing` dimension is unique to Sichuan** — for non-Sichuan dishes, default to 0
- **The `sour` dimension is rare in Chinese cooking** — most savory Chinese dishes are sour: 0-1

**Examples**:

```json
"flavor": {"spicy": 5, "sour": 0, "salty": 3, "sweet": 1, "numbing": 5}  // 麻婆豆腐
"flavor": {"spicy": 0, "sour": 0, "salty": 2, "sweet": 1, "numbing": 0}  // 海南鸡饭
"flavor": {"spicy": 0, "sour": 0, "salty": 3, "sweet": 0, "numbing": 0}  // 炸酱面
"flavor": {"spicy": 2, "sour": 4, "salty": 2, "sweet": 3, "numbing": 0}  // 糖醋里脊
```

### 3.14 `pair_with`

- 1-4 items, what to eat/drink **with** this dish
- **Format**: lowercase English, comma-separated in display
- **Examples**:
  - 麻婆豆腐: `["steamed rice", "jasmine tea"]`
  - 海南鸡饭: `["chili sauce", "dark soy", "cucumber slices"]`
  - 炸酱面: `["pickled vegetables", "soy milk"]`
- **No emojis in the strings**
- **Be specific**: "steamed rice" not "rice", "jasmine tea" not "tea"

### 3.15 `region`

- **Single region** in EN
- For Chinese cuisines: use the cuisine name (`Sichuan`, `Cantonese`, `Shandong`, `Huaiyang`, `Northern`, `Shanghai`, `Fujian`, `Hunan`, `Xinjiang`)
- For Western dishes: country or cuisine (`Italian`, `French`, `American`, `Mexican`, `Indian`)
- For Singapore: `Singapore` (even if origin is Hainanese — it's the SG version)
- For pan-Chinese dishes: `China` or the most-associated region
- **No compound regions** (`Sichuan/Chongqing` → pick one)

### 3.16 `category`

Exactly one of: `main` | `side` | `soup` | `noodle` | `rice` | `dessert` | `drink` | `snack` | `breakfast` | `dim_sum`

**Decision rules**:
- Is it served as the main protein/carb of a meal? → `main`
- Is it a small accompanying dish? → `side`
- Is it a soup or stew (liquid-heavy)? → `soup`
- Is it noodle-based? → `noodle`
- Is it rice-based (where rice is the star)? → `rice`
- Sweet, eaten after the meal? → `dessert`
- Beverage? → `drink`
- Light bite, between meals? → `snack`
- Traditionally eaten at breakfast? → `breakfast`
- Bite-sized, in a steamer or small plate? → `dim_sum`
- **If in doubt, default to `main`**

### 3.17 `tags`

- 0-5 free-form tags for filtering / future search
- **Use these vocabularies only** (to keep tag space small):
  - `spicy`, `mild`, `sweet`, `sour`, `salty`, `numbing`
  - `vegetarian`, `vegan`, `vegetarian-option`, `pescatarian`
  - `gluten-free`, `dairy-free`
  - `rice-pair`, `noodle-pair`, `tea-pair`, `beer-pair`
  - `street-food`, `fine-dining`, `home-cooking`, `restaurant-only`
  - `quick`, `slow-cook`
  - `breakfast`, `lunch`, `dinner`, `late-night`
  - `cold-dish`, `hot-dish`
  - `communal` (family-style sharing)
- **No invented tags** — if your concept isn't in this list, leave it off

---

## 4. Quality checklist (run on every card before merging)

```
[ ] id is lowercase_underscore, no collisions
[ ] name_zh and name_en are both present, canonical
[ ] pinyin matches name_zh (if applicable)
[ ] photo_path exists on disk OR is empty string + emoji_fallback is set
[ ] source is one of the 5 valid values
[ ] is_menu_verified is correct (matches data/menus/)
[ ] intro is 20-80 words, vivid, no marketing fluff, first sentence is strongest
[ ] flavor has all 5 fields, each 0-5
[ ] pair_with has 1-4 lowercase EN items
[ ] region is single, canonical
[ ] category is one of the 11 valid values
[ ] tags are from the controlled vocabulary (or empty)
[ ] Source tag (📖/📷/🤖) is correct per the rule in §1
```

---

## 5. LLM-only card special rules

When `source: "llm_only"` (the 🤖 tag), apply extra scrutiny:

1. **Verify the dish actually exists** — if you can't find it on Wikipedia, 百度百科, or any menu, do not include it. Skip instead.
2. **LLM must include uncertainty signal** in the prompt:
   ```
   If you are not confident in any field, set it to null. Do not guess.
   ```
3. **Post-generation manual review** — read every LLM-only card. Reject any that:
   - Confuses two similar dishes
   - Has generic/wrong flavor profiles
   - Has intro longer than 80 words
   - Has any field that feels hallucinated
4. **Cap at 30% of the DB** — for MVP0, no more than 30 of 100 cards should be `llm_only`. The rest should be verifiable.

---

## 6. Menu JSONL format (input to card generation)

`data/menus/menu-a-sg-en.json`:
```json
{
  "menu_id": "menu-a-sg-en",
  "restaurant_name": "TBD",
  "cuisine": "Western",
  "language": "en",
  "location": "Singapore",
  "source_notes": "Photographed by Jacky on 2026-07-XX",
  "dishes": [
    {
      "line_number": 1,
      "name_on_menu": "Truffle Mushroom Soup",
      "price": "18.00",
      "section": "Starters"
    },
    ...
  ]
}
```

`data/menus/menu-b-bj-zh.json`:
```json
{
  "menu_id": "menu-b-bj-zh",
  "restaurant_name": "TBD",
  "cuisine": "Northern Chinese",
  "language": "zh-Hans",
  "location": "Beijing",
  "source_notes": "Online menu, scraped 2026-07-XX",
  "dishes": [
    {
      "line_number": 1,
      "name_on_menu": "炸酱面",
      "pinyin": "zha jiang mian",
      "price": "28元",
      "section": "面食"
    },
    ...
  ]
}
```

These are **input only** — they get merged into `data/dishes/dishes.jsonl` with full card content (intro, flavor, etc) added by the card-generation step.

---

## 7. Output: `data/dishes/dishes.jsonl`

One JSON object per line, exactly matching the schema in `mvp0-plan.md` §3. Files validated against the quality checklist in §4 before bundling.

**Build pipeline** (run once):
```
data/menus/menu-a-sg-en.json   ─┐
                                 ├─→ scripts/build_dishes.py
data/menus/menu-b-bj-zh.json   ─┘            │
                                             ↓
                              scripts/llm_batch_cards.py
                                             │
                                             ↓
                              (manual review of LLM-only cards)
                                             │
                                             ↓
                              data/dishes/dishes.jsonl ✓
```

---

## 8. What this doc does NOT cover (deferred to MVP1)

- Recipe generation field (`recipe_ingredients`, `recipe_steps`) — out of MVP0 scope
- Allergen tags (`contains_peanut`, etc.) — out of MVP0 scope
- Nutrition data — out of MVP0 scope
- Multiple photos per dish — MVP0 = 0 or 1
- User reviews / ratings — out of MVP0 scope
- Seasonal availability — out of MVP0 scope
- Price data — out of MVP0 scope (not on the card)
