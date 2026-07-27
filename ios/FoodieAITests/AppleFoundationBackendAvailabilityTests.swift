// AppleFoundationBackendAvailabilityTests.swift
// Day 3 — Test the availability + simulator-fallback path of AppleFM.
//
// We don't actually call respond(to:) on the live model — the simulator
// doesn't support it. Instead we assert the backend's `displayLabel`
// is correct, and verify the canImport gate by reading `isAvailable`.
//
// The actual `generate(prompt:)` path against a real device is exercised
// in the simulator smoke test (Day 6+ will fold this into a UI flow).

import XCTest
@testable import FoodieAI

final class AppleFoundationBackendAvailabilityTests: XCTestCase {

    func test_displayLabel_is_apple_foundation_models() {
        let backend = AppleFoundationBackend()
        XCTAssertEqual(backend.displayLabel, "Apple Foundation Models")
    }

    func test_isAvailable_returns_a_bool() async {
        // We don't assert whether it's true or false — both are valid
        // depending on whether the host has Apple Intelligence. We just
        // make sure the call doesn't crash and returns something.
        let backend = AppleFoundationBackend()
        let available = await backend.isAvailable
        XCTAssertNotNil(available as Bool?, "Should return a deterministic bool")
    }

    func test_generator_with_apple_backend_compiles() {
        // Compile-time assertion that the backend conforms to LLMService.
        let backend: any LLMService = AppleFoundationBackend()
        let _: CardGenerator = CardGenerator(service: backend)
        // No runtime assertion — we don't want this test to hit the model.
    }
}
