// CardGeneratorTests.swift
// Day 3 — Unit tests for the orchestrator that wires `LLMService` →
// `PromptTemplates` → `CardJSONDecoder`.
//
// Pipeline under test (R8 D-058):
//   - First try: lax prompt. If JSON parses, return.
//   - Retry once with stricter prompt if first response fails to parse.
//   - After 2 attempts, throw `.malformedResponse`.

import XCTest
@testable import FoodieAI

final class CardGeneratorTests: XCTestCase {

    // MARK: Happy path

    func test_succeeds_first_try_with_valid_json() async throws {
        let mock = MockLLMService(scripted: [
            #"{"name_zh":"芝麻鸡","name_en":"Sesame Chicken","intro_en":"A sweet takeout classic."}"#
        ])
        let generator = CardGenerator(service: mock)
        let dish = try Dish(
            id: "sesame_chicken",
            nameZh: "芝麻鸡",
            nameEn: "Sesame Chicken",
            pinyin: "zhi ma ji",
            aliasesEn: [], aliasesZh: [],
            photoPath: "",
            emojiFallback: "🍗",
            source: .menuVerified,
            sourceUrl: "",
            isMenuVerified: true,
            intro: "stub",
            flavor: FlavorProfile(spicy: 0, sour: 1, salty: 2, sweet: 5, numbing: 0),
            pairWith: [],
            region: "American-Chinese",
            category: "main",
            tags: []
        )

        let draft = try await generator.generate(for: dish, query: "sesame chicken")

        XCTAssertEqual(mock.callCount, 1, "Should have succeeded on attempt 1")
        XCTAssertEqual(draft.nameZh, "芝麻鸡")
        XCTAssertEqual(draft.nameEn, "Sesame Chicken")
        XCTAssertEqual(draft.introEn, "A sweet takeout classic.")
    }

    func test_recovers_on_garbled_then_valid() async throws {
        // First response is JSON-but-missing-intro_en (malformed).
        // Second response is valid JSON.
        let mock = MockLLMService(scripted: [
            #"{"name_en":"Sesame Chicken"}"#, // attempt 1: missing intro_en
            #"{"intro_en":"Sweet, sticky, fried chicken."}"# // attempt 2: valid
        ])
        let generator = CardGenerator(service: mock)
        let dish = try sampleDish()

        let draft = try await generator.generate(for: dish, query: "sesame")

        XCTAssertEqual(mock.callCount, 2, "Should retry exactly once after a malformed response")
        XCTAssertEqual(draft.introEn, "Sweet, sticky, fried chicken.")
        // First prompt should be systemFirst, second systemRetry.
        XCTAssertTrue(mock.recordedPrompts[0].contains(PromptTemplates.systemFirst))
        XCTAssertTrue(mock.recordedPrompts[1].contains(PromptTemplates.systemRetry))
    }

    // MARK: Error paths

    func test_throws_malformed_when_both_attempts_invalid() async throws {
        let mock = MockLLMService(scripted: [
            "Sure, here you go: a description that isn't JSON.",
            "Also not JSON at all, just prose."
        ])
        let generator = CardGenerator(service: mock)
        let dish = try sampleDish()

        do {
            _ = try await generator.generate(for: dish, query: "x")
            XCTFail("Should have thrown")
        } catch let error as LLMError {
            XCTAssertEqual(error.tag, "malformed_response")
            if case .malformedResponse(let reason) = error {
                XCTAssertTrue(reason.contains("after 2 attempts"))
            } else {
                XCTFail("Wrong case: \(error)")
            }
        }
        XCTAssertEqual(mock.callCount, 2, "Should attempt exactly twice")
    }

    func test_throws_cancelled_without_retry() async throws {
        let mock = MockLLMService(alwaysThrows: .cancelled)
        let generator = CardGenerator(service: mock)
        let dish = try sampleDish()

        do {
            _ = try await generator.generate(for: dish, query: "x")
            XCTFail("Expected throw")
        } catch let error as LLMError {
            XCTAssertEqual(error.tag, "cancelled",
                           "Cancellation should be surfaced as-is, not retried")
        }
        XCTAssertEqual(mock.callCount, 1, "Should NOT retry after cancellation")
    }

    func test_throws_refused_without_retry() async throws {
        let mock = MockLLMService(alwaysThrows: .refused(reason: "policy"))
        let generator = CardGenerator(service: mock)
        let dish = try sampleDish()

        do {
            _ = try await generator.generate(for: dish, query: "x")
            XCTFail("Expected throw")
        } catch let error as LLMError {
            XCTAssertEqual(error.tag, "refused",
                           "Refusal should be surfaced as-is, not retried")
        }
        XCTAssertEqual(mock.callCount, 1)
    }

    func test_throws_backendUnavailable_without_retry() async throws {
        let mock = MockLLMService(alwaysThrows: .backendUnavailable(reason: "simulator"))
        let generator = CardGenerator(service: mock)
        let dish = try sampleDish()

        do {
            _ = try await generator.generate(for: dish, query: "x")
            XCTFail("Expected throw")
        } catch let error as LLMError {
            XCTAssertEqual(error.tag, "backend_unavailable")
        }
        XCTAssertEqual(mock.callCount, 1)
    }

    // MARK: Availability gating

    func test_throws_backendUnavailable_when_service_reports_unavailable() async throws {
        // Mock returns isAvailable=false → no LLM call.
        let mock = AlwaysUnavailableMockLLM()
        let generator = CardGenerator(service: mock)
        let dish = try sampleDish()

        do {
            _ = try await generator.generate(for: dish, query: "x")
            XCTFail("Expected throw")
        } catch let error as LLMError {
            XCTAssertEqual(error.tag, "backend_unavailable")
        }
        XCTAssertEqual(mock.callCount, 0,
                       "Should not hit the model at all when isAvailable=false")
    }

    // MARK: Helpers

    private func sampleDish() throws -> Dish {
        try Dish(
            id: "sesame_chicken",
            nameZh: "芝麻鸡",
            nameEn: "Sesame Chicken",
            pinyin: "zhi ma ji",
            aliasesEn: [], aliasesZh: [],
            photoPath: "",
            emojiFallback: "🍗",
            source: .menuVerified,
            sourceUrl: "",
            isMenuVerified: true,
            intro: "stub",
            flavor: FlavorProfile(spicy: 0, sour: 1, salty: 2, sweet: 5, numbing: 0),
            pairWith: [],
            region: "American-Chinese",
            category: "main",
            tags: []
        )
    }
}

/// Mock that reports isAvailable=false to test the availability gating path.
private final class AlwaysUnavailableMockLLM: LLMService, @unchecked Sendable {
    let displayLabel: String = "AlwaysUnavailable"
    var isAvailable: Bool { get async { false } }
    private(set) var callCount: Int = 0
    func generate(prompt: String) async throws -> String {
        callCount += 1
        return "{}"
    }
}
