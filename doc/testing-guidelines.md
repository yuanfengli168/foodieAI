# foodieAI Testing & Documentation Guidelines

> Status: **Locked 2026-07-26 (Round 6, Jacky)**
> Owner: All contributors (currently just Jacky + AI)
> Applies to: All code in `ios/FoodieAI/`, `ios/FoodieAITests/`, and any future modules
> Enforcement: Manual review of every PR + the AI agent's per-function checklist

---

## The 3 rules (locked)

1. **≥95% test coverage** — every meaningful code path has a test. CI must fail if coverage drops below 95%.
2. **Manual verification of every function** — not "the test passed" but "I read the test and confirmed it actually tests the behavior I care about."
3. **Update specific stale docs after verified success** — a clear checklist of which docs must be touched when behavior changes.

---

## 1. Coverage: how we measure and enforce

### Tool
**Xcode's built-in code coverage** (no extra tools).

Configured in `ios/project.yml`:
```yaml
settings:
  base:
    CLANG_ENABLE_CODE_COVERAGE: YES
    GCC_GENERATE_TEST_COVERAGE_FILES: YES
```

### How to view locally
```bash
cd ios
xcodebuild -project FoodieAI.xcodeproj -scheme FoodieAI \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -configuration Debug \
  -enableCodeCoverage YES test
```

Then in Xcode: **Report Navigator** → select the latest test run → **Coverage** tab. Shows per-file and per-function coverage.

