// CameraAuthorizationStatusTests.swift
// Day 4 — Unit tests for CameraAuthorizationStatus enum + userMessage.

import XCTest
@testable import FoodieAI

final class CameraAuthorizationStatusTests: XCTestCase {
    func test_authorized_userMessage_says_granted() {
        let msg = CameraAuthorizationStatus.authorized.userMessage
        XCTAssertTrue(msg.lowercased().contains("granted"))
    }

    func test_denied_userMessage_redirects_to_settings() {
        let msg = CameraAuthorizationStatus.denied.userMessage
        XCTAssertTrue(msg.lowercased().contains("settings"))
    }

    func test_restricted_userMessage_mentions_policy() {
        let msg = CameraAuthorizationStatus.restricted.userMessage
        XCTAssertTrue(msg.lowercased().contains("policy"))
    }

    func test_unavailable_userMessage_mentions_device() {
        let msg = CameraAuthorizationStatus.unavailable.userMessage
        XCTAssertTrue(msg.lowercased().contains("device"))
    }

    func test_notDetermined_userMessage_mentions_prompt() {
        let msg = CameraAuthorizationStatus.notDetermined.userMessage
        XCTAssertTrue(msg.lowercased().contains("ask"))
    }

    func test_sendable_equatable_for_all_five_cases() {
        // All five cases are distinct and hashable as values.
        let all: Set<CameraAuthorizationStatus> = [
            .notDetermined, .authorized, .denied, .restricted, .unavailable
        ]
        XCTAssertEqual(all.count, 5)
    }
}
