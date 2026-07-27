# foodieAI — iOS App

> MVP0 status: **Day 4 complete** (Camera + Library picker + MenuProcessor stub, 194 tests)
> Last build: 2026-07-27 (iOS 26 simulator, iPhone 17 Pro Max)

## Quick start

```bash
# Regenerate the Xcode project (after editing project.yml or adding files)
xcodegen generate

# Build the app
xcodebuild -project FoodieAI.xcodeproj -scheme FoodieAI \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -configuration Debug build

# Run the unit tests
xcodebuild -project FoodieAI.xcodeproj -scheme FoodieAI \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -configuration Debug test
```

## What works on Day 1

- `dishes.jsonl` (126 cards from 2 menus) is bundled in the .app
- Data models: `Dish`, `FlavorProfile`, `CardSource`, `LLMBackend`
- `DishRepository` loads, parses, validates the bundled JSON
- 11 unit tests pass (bundle load, 126 dishes, unique IDs, valid flavor/category/source, menu_verified count, emoji fallback, LLM priority order, card source tags)
- **Testing policy**: ≥95% coverage, manual verification per function, stale doc updates per [doc/testing-guidelines.md](../../doc/testing-guidelines.md)

## What works on Day 2

- `PinyinConverter` (hand-rolled lookup for 126 dishes, no full pinyin library)
- `FuzzyIndex` with 4 channels: EN substring, EN Levenshtein, pinyin Levenshtein, ZH substring
- Scoring: exact > substring > edit-distance, with menu_verified bonus and exact-match tiebreak
- 40 new tests (87 total): 28 fuzzy + 9 pinyin + 3 normalize/levenshtein behavior

## Day 1.6 / Day 3 coverage status

| File | Coverage |
|---|---|
| Models (CardSource, Dish, FlavorProfile, LLMBackend) | **100%** |
| `Data/PinyinConverter.swift` | **100%** |
| `Views/SearchViewHelpers.swift` | **100%** |
| `LLM/LLMError.swift` | **100%** |
| `LLM/CardDraft.swift` | **100%** |
| `LLM/CardGenerator.swift` | **100%** |
| `LLM/PromptTemplates.swift` | **100%** |
| `LLM/MockLLMService.swift` | **95.24%** |
| `Data/DishRepository.swift` | **98.44%** |
| `Data/FuzzyIndex.swift` | **98.73%** |
| `LLM/AppleFoundationBackend.swift` | **74.07%** ⚠️ (simulator-unreachable FM error cases) |
| `App/FoodieAIApp.swift` | **44.01%** ⚠️ |
| **Overall line coverage** | **73.76%** ⚠️ |

**Known coverage gap (R8 D-057):**

`App/FoodieAIApp.swift` sits at 44% because the SwiftUI view bodies (`SmokeTestView`,
`ProductionPlaceholder`) and `SearchField` UIViewRepresentable aren't reachable
from unit tests. We extracted `searchDishes()` and `scoreColor()` to
`SearchViewHelpers.swift` so the logic is testable at 100%, but the view-tree
rendering can't be unit-tested without standing up XCUIApplication.

