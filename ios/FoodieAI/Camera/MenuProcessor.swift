// MenuProcessor.swift
// Day 4 — Handoff stub between Camera/Library → OCR pipeline (R10 D-080).
//
// On Day 5 this becomes:
//   1. call Vision OCR → OCRLine[]
//   2. find each dish via FuzzyIndex → Dish[]
//   3. for each novel dish without a card, schedule a CardGenerator
//      job via the LLMService
//
// On Day 4 it just logs "Received menu image" + dimensions + the path
// on disk. The smoke-test view relies on this handoff being a one-call
// interface so it can wire one button directly.

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Result of `process(image:)`. Cases:
///   - `.received(...)`  → Day-4 stub output (kept for backwards compat)
///   - `.parsed(...)`    → Day-5+ output carrying OCR lines + matched Dish[]
///                         + unmatched lines that need an LLM card.
///   - `.errored(reason)` → any unrecoverable failure.
public enum MenuProcessingResult: Equatable, Sendable {
    case received(imageBytes: Int, onDiskPath: String?, modelLabel: String)
    case parsed(
        ocrLines: [OCRLine],
        matchedDishes: [Dish],
        unmatchedLines: [String],
        modelLabel: String
    )
    case errored(reason: String)
}

public protocol MenuProcessor: Sendable {
    var displayLabel: String { get }
    func process(image: UIImage, onDiskPath: String?) async -> MenuProcessingResult
}

/// Day-4 stub: records the call + image dimensions + the path and returns
/// `.received(...)`. Day 5 swaps this out in production for
/// `VisionMenuProcessor`; `StubMenuProcessor` is retained for unit tests
/// and as a fallback when OCR isn't available.
public final class StubMenuProcessor: MenuProcessor, @unchecked Sendable {
    public let displayLabel: String = "MenuProcessor (stub)"

    public private(set) var callCount: Int = 0
    public private(set) var lastImageBytes: Int?

    public init() {}

    public func process(image: UIImage, onDiskPath: String?) async -> MenuProcessingResult {
        callCount += 1
        if image.size == .zero {
            lastImageBytes = 0
            return .errored(reason: "empty image passed to MenuProcessor")
        }
        let w = Int(image.size.width * image.scale)
        let h = Int(image.size.height * image.scale)
        let bytes = w * h * 4
        lastImageBytes = bytes
        return .received(
            imageBytes: bytes,
            onDiskPath: onDiskPath,
            modelLabel: displayLabel
        )
    }
}
