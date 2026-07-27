// OCRErrorTests.swift
// Day 5 — Unit tests for the 5 typed OCRError cases (R12 D-099).

import XCTest
@testable import FoodieAI

final class OCRErrorTests: XCTestCase {
    func test_emptyImage_description_mentions_image() {
        let e = OCRError.emptyImage
        XCTAssertEqual(e.tag, "empty_image")
        XCTAssertTrue(e.errorDescription!.lowercased().contains("empty"))
    }

    func test_noTextFound_description_mentions_text() {
        let e = OCRError.noTextFound
        XCTAssertEqual(e.tag, "no_text_found")
        XCTAssertTrue(e.errorDescription!.lowercased().contains("text"))
    }

    func test_visionFailure_includes_reason() {
        let e = OCRError.visionFailure(reason: "VN error -50")
        XCTAssertEqual(e.tag, "vision_failure")
        XCTAssertTrue(e.errorDescription!.contains("VN error -50"))
    }

    func test_invalidImage_includes_reason() {
        let e = OCRError.invalidImage(reason: "PDF page unsupported")
        XCTAssertEqual(e.tag, "invalid_image")
        XCTAssertTrue(e.errorDescription!.contains("PDF page"))
    }

    func test_underlying_includes_reason() {
        let e = OCRError.underlying(reason: "context overflow")
        XCTAssertEqual(e.tag, "underlying")
        XCTAssertTrue(e.errorDescription!.contains("context overflow"))
    }

    func test_five_cases_have_distinct_tags() {
        let tags = [
            OCRError.emptyImage.tag,
            OCRError.noTextFound.tag,
            OCRError.visionFailure(reason: "").tag,
            OCRError.invalidImage(reason: "").tag,
            OCRError.underlying(reason: "").tag,
        ]
        XCTAssertEqual(Set(tags).count, 5)
    }

    func test_equatable_uses_case_and_reason() {
        XCTAssertEqual(
            OCRError.visionFailure(reason: "x"),
            OCRError.visionFailure(reason: "x")
        )
        XCTAssertNotEqual(
            OCRError.visionFailure(reason: "x"),
            OCRError.visionFailure(reason: "y")
        )
        XCTAssertNotEqual(
            OCRError.emptyImage,
            OCRError.noTextFound
        )
    }
}