Per [doc/testing-guidelines.md](../../doc/testing-guidelines.md) §2, the right
fix is to introduce a `SearchViewModel` on Day 6 when `ContentView` ships, and
move the remaining controller logic from `body` into the view model. For now,
smoke-test surfaces are exercised manually in the simulator (you typed
`sesame chicken` and saw the top hit). Day 6 will close the gap with the
ViewModel extraction; the eventual CI gate (MVP1) will then enforce ≥95%.xtField` (R7 D-052 fix for
  keyboard focus on iOS 26 simulator).
- 13 new tests (`ScoreColorTests`: 4 cases; `SearchDishesTests`: 9 cases).
  **Total: 100 tests passing.**
- Live verification: type `sesame chicken` in the iPhone 17 Pro Max simulator and
  the top result is `芝麻鸡 (Sesame Chicken)` rendered sage-green at score 1.21.

## Day 1.6 / Day 2 coverage status

- Models: **100%**
- `DishRepository`: **98.44%**
- `PinyinConverter`: **100%**
- `FuzzyIndex`: **96.18%**
- `FoodieAIApp` smoke view: **97.85%** (needs UI test for full)
- **Overall line coverage: 97.88%** (above 95% target)

## What does NOT work on Day 1 (deferred to later days)

- UI: ContentView, DishCardView, DishListRow, SettingsView
- Fuzzy search
- OCR pipeline (Apple Vision)
- LLM backends (Apple Foundation Models, Qwen via MLX-Swift)
- Camera / photo library
- Error handling for 20+ typed cases

## Known coverage gaps (R9 D-070)

Two files are below the 80% per-file target. Both are acknowledged gaps that
require device-only or simulator-unreachable code to close:

1. **`App/FoodieAIApp.swift` (44.01%)** — SwiftUI view bodies.
   Closed in Day 6 by extracting a `SearchViewModel` + `CardViewModel`.
2. **`LLM/AppleFoundationBackend.swift` (74.07%)** — the 9 FM error-mapping
   branches of `mapAppleFMGenerationError` require constructing a
   `LanguageModelSession.GenerationError`, which iOS 26 simulators cannot
   produce. Closed by testing them on-device in Day 8.

For now, every *code path reachable in the simulator* is covered, and the
data layer / LLM layer files are all at 100% or close.

## Known coverage gaps — Day 4 update (R10 D-082)

Two new gaps joined the list at Day 4:

3. **`Camera/AVCameraService.swift` (5.05%)** — most lines are
   `AVCaptureSession`/`AVCapturePhotoOutput` glue that needs a real
   camera. Closed on-device in Day 8.
4. **`Camera/LibraryPicker.swift` (15.22%)** — the protocol-level
   error tests run; the PHPickerViewController delegate path needs a
   real Photos library. Closed on-device in Day 8.

## What works on Day 4

- `Camera/CameraService.swift` (R10 D-073) — protocol with 7 methods
- `Camera/CameraError.swift` (R10 D-072) — 6 cases incl. `.unavailable`
- `Camera/CameraAuthorizationStatus.swift` (R10 D-071) — 5 cases + userMessage
- `Camera/AVCameraService.swift` (R10 D-078) — AVCaptureSession-backed real impl
- `Camera/CameraServiceMock.swift` (R10 D-074) — 3-init test double
- `Camera/CapturedImageStore.swift` (R10 D-075) — single-slot in-memory + tmp dir
- `Camera/LibraryPicker.swift` (R10 D-076/D-077) — protocol + PHPicker-backed
- `Camera/MenuProcessor.swift` (R10 D-079/D-080) — Day 5 handoff stub
- `Views/CameraPanel.swift` (R10 D-081) — SwiftUI panel mounted under SmokeTestView
- 43 new tests (CameraErrorTests 8, CameraAuthorizationStatusTests 6,
  CameraServiceMockTests 12, LibraryPickerErrorTests 5, CapturedImageStoreTests 6,
  MenuProcessorTests 6) — **Total: 194 tests passing.**

## Day-by-day build progress

See [../../doc/mvp0-plan.md](../../doc/mvp0-plan.md) §9 for the 10-day build order.

| Day | Status | What ships |
|---|---|---|
| 1 | ✅ Done | Data layer + 11 tests passing |
| 1.6 | ✅ Done | Coverage boost to 98.77% (35 new tests) |
| 2 | ✅ Done | FuzzyIndex + PinyinConverter, 40 new tests, coverage 97.88% |
| 3 | ✅ Done | LLM glue (Apple FM backend), 51 new tests, 151 total |
| 4 | ✅ Done | Camera + Library picker + MenuProcessor stub, 43 new tests, 194 total |
| 5 | ⏳ | OCR pipeline (Apple Vision) |
| 6 | ⏳ | UI: ContentView + DishCard + DishListRow |
| 7 | ⏳ | Settings + error handling + polish |
| 8 | ⏳ | Deploy to iPhone 17 Pro Max, test 2 menus |
| 9 | ⏳ | App icon, launch screen, README |
| 10 | ⏳ | MVP0 results doc, Round 6 sign-off |
