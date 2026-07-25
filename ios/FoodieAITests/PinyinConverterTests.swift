// PinyinConverterTests.swift
// Day 2 — tests for the hand-rolled PinyinConverter.

import XCTest
@testable import FoodieAI

final class PinyinConverterTests: XCTestCase {
    var repo: DishRepository!
    var converter: PinyinConverter!

    override func setUpWithError() throws {
        repo = try DishRepository.loadFromBundle()
        converter = PinyinConverter(dishes: repo.dishes)
    }

    func testCountMatchesRepoSize() {
        XCTAssertEqual(converter.count, repo.dishes.count,
            "All 126 dishes have pinyin in MVP0")
    }

    func testPinyinForKnownDishId() {
        let p = converter.pinyin(forDishId: "sesame_chicken")
        XCTAssertEqual(p, "zhi ma ji")
    }

    func testPinyinForUnknownDishIdReturnsNil() {
        XCTAssertNil(converter.pinyin(forDishId: "nonexistent_dish_xyz"))
    }

    func testPinyinForKnownName() {
        // Note: mapo_tofu (麻婆豆腐) is NOT in the 126-dish MVP0 DB.
        // Use a dish that IS in the DB: 芝麻鸡 (sesame chicken) for example.
        let p = converter.pinyin(forName: "芝麻鸡")
        XCTAssertEqual(p, "zhi ma ji")
    }

    func testPinyinForUnknownNameReturnsNil() {
        XCTAssertNil(converter.pinyin(forName: "不存在的菜"))
    }

    func testAllPinyinsAreLowercaseNoTones() throws {
        for p in converter.allPinyins {
            XCTAssertEqual(p, p.lowercased(),
                "Pinyin '\(p)' must be lowercase")
            for ch in p {
                XCTAssertFalse("0123456789".contains(ch),
                    "Pinyin '\(p)' must not contain digits (would imply tone marks weren't stripped)")
            }
        }
    }

    func testAllDishesHavePinyin() {
        // Every dish in the MVP0 DB must have a pinyin
        for d in repo.dishes {
            let p = converter.pinyin(forDishId: d.id)
            XCTAssertNotNil(p, "Dish \(d.id) has no pinyin in the converter")
        }
    }

    func testEmptyDishesProducesEmptyConverter() {
        let empty = PinyinConverter(dishes: [])
        XCTAssertEqual(empty.count, 0)
        XCTAssertTrue(empty.allPinyins.isEmpty)
        XCTAssertNil(empty.pinyin(forDishId: "anything"))
    }

    func testDishesWithEmptyPinyinAreSkipped() {
        let dishWithNoPinyin = Dish(
            id: "no_pinyin_dish",
            nameZh: "测试", nameEn: "Test", pinyin: "",
            aliasesEn: [], aliasesZh: [],
            photoPath: "", emojiFallback: "🍽️",
            source: .wikipedia, sourceUrl: "", isMenuVerified: false,
            intro: "test", flavor: FlavorProfile(spicy: 0, sour: 0, salty: 0, sweet: 0, numbing: 0),
            pairWith: [], region: "x", category: "main", tags: []
        )
        let dishesWithEmpty = repo.dishes + [dishWithNoPinyin]
        let c = PinyinConverter(dishes: dishesWithEmpty)
        // The empty-pinyin dish should not be indexed
        XCTAssertNil(c.pinyin(forDishId: "no_pinyin_dish"))
        XCTAssertNil(c.pinyin(forName: "测试"))
    }
}
