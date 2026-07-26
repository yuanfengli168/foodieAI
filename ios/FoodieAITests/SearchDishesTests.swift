// SearchDishesTests.swift
// Day 2.5 — Unit tests for the searchDishes() helper extracted from
// SmokeTestView (R7 D-049). Mirrors the smoke-view call path so we can
// verify without SwiftUI: trim → FuzzyIndex.search → results.

import XCTest
@testable import FoodieAI

final class SearchDishesTests: XCTestCase {
    private var repo: DishRepository!

    override func setUpWithError() throws {
        repo = try DishRepository.loadFromBundle()
    }

    func test_exact_english_match_returns_top_hit() {
        let hits = searchDishes("sesame chicken", in: repo.dishes)
        XCTAssertFalse(hits.isEmpty)
        XCTAssertTrue(hits.first?.dish.id.contains("sesame") ?? false,
                      "Expected a sesame dish as the top hit, got \(hits.first?.dish.id ?? "<none>")")
    }

    func test_chinese_substring_match() {
        // 西蓝/西兰/蜜汁 etc are in dish names → ZH substring channel.
        // Use "西兰" which appears in 西兰花炒鸡片 (Chicken with Broccoli).
        let hits = searchDishes("西兰", in: repo.dishes)
        XCTAssertFalse(hits.isEmpty, "Expected substring ZH match, got nothing")
    }

    func test_pinyin_match() {
        // Sesame chicken's pinyin is "zhi ma ji" → fuzzy pinyin channel.
        let hits = searchDishes("zhima ji", in: repo.dishes)
        XCTAssertFalse(hits.isEmpty, "Expected pinyin match, got nothing")
    }

    func test_empty_query_returns_empty() {
        XCTAssertTrue(searchDishes("", in: repo.dishes).isEmpty)
    }

    func test_whitespace_only_query_returns_empty() {
        XCTAssertTrue(searchDishes("   \n  ", in: repo.dishes).isEmpty)
    }

    func test_query_is_trimmed_before_search() {
        // Leading/trailing whitespace should not affect matching.
        let hitsPadded = searchDishes("   sesame chicken   ", in: repo.dishes)
        let hitsClean = searchDishes("sesame chicken", in: repo.dishes)
        XCTAssertEqual(hitsPadded.map(\.dish.id), hitsClean.map(\.dish.id))
    }

    func test_short_query_below_min_returns_empty() {
        // FuzzyIndex.minQueryLength = 2 → single-char queries return nothing.
        let hits = searchDishes("a", in: repo.dishes)
        XCTAssertTrue(hits.isEmpty)
    }

    func test_nonexistent_query_returns_empty() {
        let hits = searchDishes("zzqxnosuchdish", in: repo.dishes)
        XCTAssertTrue(hits.isEmpty)
    }

    func test_empty_dish_list_returns_empty() {
        let hits = searchDishes("sesame", in: [])
        XCTAssertTrue(hits.isEmpty)
    }
}
