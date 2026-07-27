// LLMErrorTests.swift
// Day 3 — Unit tests for the 5 typed LLMError cases.
//
// We pin errorDescription, tag, and Equatable conformance so the rest of
// the app can switch on these safely.

import XCTest
@testable import FoodieAI

final class LLMErrorTests: XCTestCase {
    func test_backendUnavailable_has_human_description_and_tag() {
        let e = LLMError.backendUnavailable(reason: "no model")
        XCTAssertEqual(e.tag, "backend_unavailable")
        XCTAssertNotNil(e.errorDescription)
        XCTAssertTrue(e.errorDescription!.contains("language model"),
                      "Description should mention the model")
        XCTAssertTrue(e.errorDescription!.contains("no model"),
                      "Description should include the reason")
    }

    func test_malformedResponse_description_mentions_response() {
        let e = LLMError.malformedResponse(reason: "not JSON")
        XCTAssertEqual(e.tag, "malformed_response")
        XCTAssertEqual(e.errorDescription?.contains("not JSON"), true)
    }

    func test_cancelled_has_no_reason() {
        let e = LLMError.cancelled
        XCTAssertEqual(e.tag, "cancelled")
        XCTAssertNotNil(e.errorDescription)
    }

    func test_refused_description_includes_reason() {
        let e = LLMError.refused(reason: "policy violation")
        XCTAssertEqual(e.tag, "refused")
        XCTAssertEqual(e.errorDescription?.contains("policy violation"), true)
    }

    func test_underlying_description_includes_reason() {
        let e = LLMError.underlying(reason: "simulator crash")
        XCTAssertEqual(e.tag, "underlying")
        XCTAssertEqual(e.errorDescription?.contains("simulator crash"), true)
    }

    func test_equatable_uses_case_and_reason() {
        // Same reason → equal (so retry logic doesn't double-fire).
        XCTAssertEqual(
            LLMError.backendUnavailable(reason: "x"),
            LLMError.backendUnavailable(reason: "x")
        )
        // Different reason → not equal (so the UI can show different text).
        XCTAssertNotEqual(
            LLMError.backendUnavailable(reason: "x"),
            LLMError.backendUnavailable(reason: "y")
        )
        // Different case → not equal.
        XCTAssertNotEqual(
            LLMError.backendUnavailable(reason: "x"),
            LLMError.malformedResponse(reason: "x")
        )
    }

    func test_all_five_cases_have_distinct_tags() {
        let tags = [
            LLMError.backendUnavailable(reason: "").tag,
            LLMError.malformedResponse(reason: "").tag,
            LLMError.cancelled.tag,
            LLMError.refused(reason: "").tag,
            LLMError.underlying(reason: "").tag,
        ]
        XCTAssertEqual(Set(tags).count, 5, "Tags must be unique across the 5 cases")
    }
}
