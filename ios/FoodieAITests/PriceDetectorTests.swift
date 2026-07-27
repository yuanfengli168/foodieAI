// PriceDetectorTests.swift
// Day 5 — Unit tests for the price heuristic (R12 D-102).
//
// We test:
//   - all 5 explicit price patterns ($, €, ¥, ￥, S$, SGD, USD, plain)
//   - rejection of letters (EN/CJK)
//   - rejection of empty strings
//   - the `classify(_:)` helper

import XCTest
import CoreGraphics
@testable import FoodieAI

final class PriceDetectorTests: XCTestCase {
    private func line(_ text: String) -> OCRLine {
        OCRLine(text: text, confidence: 0.9, bbox: .zero)
    }

    func test_dollar_prefixed_is_price() {
        XCTAssertTrue(PriceDetector.isPrice("$12"))
        XCTAssertTrue(PriceDetector.isPrice("$12.50"))
        XCTAssertTrue(PriceDetector.isPrice("$ 12"))
        XCTAssertTrue(PriceDetector.isPrice("$5.99"))
    }

    func test_euro_yen_yuan_is_price() {
        XCTAssertTrue(PriceDetector.isPrice("€10"))
        XCTAssertTrue(PriceDetector.isPrice("¥1200"))
        XCTAssertTrue(PriceDetector.isPrice("￥12.50"))
    }

    func test_SGD_prefixed_is_price() {
        XCTAssertTrue(PriceDetector.isPrice("S$12"))
        XCTAssertTrue(PriceDetector.isPrice("S$ 12.50"))
    }

    func test_SGD_USD_alphabetic_count_as_price_marker() {
        XCTAssertTrue(PriceDetector.isPrice("SGD 12.50"))
        XCTAssertTrue(PriceDetector.isPrice("USD 12"))
    }

    func test_plain_digits_with_or_without_decimals_is_price() {
        XCTAssertTrue(PriceDetector.isPrice("12"))
        XCTAssertTrue(PriceDetector.isPrice("12.50"))
        XCTAssertTrue(PriceDetector.isPrice("0.99"))
    }

    func test_empty_string_is_not_price() {
        XCTAssertFalse(PriceDetector.isPrice(""))
        XCTAssertFalse(PriceDetector.isPrice("   "))
        XCTAssertFalse(PriceDetector.isPrice("\n"))
    }

    func test_lines_with_EN_letters_are_not_price() {
        XCTAssertFalse(PriceDetector.isPrice("sesame chicken"))
        XCTAssertFalse(PriceDetector.isPrice("a"))
        XCTAssertFalse(PriceDetector.isPrice("Combo A"))
        XCTAssertFalse(PriceDetector.isPrice("12a"))
        XCTAssertFalse(PriceDetector.isPrice("12 chicken"))
    }

    func test_lines_with_CJK_letters_are_not_price() {
        XCTAssertFalse(PriceDetector.isPrice("麻婆豆腐"))
        XCTAssertFalse(PriceDetector.isPrice("小笼包"))
        XCTAssertFalse(PriceDetector.isPrice("12元"))
        XCTAssertFalse(PriceDetector.isPrice("甲5"))
    }

    func test_classify_sets_isPrice_correctly_per_line() {
        let lines = [
            line("sesame chicken"),
            line("$12.50"),
            line("EGG"),
            line("12"),
            line("SGD 12"),
        ]
        let classified = PriceDetector.classify(lines)
        XCTAssertEqual(classified.count, 5)
        XCTAssertFalse(classified[0].isPrice, "sesame chicken is a dish")
        XCTAssertTrue(classified[1].isPrice,  "$12.50 is a price")
        XCTAssertFalse(classified[2].isPrice, "EGG is a dish")
        XCTAssertTrue(classified[3].isPrice,  "12 is a price")
        XCTAssertTrue(classified[4].isPrice,  "SGD 12 is a price")
    }

    func test_classify_returns_empty_for_empty_input() {
        XCTAssertTrue(PriceDetector.classify([]).isEmpty)
    }
}
