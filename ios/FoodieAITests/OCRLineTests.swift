// OCRLineTests.swift
// Day 5 — Unit tests for OCRLine Codable round-trip + Equatable (R12 D-100).

import XCTest
import CoreGraphics
@testable import FoodieAI

final class OCRLineTests: XCTestCase {
    func test_init_stores_all_fields() {
        let line = OCRLine(
            text: "sesame chicken",
            confidence: 0.87,
            bbox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.05),
            isPrice: false
        )
        XCTAssertEqual(line.text, "sesame chicken")
        XCTAssertEqual(line.confidence, 0.87)
        XCTAssertEqual(line.bbox.origin.x, 0.1, accuracy: 0.001)
        XCTAssertEqual(line.bbox.size.width, 0.3, accuracy: 0.001)
        XCTAssertFalse(line.isPrice)
    }

    func test_isPrice_defaults_to_false() {
        let line = OCRLine(text: "x", confidence: 0.5, bbox: .zero)
        XCTAssertFalse(line.isPrice)
    }

    func test_codable_round_trip_preserves_fields() throws {
        let original = OCRLine(
            text: "麻婆豆腐",
            confidence: 0.92,
            bbox: CGRect(x: 0.05, y: 0.10, width: 0.5, height: 0.05),
            isPrice: false
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(OCRLine.self, from: data)
        XCTAssertEqual(decoded.text, original.text)
        XCTAssertEqual(decoded.confidence, original.confidence, accuracy: 0.001)
        XCTAssertEqual(decoded.bbox.origin.x, original.bbox.origin.x, accuracy: 0.001)
        XCTAssertEqual(decoded.bbox.size.width, original.bbox.size.width, accuracy: 0.001)
        XCTAssertFalse(decoded.isPrice)
    }

    func test_codable_round_trip_with_isPrice_true() throws {
        let original = OCRLine(text: "$12.50", confidence: 0.99, bbox: .zero, isPrice: true)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(OCRLine.self, from: data)
        XCTAssertTrue(decoded.isPrice)
    }

    func test_equatable_uses_all_fields() {
        let a = OCRLine(text: "x", confidence: 0.5, bbox: .zero)
        let b = OCRLine(text: "x", confidence: 0.5, bbox: .zero)
        XCTAssertEqual(a, b)
        let c = OCRLine(text: "y", confidence: 0.5, bbox: .zero)
        XCTAssertNotEqual(a, c)
    }
}
