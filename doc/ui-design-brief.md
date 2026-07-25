# MVP0 UI Design Brief

> Status: Locked 2026-07-25
> Owner: Jacky + AI
> Purpose: Lock the visual language for MVP0 — colors, typography, layout, mood — so the Xcode project has a clear design target.

---

## 1. Mood

**"A warm foodie notebook, not a tech app."**

When a user opens foodieAI, they should feel:
- **Casual** — like opening a personal travel journal, not a corporate tool
- **Warm** — colors that make you hungry, not clinical
- **Friendly** — copy that talks like a foodie friend, not a translation API
- **Comfortable** — large tap targets, generous whitespace, no fiddly controls
- **Trustworthy** — sources shown, no hidden AI

### Visual references (for inspiration, not copying)
- Apple Notes (warm cream + SF Pro)
- A handwritten food journal
- A hand-illustrated cookbook (e.g. Salt, Fat, Acid, Heat)
- A casual travel blog (e.g. Smitten Kitchen)
- The art style of *Wanderlost* by Elly Blake

### Anti-references (what we are NOT)
- Google Translate (clinical, gray)
- A corporate SaaS dashboard
- A stock-image travel app
- A "Chinese restaurant" stereotype (red + gold dragons + fortune cookie imagery)
- Minimalist all-white productivity apps (Notion, Linear)

---

## 2. Color palette (locked)

| Token | Hex | RGB | Where used | Why |
|---|---|---|---|---|
| **Background** | `#FAF7F2` | 250, 247, 242 | App background, card surfaces | Warm cream, reads like paper menu |
| **Primary text** | `#2A2522` | 42, 37, 34 | Dish name, intro, body | High contrast, warm undertone |
| **Secondary text** | `#6B5E54` | 107, 94, 84 | Pinyin, captions, source URLs | Soft, doesn't fight primary |
| **Accent (spicy/CTA)** | `#C7683D` | 199, 104, 61 | Buttons, spicy flavor bar, active state | Terracotta — warm, food-associated |
| **Secondary (savory)** | `#7A9A6E` | 122, 154, 110 | Salty/savory flavor bar, success | Sage green — calm, natural |
| **Tertiary (sweet/sour)** | `#D4A574` | 212, 165, 116 | Sweet + sour flavor bars | Warm gold — appetite-stimulating |
| **Numbing** | `#8B6F8E` | 139, 111, 142 | Numbing flavor bar (Sichuan marker) | Muted plum — distinct from spicy |
| **Surface border** | `#E8E0D4` | 232, 224, 212 | Card borders, dividers | Soft cream-tan separation |
| **Error** | `#B85450` | 184, 84, 80 | Error banners, blocking modals | Soft red, not alarm-red |
| **Warning** | `#C9A227` | 201, 162, 39 | Low confidence warnings | Honey yellow |
| **Surface raised** | `#FFFFFF` | 255, 255, 255 | Modals, photo backgrounds | Pure white for image contrast |

### Accessibility check
- Primary text on background: **WCAG AAA** (contrast ratio 13.5:1)
- Accent on background: **WCAG AA Large** (4.7:1) — fine for buttons and 16pt+ text, **not** for body text
- All flavor bars have icon labels in addition to color (🌶️ Spicy, 🍋 Sour, etc.) so colorblind users can still read

### Dark mode
**Out of scope for MVP0.** Ship light mode only. MVP1 can add a dark variant with deep walnut + cream accents.

---

## 3. Typography (locked)

| Use case | Font | Size | Weight | Color |
|---|---|---|---|---|
| Dish name (ZH) | System PingFang TC | 28pt | Semibold | Primary text |
| Dish name (EN) | System SF Pro | 22pt | Medium | Primary text |
| Pinyin | System SF Pro | 14pt | Light | Secondary text |
| Intro body | System SF Pro | 16pt | Regular | Primary text |
| Flavor bar label | System SF Pro | 12pt | Medium | Primary text |
| Button label | System SF Pro | 16pt | Semibold | Accent (or white on accent bg) |
| Source tag | System SF Pro | 11pt | Medium | Secondary text |
| Section header | System SF Pro | 18pt | Semibold | Primary text |
| Caption / metadata | System SF Pro | 12pt | Regular | Secondary text |

**No custom fonts in MVP0** — keeps app size small, leverages Apple's best-in-class rendering.

