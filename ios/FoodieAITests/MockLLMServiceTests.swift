// MockLLMServiceTests.swift
// Day 3 — Unit tests covering all 3 init overloads of MockLLMService.

import XCTest
@testable import FoodieAI

final class MockLLMServiceTests: XCTestCase {

    func test_scripted_init_returns_completions_in_order() async throws {
        let mock = MockLLMService(scripted: ["first", "second"])
        let a = try await mock.generate(prompt: "p1")
        let b = try await mock.generate(prompt: "p2")
        XCTAssertEqual(a, "first")
        XCTAssertEqual(b, "second")
    }

    func test_scripted_init_throws_when_exhausted() async {
        let mock = MockLLMService(scripted: ["only"])
        _ = try? await mock.generate(prompt: "p1")
        do {
            _ = try await mock.generate(prompt: "p2")
            XCTFail("Expected throw on exhaustion")
        } catch let error as LLMError {
            XCTAssertEqual(error.tag, "underlying")
        } catch {
            XCTFail("Unexpected non-LLMError: \(error)")
        }
    }

    func test_failFirst_init_throws_then_returns() async throws {
        let mock = MockLLMService(
            failFirstWith: .cancelled,
            thenReturn: "ok"
        )
        do {
            _ = try await mock.generate(prompt: "p1")
            XCTFail("Expected throw on first call")
        } catch let error as LLMError {
            XCTAssertEqual(error.tag, "cancelled",
                           "First call should surface injected error")
        } catch {
            XCTFail("Unexpected non-LLMError: \(error)")
        }
        let second = try await mock.generate(prompt: "p2")
        XCTAssertEqual(second, "ok")
    }

    func test_alwaysThrows_init_never_returns() async {
        let mock = MockLLMService(alwaysThrows: .backendUnavailable(reason: "x"))
        do {
            _ = try await mock.generate(prompt: "p1")
            XCTFail("Expected throw")
        } catch let error as LLMError {
            XCTAssertEqual(error.tag, "backend_unavailable")
        } catch {
            XCTFail("Unexpected non-LLMError: \(error)")
        }
        do {
            _ = try await mock.generate(prompt: "p2")
            XCTFail("Expected throw on second call too")
        } catch {
            XCTAssertTrue(true)
        }
    }

    func test_recordedPrompts_captures_each_call() async throws {
        let mock = MockLLMService(scripted: ["x", "y", "z"])
        _ = try await mock.generate(prompt: "alpha")
        _ = try await mock.generate(prompt: "beta")
        _ = try await mock.generate(prompt: "gamma")
        XCTAssertEqual(mock.recordedPrompts, ["alpha", "beta", "gamma"])
        XCTAssertEqual(mock.callCount, 3)
    }

    func test_isAvailable_default_is_true() async {
        let mock = MockLLMService(scripted: [])
        let available = await mock.isAvailable
        XCTAssertTrue(available)
    }

    func test_isAvailable_can_be_disabled() async {
        let mock = MockLLMService(isAvailable: false, scripted: [])
        let available = await mock.isAvailable
        XCTAssertFalse(available)
    }

    func test_displayLabel_is_defaulted() {
        let mock = MockLLMService(scripted: [])
        XCTAssertEqual(mock.displayLabel, "MockLLM")
        let customMock = MockLLMService(displayLabel: "CustomLabel", scripted: [])
        XCTAssertEqual(customMock.displayLabel, "CustomLabel")
    }
}
