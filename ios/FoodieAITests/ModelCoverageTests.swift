// ModelCoverageTests.swift
// Day 1.5: improve test coverage to ≥95% on the testable code.
// Per doc/testing-guidelines.md §3 (manual verification per function),
// every public function on every model needs a meaningful test.

import XCTest
@testable import FoodieAI

final class CardSourceTests: XCTestCase {
    func testAllCasesHaveTagEmoji() {
        for source in CardSource.allCases {
            XCTAssertFalse(source.tagEmoji.isEmpty,
                "CardSource.\(source.rawValue) must have a non-empty tag emoji")
        }
    }

    func testAllCasesHaveShortLabel() {
        for source in CardSource.allCases {
            XCTAssertFalse(source.shortLabel.isEmpty,
                "CardSource.\(source.rawValue) must have a non-empty short label")
        }
    }

    func testTagEmojisAreDistinctByCategory() {
        // encyclopedia, menu, ai should each have their own emoji
        let encyclopedia: Set<CardSource> = [.wikipedia, .baiduBaike, .wikipediaPlusBaidu]
        let menuEmoji = CardSource.menuVerified.tagEmoji
        let aiEmoji = CardSource.llmOnly.tagEmoji
        let wikiEmoji = CardSource.wikipedia.tagEmoji
        XCTAssertEqual(wikiEmoji, "📖")
        XCTAssertEqual(menuEmoji, "📷")
        XCTAssertEqual(aiEmoji, "🤖")
        for s in encyclopedia { XCTAssertEqual(s.tagEmoji, "📖") }
    }

    func testShortLabelsAreDistinct() {
        let labels = Set(CardSource.allCases.map(\.shortLabel))
        // 5 cases, at least 4 distinct labels (some may share, e.g. wikipedia + baidu_baike are both 'Wikipedia' / '百度百科')
        XCTAssertGreaterThanOrEqual(labels.count, 4)
    }

    func testAllCasesAreCodable() throws {
        for source in CardSource.allCases {
            let data = try JSONEncoder().encode(source)
            let decoded = try JSONDecoder().decode(CardSource.self, from: data)
            XCTAssertEqual(decoded, source)
        }
    }
}

final class LLMBackendTests: XCTestCase {
    func testAllCasesHaveDisplayLabel() {
        for backend in LLMBackend.allCases {
            XCTAssertFalse(backend.displayLabel.isEmpty,
                "LLMBackend.\(backend.rawValue) must have a non-empty display label")
        }
    }

    func testAllCasesHaveSubtitle() {
        for backend in LLMBackend.allCases {
            XCTAssertFalse(backend.subtitle.isEmpty,
                "LLMBackend.\(backend.rawValue) must have a non-empty subtitle")
        }
    }

    func testFallbackPriorityMatchesR6D039() {
        // Apple Foundation Models is primary (priority 0),
        // Qwen 4B is bundled fallback (priority 1),
        // Qwen 3B is thermal fallback (priority 2).
        XCTAssertEqual(LLMBackend.appleFoundation.fallbackPriority, 0)
        XCTAssertEqual(LLMBackend.qwen4b.fallbackPriority, 1)
        XCTAssertEqual(LLMBackend.qwen3b.fallbackPriority, 2)
    }

    func testAllByPriorityIsStable() {
        let first = LLMBackend.allByPriority
        let second = LLMBackend.allByPriority
        XCTAssertEqual(first, second, "allByPriority must be deterministic")
    }

    func testAllCasesAreCodable() throws {
        for backend in LLMBackend.allCases {
            let data = try JSONEncoder().encode(backend)
            let decoded = try JSONDecoder().decode(LLMBackend.self, from: data)
            XCTAssertEqual(decoded, backend)
        }
    }

    func testDisplayLabelsAreDistinct() {
        let labels = Set(LLMBackend.allCases.map(\.displayLabel))
        XCTAssertEqual(labels.count, LLMBackend.allCases.count,
            "Each LLM backend should have a unique display label")
    }
}

final class FlavorProfileTests: XCTestCase {
    func testZeroFlavorProfileIsValid() {
        XCTAssertNil(FlavorProfile.validate(FlavorProfile(spicy: 0, sour: 0, salty: 0, sweet: 0, numbing: 0)))
    }

    func testMaxFlavorProfileIsValid() {
        XCTAssertNil(FlavorProfile.validate(FlavorProfile(spicy: 5, sour: 5, salty: 5, sweet: 5, numbing: 5)))
    }

