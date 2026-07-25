// DishRepositoryTests.swift
// Day 1 unit tests for the data layer.
// Validates that dishes.jsonl loads, parses, and contains the expected 126 cards.

import XCTest
@testable import FoodieAI

final class DishRepositoryTests: XCTestCase {
    func testBundleLoadSucceeds() throws {
        let repo = try DishRepository.loadFromBundle()
        XCTAssertGreaterThan(repo.dishes.count, 0, "dishes.jsonl should not be empty")
    }

    func testLoadsExactly126Dishes() throws {
        let repo = try DishRepository.loadFromBundle()
        XCTAssertEqual(repo.dishes.count, 126,
            "MVP0 data has 126 cards (84 Noodle Gourmet + 42 Zhang Gui)")
    }

    func testAllDishesHaveUniqueIDs() throws {
        let repo = try DishRepository.loadFromBundle()
        let ids = repo.dishes.map(\.id)
        let unique = Set(ids)
        XCTAssertEqual(ids.count, unique.count, "All dish IDs must be unique")
    }

    func testAllDishesHaveValidFlavorProfiles() throws {
        let repo = try DishRepository.loadFromBundle()
        for dish in repo.dishes {
            XCTAssertNil(FlavorProfile.validate(dish.flavor),
                "Dish \(dish.id) has invalid flavor profile")
        }
    }

    func testAllDishesHaveValidCategory() throws {
        let repo = try DishRepository.loadFromBundle()
        let valid: Set<String> = ["main", "side", "soup", "noodle", "rice",
                                   "dessert", "drink", "snack", "breakfast", "dim_sum"]
        for dish in repo.dishes {
            XCTAssertTrue(valid.contains(dish.category),
                "Dish \(dish.id) has invalid category '\(dish.category)'")
        }
    }

    func testAllDishesHaveValidSource() throws {
        let repo = try DishRepository.loadFromBundle()
        let valid: Set<String> = ["wikipedia", "baidu_baike", "wikipedia+baidu",
                                   "menu_verified", "llm_only"]
        for dish in repo.dishes {
            XCTAssertTrue(valid.contains(dish.source.rawValue),
                "Dish \(dish.id) has invalid source '\(dish.source.rawValue)'")
        }
    }

    func testAtLeastOneMenuVerifiedDish() throws {
        let repo = try DishRepository.loadFromBundle()
        let menuVerified = repo.dishes.filter(\.isMenuVerified)
        XCTAssertGreaterThan(menuVerified.count, 0,
            "At least some dishes should be menu_verified (from the 2 menus)")
    }

    func testAllDishesHaveEmojiFallback() throws {
        let repo = try DishRepository.loadFromBundle()
        for dish in repo.dishes {
            XCTAssertFalse(dish.emojiFallback.isEmpty,
                "Dish \(dish.id) must have an emoji fallback (MVP0 photos = emoji only)")
        }
    }

    func testKnownDishHasExpectedFields() throws {
        let repo = try DishRepository.loadFromBundle()
        guard let mapo = repo.dish(byId: "mapo_tofu") else {
            // The MVP0 DB is Noodle Gourmet + Zhang Gui, no mapo_tofu in the 126 cards.
            // Use a known dish from the actual DB instead.
            let sesame = try XCTUnwrap(repo.dish(byId: "sesame_chicken"),
                "Expected a known dish in the 126-card DB")
            XCTAssertEqual(sesame.nameEn, "Sesame Chicken")
            XCTAssertEqual(sesame.flavor.sweet, 5)
            return
        }
        XCTAssertEqual(mapo.nameEn, "Mapo Tofu")
    }

    func testLLMBackendPriorityOrder() {
        XCTAssertEqual(LLMBackend.allByPriority.first, .appleFoundation)
        XCTAssertEqual(LLMBackend.allByPriority.last, .qwen3b)
    }

    func testCardSourceTagsAreCorrect() {
        XCTAssertEqual(CardSource.wikipedia.tagEmoji, "📖")
        XCTAssertEqual(CardSource.menuVerified.tagEmoji, "📷")
        XCTAssertEqual(CardSource.llmOnly.tagEmoji, "🤖")
    }
}
