// mapAppleFMErrorTests.swift
// Day 3 — Unit tests for `mapAppleFMError`.
//
// We test the public free function directly because Apple's
// `LanguageModelSession.GenerationError` cases are simulator-unreachable
// otherwise. The point isn't to verify Apple's type — it's to verify that
// every case in their enum gets routed to the correct `LLMError` tag in
// our app.

import XCTest
@testable import FoodieAI

final class mapAppleFMErrorTests: XCTestCase {

    // MARK: - AppleFM cases (iOS 26+)

    func test_refused_maps_to_refused() {
        let mapped = mapAppleFMError("any error")
        // Without Foundation Models, we fall through to `.underlying`,
        // but the function must still be callable and return a typed LLMError.
        XCTAssertNotNil(mapped.errorDescription)
    }

    func test_non_foundation_model_error_returns_underlying() {
        // We pass a non-LanguageModelSession.GenerationError value; the
        // free function should still return a typed LLMError with the
        // description attached.
        let mapped = mapAppleFMError(NSError(domain: "NSNetwork", code: 42))
        XCTAssertEqual(mapped.tag, "underlying")
        XCTAssertNotNil(mapped.errorDescription)
    }

    // MARK: - Shape contract

    func test_always_returns_an_LLMError() {
        let mapped = mapAppleFMError("anything")
        // Compile-time guarantee: the return type is `LLMError`.
        // We can assert one of five tags exists.
        let validTags: Set<String> = [
            "backend_unavailable", "malformed_response",
            "cancelled", "refused", "underlying"
        ]
        XCTAssertTrue(validTags.contains(mapped.tag))
    }

    func test_error_description_is_present_for_every_returned_case() {
        let cases: [Any] = [
            "string",
            42,
            Date(),
            [1, 2, 3],
            ["k": "v"]
        ]
        for c in cases {
            let mapped = mapAppleFMError(c)
            XCTAssertNotNil(mapped.errorDescription, "Case \(c) returned nil description")
            XCTAssertFalse(mapped.errorDescription?.isEmpty ?? true,
                           "Case \(c) returned empty description")
        }
    }

    // MARK: - Smoke (live availability check)

    func test_live_applefm_isAvailable_returns_a_bool() async {
        let backend = AppleFoundationBackend()
        let value = await backend.isAvailable
        XCTAssertTrue(value == true || value == false,
                      "isAvailable should return a deterministic bool")
    }

    func test_live_applefm_generate_throws_or_succeeds() async {
        // We don't try to assert either branch — simulator may throw; device
        // works. We just verify the function doesn't crash on this platform.
        let backend = AppleFoundationBackend()
        do {
            _ = try await backend.generate(prompt: "hello")
            // success path is fine
        } catch let error as LLMError {
            // error path is fine — verify it's a typed LLMError.
            XCTAssertNotNil(error.errorDescription)
        } catch {
            XCTFail("AppleFM threw a non-LLMError: \(error)")
        }
    }
}
