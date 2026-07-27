// VisionMenuProcessor.swift
// Day 5 — Replaces StubMenuProcessor with the real OCR pipeline (R12 D-097).
//
// Pipeline:
//
//   image → OCRService.recognize → [OCRLine]
//        → PriceDetector.classify → [OCRLine] with `isPrice`
//        → for each non-price line:
//            - FuzzyIndex.search(line) → top Dish? (or nil)
//        → collect matchedDishes + unmatchedLines
//        → return .parsed(...)
//
// On any thrown OCRError we surface it as .errored("ocr: <reason>") so
// the smoke view's red panel can show the underlying message.
//
// Day 5 does NOT actually generate LLM cards for unmatched lines — that
// requires a card-scheduler (Day 7 work) and would add latency to the
// smoke panel. We capture `unmatchedLines` and let the UI surface them.

import Foundation
#if canImport(UIKit)
import UIKit
#endif

public final class VisionMenuProcessor: MenuProcessor, @unchecked Sendable {
    public let displayLabel: String = "VisionMenuProcessor"

    public let ocr: any OCRService
    public let repository: DishRepository
    public let minConfidenceForMatch: Double

    public init(
        ocr: any OCRService,
        repository: DishRepository,
        minConfidenceForMatch: Double = 0.5
    ) {
        self.ocr = ocr
        self.repository = repository
        self.minConfidenceForMatch = minConfidenceForMatch
    }

    public func process(image: UIImage, onDiskPath: String?) async -> MenuProcessingResult {
        if image.size == .zero {
            return .errored(reason: "empty image passed to MenuProcessor")
        }
        do {
            let raw = try await ocr.recognize(image: image)
            // OCRService returns lines already classified if it ran the
            // price detector. Our VisionOCRService does this internally,
            // but if a different OCRService (Day 6+) doesn't, we run it
            // here as a safety net.
            let classified: [OCRLine] = raw.allSatisfy { !$0.isPrice }
                ? PriceDetector.classify(raw)
                : raw
            let (matched, unmatched) = await match(dishLines: classified)
            return .parsed(
                ocrLines: classified,
                matchedDishes: matched,
                unmatchedLines: unmatched,
                modelLabel: displayLabel
            )
        } catch let err as OCRError {
            return .errored(reason: "ocr:\(err.tag) — \(err.errorDescription ?? "<no msg>")")
        } catch {
            return .errored(reason: "ocr: unexpected — \(String(describing: error))")
        }
    }

    // MARK: - Matching

    /// Match each non-price line against the repository's FuzzyIndex.
    /// Returns `(matched, unmatched)` where `matched` is the unique Dish
    /// objects in input order, and `unmatched` is the original text lines
    /// that didn't reach `minConfidenceForMatch`.
    private func match(dishLines: [OCRLine]) async -> ([Dish], [String]) {
        let index = FuzzyIndex(dishes: repository.dishes)
        var matched: [Dish] = []
        var seenIDs = Set<String>()
        var unmatched: [String] = []
        for line in dishLines where !line.isPrice {
            let trimmed = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            let hits = index.search(trimmed)
            if let best = hits.first, best.score >= minConfidenceForMatch {
                if !seenIDs.contains(best.dish.id) {
                    matched.append(best.dish)
                    seenIDs.insert(best.dish.id)
                }
            } else {
                unmatched.append(trimmed)
            }
        }
        return (matched, unmatched)
    }
}
