// MockLLMService.swift
// Test double for `LLMService`. Lives in the main target so other targets
// could in theory use it (Day 7+). For Day 3 it's only consumed by tests.
//
// Behaviour is configured at construction time so each test stays focused:
//   - MockLLMService(scripted:) — return the next string from a fixed list
//   - MockLLMService(throwOnFirstCall:thenReturn:) — fail once, succeed after
//   - MockLLMService(throws:) — always throw

import Foundation

public final class MockLLMService: LLMService, @unchecked Sendable {
    public let displayLabel: String
    public var isAvailable: Bool

    /// Closed-over scripts of completion strings. We pop one per call.
    private let script: Deque<String>

    /// Optional error injected before any scripted response.
    private let injectedError: LLMError?

    /// Append a JSON-shaped result here after each call so tests can assert
    /// prompt + call count.
    public private(set) var recordedPrompts: [String]
    public private(set) var callCount: Int

    public init(
        displayLabel: String = "MockLLM",
        isAvailable: Bool = true,
        scripted completions: [String]
    ) {
        self.displayLabel = displayLabel
        self.isAvailable = isAvailable
        self.script = Deque(initial: completions)
        self.injectedError = nil
        self.recordedPrompts = []
        self.callCount = 0
    }

    public init(
        displayLabel: String = "MockLLM",
        isAvailable: Bool = true,
        failFirstWith error: LLMError,
        thenReturn completion: String
    ) {
        self.displayLabel = displayLabel
        self.isAvailable = isAvailable
        // Wrap as a 2-step script: [error, completion]
        self.script = Deque(initial: [completion])
        self.injectedError = error
        self.recordedPrompts = []
        self.callCount = 0
    }

    public init(
        displayLabel: String = "MockLLM",
        isAvailable: Bool = true,
        alwaysThrows error: LLMError
    ) {
        self.displayLabel = displayLabel
        self.isAvailable = isAvailable
        self.script = Deque(initial: [])
        self.injectedError = error
        self.recordedPrompts = []
        self.callCount = 0
    }

    public func generate(prompt: String) async throws -> String {
        recordedPrompts.append(prompt)
        callCount += 1
        if callCount == 1, let injectedError {
            throw injectedError
        }
        guard let next = script.popFront() else {
            throw LLMError.underlying(reason: "MockLLMService ran out of scripted responses on call \(callCount)")
        }
        return next
    }
}

/// Tiny FIFO so the mock doesn't have to depend on `swift-collections`.
/// Internal to the LLM module — not exported.
final class Deque<Element> {
    private var storage: [Element]
    init(initial: [Element]) { self.storage = initial }
    func popFront() -> Element? {
        storage.isEmpty ? nil : storage.removeFirst()
    }
    var isEmpty: Bool { storage.isEmpty }
    var count: Int { storage.count }
}
