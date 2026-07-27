// LLMService.swift
// Abstraction over the actual on-device LLM call (Day 3).
//
// The protocol exists so `CardGenerator` and our unit tests never touch a
// concrete backend directly. Swift 6 strict concurrency is enforced — every
// implementing type must be `Sendable` so we can hop across the MainActor
// boundary without ceremony.

import Foundation

/// Free-form prompt sent to the model. Day 7+ may introduce typed prompt
/// structs to catch typos in the template name at compile time.
public typealias LLMPrompt = String

/// Completion contract: one prompt in, one raw string out.
///
/// Implementations MUST throw `LLMError` (never `CancellationError` or
/// `NSError` directly) so the UI layer can switch on the tag.
public protocol LLMService: Sendable {
    /// Human-readable label shown in Settings + logs.
    var displayLabel: String { get }

    /// Whether this backend can run right now. Checked on the main actor
    /// before each `generate`. Implementations that need to do I/O here
    /// (e.g. wait for a model file) should return `false` until ready and
    /// let the caller retry.
    var isAvailable: Bool { get async }

    /// Generate a raw completion. Must throw on any failure.
    func generate(prompt: LLMPrompt) async throws -> String
}