### Line spacing
- Intro body: 1.45× line height (roomy, comfortable to read)
- Card titles: 1.2× (tight, scannable)

---

## 4. Iconography

### System icons (SF Symbols)
- 🔍 search (in search box)
- 📷 camera (capture button)
- ➕ plus (photo library button)
- ⚙️ gear (settings)
- ← arrow.left (back)
- × xmark (close, dismiss)
- ⓘ info.circle (source link, about)

### Food emojis
Used as **card heroes** when no photo. Each dish has a designated `emoji_fallback` (see `data-sourcing.md` §3.8).

**Sizing on cards**:
- Hero: 80pt, centered, 16pt margin
- Inline: 16pt, baseline-aligned with text

**Custom sketch upgrade path** (out of MVP0 scope):
- MVP0: emoji (works now)
- MVP1: ~40 hand-drawn sketches (commissioned art) for the most-seen dishes
- MVP2: full 200-dish sketch set
- Color palette for sketches: same warm cream bg + terracotta + sage + gold

---

## 5. Spacing & layout

### Spacing scale (8pt grid)
- `xxs`: 4pt (icon-to-text gap)
- `xs`: 8pt (within a single component)
- `s`: 12pt (between list items)
- `m`: 16pt (card internal padding)
- `l`: 24pt (between cards)
- `xl`: 32pt (screen padding top/bottom)
- `xxl`: 48pt (section break)

### Card layout
- Border radius: 16pt (soft, modern, not "boxy")
- Internal padding: 16pt all sides
- Border: 1pt solid `#E8E0D4` (or no border + drop shadow 0,2,8 at 8% black)
- Drop shadow: `0 2pt 8pt rgba(0,0,0,0.04)` (very subtle, just enough depth)

### Tap target minimum
- **44×44pt** (Apple HIG)
- List rows: full-width, 60pt min height
- Buttons: 48pt height
- Flavor bars: tap-anywhere on bar = show number tooltip

### Screen layout
- Top safe area: 8pt below status bar
- Bottom safe area: 16pt above home indicator
- Side margins: 16pt on iPhone (so 32pt total gutter)

---

## 6. Card structure (the hero of the app)

```
┌─────────────────────────────────────┐
│                                     │
│         [🌶️ hero emoji]            │  ← 80pt, centered, 24pt top padding
│              80×80                  │
│                                     │
│   麻婆豆腐                📖 Wiki   │  ← 28pt ZH, then 22pt EN, 14pt pinyin
│   Mapo Tofu                          │     source tag right-aligned
│   má pó dòu fú                       │
│                                     │
│   ─────────────────────────────     │  ← 1pt divider
│                                     │
│   A Taste                            │  ← 14pt section header, semibold
│   Silken tofu in fiery chili-bean   │  ← 16pt body, 1.45× line height
│   sauce with ground pork and         │
│   numbing Sichuan peppercorns.       │
│   Born in 1860s Chengdu...           │
│                                     │
│   ─────────────────────────────     │
│                                     │
│   Flavor                             │
│   🌶️  Spicy    ████░░  4/5         │  ← 5 flavor bars
│   🍋  Sour     ░░░░░░  0/5         │     bar: 8pt tall, 4pt radius
│   🧂  Salty    ███░░░  3/5         │     filled: flavor color
│   🍯  Sweet    █░░░░░  1/5         │     unfilled: #E8E0D4
│   🥜  Numbing  █████░  5/5         │
│                                     │
│   ─────────────────────────────     │
│                                     │
│   Pair with                          │
│   Steamed rice, jasmine tea          │  ← 16pt body
│                                     │
└─────────────────────────────────────┘
```

### Notes
- No "Region" / "Category" / "Tags" in MVP0 card (those were in brainstorm; deferring for cleaner MVP0)
- The source tag is a **subtle text + emoji** in the top-right, not a colored chip — fits the casual mood
- Card padding 16pt; section dividers are 1pt `#E8E0D4` with 16pt vertical space above/below
- Card is scrollable (intro can be 2-4 lines, fits in the visible area for most dishes)

---

## 7. Root screen layout (ContentView)

