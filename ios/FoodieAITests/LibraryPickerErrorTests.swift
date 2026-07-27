// LibraryPickerErrorTests.swift
// Day 4 — Unit tests for the LibraryPickerError enum.

import XCTest
@testable import FoodieAI

final class LibraryPickerErrorTests: XCTestCase {
    func test_cancelled_has_no_reason_in_message() {
        let e = LibraryPickerError.cancelled
        XCTAssertEqual(e.tag, "cancelled")
        XCTAssertNotNil(e.errorDescription)
        XCTAssertTrue(e.errorDescription!.lowercased().contains("cancel"))
    }

    func test_underlying_includes_reason() {
        let e = LibraryPickerError.underlying(reason: "NSItemProvider failure")
        XCTAssertEqual(e.tag, "underlying")
        XCTAssertTrue(e.errorDescription!.contains("NSItemProvider failure"))
    }

    func test_emptyImage_text_is_descriptive() {
        let e = LibraryPickerError.emptyImage
        XCTAssertEqual(e.tag, "empty_image")
        XCTAssertTrue(e.errorDescription!.lowercased().contains("empty"))
    }

    func test_three_cases_have_distinct_tags() {
        let tags = [
            LibraryPickerError.cancelled.tag,
            LibraryPickerError.underlying(reason: "").tag,
            LibraryPickerError.emptyImage.tag,
        ]
        XCTAssertEqual(Set(tags).count, 3)
    }

    func test_equatable_works() {
        XCTAssertEqual(
            LibraryPickerError.underlying(reason: "x"),
            LibraryPickerError.underlying(reason: "x")
        )
        XCTAssertNotEqual(
            LibraryPickerError.underlying(reason: "x"),
            LibraryPickerError.underlying(reason: "y")
        )
    }
}
