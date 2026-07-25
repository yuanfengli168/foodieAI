# foodieAI — iOS App

> MVP0 status: **Day 1 complete** (data layer + tests passing)
> Last build: 2026-07-26 (iOS 26 simulator, iPhone 17 Pro Max)

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

## What does NOT work on Day 1 (deferred to later days)

- UI: ContentView, DishCardView, DishListRow, SettingsView
- Fuzzy search
- OCR pipeline (Apple Vision)
- LLM backends (Apple Foundation Models, Qwen via MLX-Swift)
- Camera / photo library
- Error handling for 20+ typed cases

## Day-by-day build progress

See [../../doc/mvp0-plan.md](../../doc/mvp0-plan.md) §9 for the 10-day build order.

| Day | Status | What ships |
|---|---|---|
| 1 | ✅ Done | Data layer + 11 tests passing |
| 2 | ⏳ | Fuzzy index + 20 test queries pass |
| 3 | ⏳ | LLM glue (Apple FM + Qwen 4B + 3B) |
| 4 | ⏳ | Camera + photo library + auto-start |
| 5 | ⏳ | OCR pipeline (Apple Vision) |
| 6 | ⏳ | UI: ContentView + DishCard + DishListRow |
| 7 | ⏳ | Settings + error handling + polish |
| 8 | ⏳ | Deploy to iPhone 17 Pro Max, test 2 menus |
| 9 | ⏳ | App icon, launch screen, README |
| 10 | ⏳ | MVP0 results doc, Round 6 sign-off |