```
┌─────────────────────────────────────┐
│  🔍  What are you eating?     ⚙️   │  ← search box, 48pt height
├─────────────────────────────────────┤
│                                     │
│   ┌─────────────────────────────┐  │
│   │  📷  Snap a menu             │  │  ← 2 big CTA buttons, 56pt each
│   └─────────────────────────────┘  │
│   ┌─────────────────────────────┐  │
│   │  ➕  Pick from photos        │  │
│   └─────────────────────────────┘  │
│                                     │
│   Recently viewed                    │  ← section header, 18pt
│   ─────────────                      │
│                                     │
│   🌶️  麻婆豆腐 (Mapo Tofu)         │  ← list rows, 60pt
│       Sichuan · spicy 5 · numbing 5│
│                                     │
│   🍗  海南鸡饭 (Hainanese...)       │
│       Singapore · mild              │
│                                     │
└─────────────────────────────────────┘
```

### Behavior (MVP0)
- **Search box**: live-filter as you type. Empty input → show "Recently viewed"
- **📷 Snap a menu button**: opens camera (PHPhotoLibrary-style picker if no permission). **Auto-starts OCR + fuzzy + dish list on capture** (no review screen, per Round 5 Q1)
- **➕ Pick from photos button**: opens photo library. Same auto-start flow
- **Recently viewed**: shows last 10 dishes the user opened. Persists across launches
- **⚙️ Settings**: LLM picker (4B/3B/Apple Intelligence), "About", version

### Hidden affordances
- **Long-press on a recent dish row** → "Re-edit OCR results" (placeholder for MVP1's review screen). Disabled in MVP0.

---

## 8. Empty states & loading

| State | Display |
|---|---|
| First launch (no history) | "Snap a menu or pick a photo to get started. Or search for a dish above." |
| Search no results | "No dishes match. Try a different spelling." |
| Search too short (<2 chars) | Don't search; show empty search box |
| OCR in progress | Centered spinner + "Reading menu..." (terracotta) |
| Fuzzy matching in progress | (no spinner; instant on the 126-dish DB) |
| Card generation in progress | Hero emoji visible, body text "Thinking..." then 2-4 sentence intro fades in |
| All cards failed | Error banner: "Couldn't generate any cards. Tap to retry." |
| Network needed (not for MVP0) | n/a — all offline |

---

## 9. Animation & motion

- **Card appearance**: fade in 200ms ease-out (not slide-in — feels less janky on slow gen)
- **Flavor bar fill**: animate from 0 to value over 300ms ease-out (subtle, satisfying)
- **Search box focus**: 150ms border color transition (accent border appears)
- **Button press**: scale 0.97 over 80ms (subtle, not bouncy)
- **Error banner**: slide down from top, 250ms ease-out; auto-dismiss after 3s for warnings, manual for errors
- **Tab changes**: cross-fade, 200ms

**No parallax, no spring physics, no skeleton screens in MVP0.** Calm motion, not playful.

---

## 10. Accessibility

- All tap targets ≥ 44pt ✅
- All text respects Dynamic Type (system fonts scale)
- All flavor bars have icon + numeric label (not color-only)
- VoiceOver labels on all buttons ("Snap a menu", not "Camera")
- Reduce Motion: disables flavor bar fill animation, card fade-in becomes instant
- High Contrast: borders become 2pt, accent becomes pure white-on-terracotta

---

## 11. Asset inventory (MVP0 needs)

| Asset | Source | Status |
|---|---|---|
| App icon | Sketch + Apple icon generator | TODO Day 9 |
| Launch screen | Cream background + logo text | TODO Day 9 |
| Search icon | SF Symbol `magnifyingglass` | Built-in |
| Camera icon | SF Symbol `camera.fill` | Built-in |
| Plus icon | SF Symbol `plus` | Built-in |
| Settings icon | SF Symbol `gear` | Built-in |
| 126 dish emoji fallbacks | Already in `dishes.jsonl` | ✅ Done |
| 4 flavor bar icons | SF Symbols + emoji | Built-in |
| 4 source tag icons | Emoji (📖📷🤖❓) | Built-in |

**Total custom assets for MVP0: 0.** Pure system + emoji.

---

## 12. What this doc does NOT cover

- Dark mode color tokens (MVP1)
- Localization (MVP1+)
- App Store screenshots (MVP1, post-shipping)
- Marketing site / landing page (out of scope)
- Custom font (out of scope — system fonts only)
- Custom hand-drawn sketches (MVP1)
- iPad-specific layout (MVP0 is iPhone-only, iPad will run in compatibility mode)
