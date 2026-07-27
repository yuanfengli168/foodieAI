// CameraErrorTests.swift
// Day 4 — Unit tests for the 6 typed CameraError cases.

import XCTest
@testable import FoodieAI

final class CameraErrorTests: XCTestCase {
    func test_unauthorized_has_human_description_with_reason() {
        let e = CameraError.unauthorized(reason: "denied by user")
        XCTAssertEqual(e.tag, "unauthorized")
        XCTAssertNotNil(e.errorDescription)
        XCTAssertTrue(e.errorDescription!.lowercased().contains("not authorized"))
        XCTAssertTrue(e.errorDescription!.contains("denied by user"))
    }

    func test_invalidSessionState_includes_reason() {
        let e = CameraError.invalidSessionState(reason: "no input")
        XCTAssertEqual(e.tag, "invalid_session_state")
        XCTAssertTrue(e.errorDescription!.contains("no input"))
    }

    func test_underlying_includes_reason() {
        let e = CameraError.underlying(reason: "AV error -50")
        XCTAssertEqual(e.tag, "underlying")
        XCTAssertTrue(e.errorDescription!.contains("AV error -50"))
    }

    func test_cancelled_has_no_reason_in_message() {
        let e = CameraError.cancelled
        XCTAssertEqual(e.tag, "cancelled")
        XCTAssertNotNil(e.errorDescription)
    }

    func test_emptyImage_text_is_descriptive() {
        let e = CameraError.emptyImage
        XCTAssertEqual(e.tag, "empty_image")
        XCTAssertTrue(e.errorDescription!.lowercased().contains("empty"))
    }

    func test_unavailable_includes_reason() {
        let e = CameraError.unavailable(reason: "simulator")
        XCTAssertEqual(e.tag, "unavailable")
        XCTAssertTrue(e.errorDescription!.contains("simulator"))
    }

    func test_all_six_cases_have_distinct_tags() {
        let tags = [
            CameraError.unauthorized(reason: "").tag,
            CameraError.invalidSessionState(reason: "").tag,
            CameraError.underlying(reason: "").tag,
            CameraError.cancelled.tag,
            CameraError.emptyImage.tag,
            CameraError.unavailable(reason: "").tag,
        ]
        XCTAssertEqual(Set(tags).count, 6, "Tags must be unique across the 6 cases")
    }

    func test_equatable_uses_case_and_reason() {
        XCTAssertEqual(
            CameraError.unauthorized(reason: "x"),
            CameraError.unauthorized(reason: "x")
        )
        XCTAssertNotEqual(
            CameraError.unauthorized(reason: "x"),
            CameraError.unauthorized(reason: "y")
        )
        XCTAssertNotEqual(
            CameraError.cancelled,
            CameraError.emptyImage
        )
    }
}