### Pass criterion
- **Overall line coverage ≥95%** for the `FoodieAI` target
- **Per-file: aim for ≥80%** (some files — e.g. `ContentView.swift` until UI lands — will be lower, that's fine as long as overall is ≥95%)

### When a file is below 80%
- **Don't exclude it.** Refactor to make it testable. See §2 below.

---

## 2. When 95% is "impossible" — refactor, don't exclude

**Default policy**: if a function is hard to test, the function (or its caller) is poorly designed. Introduce a protocol + mock implementation to make it testable.

### Patterns we use

| Hard-to-test thing | Fix |
|---|---|
| `OCRService.recognize(image:)` calls Apple Vision (real device-only) | Introduce `OCRServiceProtocol`; tests use a `MockOCRService` that returns canned observations |
| `LLMService.generateCard(...)` calls Apple Foundation Models (real device-only, large model) | Introduce `LLMServiceProtocol`; tests use a `MockLLMService` returning canned JSON |
| `CameraService.capturePhoto()` needs a real camera | Inject `CameraServiceProtocol`; tests use a mock that returns a `UIImage` |
| `Date()` calls (time-dependent code) | Inject a `Clock` protocol with a mock that returns fixed dates |
| `UUID()` calls (random IDs) | Inject an `IDGenerator` protocol |
| `FileManager` operations | Inject a `FileSystem` protocol with an in-memory implementation |
| Network calls (post-MVP2) | Inject an `HTTPClient` protocol |

### When refactor is genuinely impossible
- `@main` struct entry point (App.swift) — untestable by definition, low line count, OK to skip
- SwiftUI view bodies that depend on `@State` of complex types — refactor to use a ViewModel that's testable in isolation
- **Truly untestable**: nothing else. If you find yourself wanting to exclude, refactor instead.

### The one-line test
> "If I delete this function, do my tests catch the bug?"
> If no → refactor.
> If yes → coverage is good.

---

## 3. Manual verification of every function

**Definition**: "the test passed" is necessary but not sufficient. For every function added or modified, the author must:

1. **Read each test** that covers the function. Confirm it actually tests the behavior claimed by the function's name + docstring.
2. **Run the test 3 times** in a row. A flaky test is a bug, not noise.
3. **Try the negative case**: what does the function do with empty input, nil, invalid types, boundary values? There should be a test for each.
4. **Try the happy path** with realistic data (not just `x = 1, y = 1, expect 2`).
5. **Verify the test name describes the behavior** (e.g. `testFuzzyIndexReturnsTopMatchForExactQuery`, not `testFuzzy1`).

### The manual checklist (used after every code change)

```markdown
For function `fooBar(x:)`:
- [ ] Tests exist for: happy path, empty input, nil, boundary, invalid type
- [ ] Test names describe behavior, not implementation
- [ ] All tests pass 3x in a row
- [ ] Coverage for this file: ___% (target ≥80%)
- [ ] No flakiness observed
- [ ] Doc comments match what the function actually does
```

If any checkbox fails, do not commit. Fix the test or the code.

---

## 4. The "stale docs" checklist (specific names)

When a function or behavior changes, these docs **must** be updated in the same commit:

| Doc | When to update |
|---|---|
| **Code docstring** (Swift `///`) | Always — when the function signature OR behavior changes |
| **API README in the same folder** | When a public type or function is added/renamed/removed |
| **`ios/FoodieAI/Resources/Data/README.md`** | When the day-by-day progress table changes (a day ships, a day is revisited) |
| **`doc/mvp0-plan.md`** | When scope, scope table, build order, or schema changes |
| **`doc/model-comparison.md`** | When LLM model choice, priority, or comparison changes |
| **`doc/data-sourcing.md`** | When dish card schema or authoring rules change |
| **`doc/feedback-log.md`** | When a Round produces new decisions (D-XXX) or new questions (Q-XXX) |
| **`doc/TODO.md`** | When a polish item is completed, deferred, or discovered |
| **`doc/ui-design-brief.md`** | When colors, typography, layout, or interaction change |
| **`doc/ocr-benchmark-plan.md`** | When OCR strategy, revision, or benchmark plan changes |
| **`doc/fuzzy-search-tests.md`** | When fuzzy test queries are added/removed/modified |
| **`doc/mvp0-data-results.md`** | When the dish DB changes (additions, removals, or schema changes) |

### The 30-second staleness check

Before committing, run:
```bash
git diff --name-only HEAD
```

For each file changed, ask: "Is this change reflected in any of the docs above?" If yes but the doc isn't in the diff, update the doc.

---

## 5. CI gate (planned for MVP1, not MVP0)

**MVP0**: Manual coverage check + manual verification (per §1 and §3).
**MVP1**: GitHub Actions workflow that:
1. Runs `xcodebuild test` with coverage
2. Parses the `xcresult` bundle
3. Fails if overall coverage < 95% OR any single file < 60% (grace threshold while UI is being built)
4. Posts the coverage delta as a PR comment

For MVP0, the AI agent runs the manual checklist at the end of every commit. We trust the process, not automation.

---

## 6. Examples (the right way vs the wrong way)

### ❌ Wrong: a test that "passes" but doesn't test anything

```swift
func testDishExists() {
    let dish = Dish(id: "x", nameZh: "x", nameEn: "x", pinyin: "x", ...)
    XCTAssertNotNil(dish)  // tautology — a constructed object is never nil
}
```

**Why this is bad**: passes 100% of the time, doesn't test any real behavior. The 95% rule forces you to write meaningful tests.

### ✅ Right: a test that actually validates behavior

```swift
func testFuzzyIndexReturnsTopMatchForExactQuery() throws {
    let repo = try DishRepository.loadFromBundle()
    let index = FuzzyIndex(dishes: repo.dishes)
    let results = index.search("Mapo Tofu")
    // Note: 126-dish MVP0 DB doesn't have mapo_tofu; use a known dish instead
    let top = try XCTUnwrap(results.first)
    XCTAssertGreaterThan(top.score, 0.95,
        "Exact-match query should score > 0.95; got \(top.score)")
}
```

**Why this is good**: name describes behavior, test will fail if the behavior breaks, asserts a specific quality bar.

### ❌ Wrong: excluding a function from coverage

```swift
// In a coverage report, "Excluded" appears here. Reasoning below.
func fatalError_onInvalidState() {
    fatalError("This should never happen")
}
```

**Why this is bad**: if it "should never happen", write a test that asserts the function never gets called with that state. The "should never happen" comment is a hint that the surrounding code needs a state machine.

### ✅ Right: refactor + test

```swift
enum AppState {
    case loading
    case ready
    case error(Error)
}

func transition(from current: AppState, to next: AppState) throws {
    guard isValid(transition: (current, next)) else {
        throw AppStateError.invalidTransition(from: current, to: next)
    }
}

func testInvalidTransitionThrows() {
    XCTAssertThrowsError(try transition(from: .ready, to: .loading))
    XCTAssertNoThrow(try transition(from: .loading, to: .ready))
}
```

**Why this is good**: now `transition()` is a pure function, no `fatalError`, fully testable, and the "invalid transition" path is exercised in tests.

---

## 7. Where we are today (2026-07-26, Day 2)

| Component | Tests | Line coverage | Status |
|---|---|---|---|
| `Dish.swift` (Codable model) | 11 tests (valid flavor/category/source, known dish, displayName/Subtitle, hasPhoto, isAIGenerated) | **100%** | ✅ |
| `FlavorProfile.swift` (model + validate) | 7 tests (zero, max, out-of-range, all fields, codable, hashable) | **100%** | ✅ |
| `CardSource.swift` (enum) | 6 tests (tag emoji, short label, distinctness, codable) | **100%** | ✅ |
| `LLMBackend.swift` (enum) | 7 tests (display label, subtitle, priority, distinctness, codable) | **100%** | ✅ |
| `DishRepository.swift` (loader) | 15 tests (bundle load, 126 dishes, unique IDs, matching, errors, bad data) | **98.44%** | ✅ |
| `PinyinConverter.swift` (Day 2) | 9 tests (count, id/name lookup, lowercase no tones, all dishes have pinyin, empty dishes, empty pinyin skipped) | **100%** | ✅ |
| `FuzzyIndex.swift` (Day 2) | 31 tests (exact EN/ZH, substring, pinyin, typo, edge cases, sorting, levenshtein, normalize) | **96.18%** | ✅ |
| `FoodieAIApp.swift` (smoke view) | 0 tests (loading state hard to test in XCTest) | 97.85% | ⚠️ full coverage needs UI test (Day 6) |
| **Overall** | **87/87 passing** | **97.88%** | ✅ above 95% threshold |
| `Views/SearchViewHelpers.swift` (Day 2.5) | 13 tests: 4 `ScoreColorTests`, 9 `SearchDishesTests` | **100%** | ✅ |
| `App/FoodieAIApp.swift` (Day 2.5, after D-055/#if DEBUG + D-056 helper extraction) | 0 unit tests; manual smoke test in simulator | **44.01%** | ⚠️ gap acknowledged — see **Day 2.5** below |
| **Overall (Day 2.5)** | **100/100 passing** | **67.58%** | ⚠️ below 95% — see **Day 2.5** below |

**Day 2 progress**:
- Added `PinyinConverter.swift` (100% coverage) — hand-rolled pinyin table for the 126 dishes
- Added `FuzzyIndex.swift` (96.18% coverage) — 4-channel search with scoring + tiebreaks
- Added 40 new tests across 3 new test classes (FuzzyIndexTests, PinyinConverterTests)
- Coverage held above 95% (97.88% overall)

**Day 2.5 — coverage gap acknowledged (R8 D-057)**:

After wrapping `SmokeTestView` under `#if DEBUG` and adding `ProductionPlaceholder`
(R8 D-055), plus extracting the logic to `Views/SearchViewHelpers.swift` (R8 D-056),
overall coverage dropped from 97.88% to 67.58%. The reason: the SwiftUI view bodies
in `FoodieAIApp.swift` (SmokeTestView's `body`, ProductionPlaceholder's `body`,
SearchField's make/update/dismiss) aren't reachable from XCTest because SwiftUI
treats `body` as non-callable in unit tests (`body() should not be called on
ModifiedContent<...>` if you try).

**Plan to close the gap (Day 6)**:
1. Introduce `SearchViewModel: ObservableObject` and move the user-facing state
   out of the view's `@State` (`query`, `results`, `repository`)
2. Add a `ViewModel.search(_:)` method that wraps `searchDishes(_:in:)` plus
   future OCR/LLM calls
3. Test the ViewModel directly via XCTest — no SwiftUI needed
4. Drop coverage on `FoodieAIApp.swift` to just the `@main` Scene entry; expect
   ≥95% overall once ViewModel lands

**Why we accepted the gap now** (rather than refactoring before Day 6):
- The smoke-test view is replaced wholesale on Day 6 with the real `ContentView`
- Day 6 will ship the right pattern (ViewModel) once we know what state the
  production view actually needs
- §2 says "refactor, don't exclude": extracting `searchDishes` and `scoreColor`
  to a 100%-covered `SearchViewHelpers.swift` is the refactor we *can* do today;
  the ViewModel extraction requires the production UI skeleton, which is Day 6.

**How to reproduce these numbers**:
```bash
cd ios
xcodegen generate
xcodebuild -project FoodieAI.xcodeproj -scheme FoodieAI \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -configuration Debug -enableCodeCoverage YES \
  -resultBundlePath /tmp/foodieai-test.xcresult test

PROFDATA=$(find ~/Library/Developer/Xcode/DerivedData -name "Coverage.profdata" 2>/dev/null | head -1)
DYLIB=$(find ~/Library/Developer/Xcode/DerivedData -name "FoodieAI.debug.dylib" 2>/dev/null | head -1)
xcrun llvm-cov report "$DYLIB" -instr-profile "$PROFDATA"
```

---

## 8. Test categories (what we test at each level)

| Level | What it tests | Tools |
|---|---|---|
| **Unit** | Pure functions, models, parsers | XCTest |
| **Integration** | Repository + index, OCR + fuzzy, LLM + parser | XCTest with real bundles, mock LLM/OCR |
| **UI** (Day 6+) | View rendering, button taps, navigation | XCTest UI testing (XCUITest) |
| **End-to-end** (Day 8+) | Full pipeline on iPhone 17 Pro Max with the 2 menus | Manual walkthrough per `mvp0-data-results.md` |

---

## 9. CI / local commands (cheat sheet)

```bash
# From /Users/jackyli/Desktop/Githubs/foodieAI/ios/

# 1. Regenerate Xcode project (after editing project.yml or adding files)
xcodegen generate

# 2. Run all unit tests with coverage
xcodebuild -project FoodieAI.xcodeproj -scheme FoodieAI \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -configuration Debug \
  -enableCodeCoverage YES test

# 3. View coverage in Xcode
open FoodieAI.xcodeproj
# then: Report Navigator -> latest test run -> Coverage tab

# 4. Check that the resource is still bundled (sanity check after data updates)
find ~/Library/Developer/Xcode/DerivedData -name "FoodieAI.app" -type d 2>/dev/null \
  | head -1 | xargs -I{} ls {} | grep jsonl
# expected: dishes.jsonl
```

---

## 10. The "definition of done" for a Day in MVP0

A day is "done" when:

- [ ] All planned Swift files are written and compile
- [ ] New code has unit tests at the function level
- [ ] New tests pass 3x in a row
- [ ] Manual verification checklist (§3) signed off for every new function
- [ ] Overall coverage ≥95% (or specific written exception)
- [ ] Affected docs updated (per §4)
- [ ] Day entry in `ios/FoodieAI/Resources/Data/README.md` marked ✅
- [ ] Commit message references the day number
- [ ] Pushed to `origin/main`

If any item fails, the day is not done. Fix and re-verify.

---

## 11. Future-facing (post-MVP0)

When we move to MVP1+:

- **GitHub Actions CI** on every push + PR (replaces manual `xcodebuild test`)
- **Codecov.io** (or Coveralls) for historical coverage tracking
- **Snapshot tests** for SwiftUI views (`swift-snapshot-testing`)
- **Performance tests** (XCTest `measure {}`) for the fuzzy index and OCR pipeline
- **Fuzz tests** (Swift `libFuzzer` integration) for the JSONL parser
- **TestFlight beta** for real-user feedback on a wider range of menus

These are all nice-to-haves. MVP0 ships with manual coverage check + the checklist in §3.

---

## 12. Open questions for future you (post-MVP0)

1. Should we move the testing-guidelines into a `CONTRIBUTING.md` at the repo root so it's discoverable?
2. Should the 95% threshold be stricter for shared/utility code and looser for one-off view code?
3. Should we add pre-commit hooks (e.g. SwiftLint, swift-format) to enforce style?
4. Should we add a "test the tests" meta-check — randomly delete a test and verify coverage drops, proving the test is meaningful?

These don't block MVP0 but should be considered for MVP1.