    func testValidateRejectsOutOfRange() {
        XCTAssertNotNil(FlavorProfile.validate(FlavorProfile(spicy: -1, sour: 0, salty: 0, sweet: 0, numbing: 0)))
        XCTAssertNotNil(FlavorProfile.validate(FlavorProfile(spicy: 6, sour: 0, salty: 0, sweet: 0, numbing: 0)))
        XCTAssertNotNil(FlavorProfile.validate(FlavorProfile(spicy: 0, sour: 99, salty: 0, sweet: 0, numbing: 0)))
    }

    func testAllFieldsAreChecked() {
        // Each field should be independently validated
        for (field, val) in [
            ("spicy", -1), ("sour", 6), ("salty", 100), ("sweet", -5), ("numbing", 10)
        ] {
            let p = FlavorProfile(
                spicy: field == "spicy" ? val : 0,
                sour: field == "sour" ? val : 0,
                salty: field == "salty" ? val : 0,
                sweet: field == "sweet" ? val : 0,
                numbing: field == "numbing" ? val : 0
            )
            XCTAssertNotNil(FlavorProfile.validate(p), "Field \(field) with value \(val) should fail validation")
        }
    }

    func testFlavorProfileIsCodable() throws {
        let p = FlavorProfile(spicy: 3, sour: 1, salty: 2, sweet: 4, numbing: 0)
        let data = try JSONEncoder().encode(p)
        let decoded = try JSONDecoder().decode(FlavorProfile.self, from: data)
        XCTAssertEqual(decoded, p)
    }

    func testFlavorProfileIsHashable() {
        let a = FlavorProfile(spicy: 1, sour: 2, salty: 3, sweet: 4, numbing: 5)
        let b = FlavorProfile(spicy: 1, sour: 2, salty: 3, sweet: 4, numbing: 5)
        XCTAssertEqual(a.hashValue, b.hashValue)
    }
}

final class DishModelTests: XCTestCase {
    func testDisplayNameUsesZhWhenPresent() throws {
        let repo = try DishRepository.loadFromBundle()
        // Find a dish with a non-empty ZH name
        let withZh = try XCTUnwrap(repo.dishes.first { !$0.nameZh.isEmpty })
        XCTAssertEqual(withZh.displayName, withZh.nameZh)
    }

    func testDisplayNameFallsBackToEnWhenZhEmpty() {
        let dish = makeTestDish(nameZh: "", nameEn: "Test Dish")
        XCTAssertEqual(dish.displayName, "Test Dish")
    }

    func testDisplaySubtitleIsEnWhenZhPresent() {
        let dish = makeTestDish(nameZh: "测试菜", nameEn: "Test Dish")
        XCTAssertEqual(dish.displaySubtitle, "Test Dish")
    }

    func testDisplaySubtitleIsEmptyWhenZhEmpty() {
        let dish = makeTestDish(nameZh: "", nameEn: "Test Dish")
        XCTAssertEqual(dish.displaySubtitle, "")
    }

    func testHasPhotoReflectsPhotoPath() {
        XCTAssertTrue(makeTestDish(photoPath: "photos/x.jpg").hasPhoto)
        XCTAssertFalse(makeTestDish(photoPath: "").hasPhoto)
    }

    func testIsAIGeneratedMatchesLlmOnlySource() {
        XCTAssertTrue(makeTestDish(source: .llmOnly).isAIGenerated)
        XCTAssertFalse(makeTestDish(source: .wikipedia).isAIGenerated)
        XCTAssertFalse(makeTestDish(source: .menuVerified).isAIGenerated)
    }

    func testIsAIGeneratedForAllOtherSources() {
        for source in CardSource.allCases where source != .llmOnly {
            XCTAssertFalse(makeTestDish(source: source).isAIGenerated,
                "CardSource.\(source.rawValue) should NOT be flagged as AI-generated")
        }
    }

    // MARK: - Helpers

    private func makeTestDish(
        nameZh: String = "测试",
        nameEn: String = "Test",
        photoPath: String = "photos/test.jpg",
        source: CardSource = .wikipedia
    ) -> Dish {
        Dish(
            id: "test_dish",
            nameZh: nameZh,
            nameEn: nameEn,
            pinyin: "",
            aliasesEn: [],
            aliasesZh: [],
            photoPath: photoPath,
            emojiFallback: "🍽️",
            source: source,
            sourceUrl: "",
            isMenuVerified: false,
            intro: "Test intro.",
            flavor: FlavorProfile(spicy: 0, sour: 0, salty: 0, sweet: 0, numbing: 0),
            pairWith: [],
            region: "Test",
            category: "main",
            tags: []
        )
    }
}
