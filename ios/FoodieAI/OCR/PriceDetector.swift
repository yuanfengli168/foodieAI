// PriceDetector.swift
// Day 5 — Per-line price heuristic (R12 D-095).
//
// Rules (in order):
//   1. Strip whitespace.
//   2. If empty → not a price.
//   3. If the line contains any letter (EN or CJK) → NOT a price (menu items
//      usually contain at least one dish-name letter).
//   4. Otherwise: must match one of:
//        - starts with `$` followed by a number, e.g. "$12", "$12.50"
//        - is just digits with an optional `.dd` tail, e.g. "12", "12.50"
//        - contains a decimal point: "12.50", "12.5"
//   5. Currency-marked variants also count: "S$12" (Singapore), "SGD 12.50",
//      "￥12" (CNY), "¥1200" (JPY), "€10" (EUR).
//
// We deliberately do NOT consult the surrounding lines (a 1-letter suffix
// like "M" or "K" stays in the dish bucket). Heuristics that try to be too
// clever about context tend to over-classify dishes as prices.

import Foundation

public enum PriceDetector {
    /// Returns true if `line.text` looks like a price line.
    public static func isPrice(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return false }

        // Try currency/symbol prefixes, longest first, then trim them
        // off. After we've consumed the prefix the remainder must be a
        // plain number ("12", "12.50") or empty (for placeholder rows).
        let prefixes = ["S$", "SGD", "USD", "CNY", "HK$", "RMB", "$", "€", "¥", "￥"]
        var consumed = ""
        for p in prefixes {
            if trimmed.hasPrefix(p) {
                consumed = p
                break
            }
        }
        let remainder = trimmed
            .dropFirst(consumed.count)
            .trimmingCharacters(in: .whitespaces)

        // Reject anything in the remainder that contains a letter (EN or CJK).
        // "$12a" or "12元" are not menu prices.
        for scalar in remainder.unicodeScalars {
            let v = scalar.value
            if (v >= 0x41 && v <= 0x5A) || (v >= 0x61 && v <= 0x7A) ||
                (v >= 0x4E00 && v <= 0x9FFF) ||
                (v >= 0x3040 && v <= 0x309F) ||
                (v >= 0x30A0 && v <= 0x30FF) ||
                (v >= 0xAC00 && v <= 0xD7AF) {
                return false
            }
        }

        // Plain shape check: optional digit grouping + optional .dd.
        let plainNumber = /^\d+(\.\d{1,2})?$/
        if remainder.contains(plainNumber) {
            return true
        }
        // Marker-only case: "$" by itself is acceptable as a placeholder.
        if !consumed.isEmpty && remainder.isEmpty {
            return true
        }
        // No prefix and pure digits works (already covered by plainNumber).
        return false
    }

    /// Apply the heuristic to a vector of lines, returning the same array
    /// with each line's `isPrice` flag set.
    public static func classify(_ lines: [OCRLine]) -> [OCRLine] {
        return lines.map { line in
            var copy = line
            // Swift value-type instances can't mutate their stored props
            // directly in a map closure without the "var copy" trick.
            // OCRLine is a value type and not a var-let here; we rebuild
            // it below.
            let detected = isPrice(line.text)
            return OCRLine(
                text: line.text,
                confidence: line.confidence,
                bbox: line.bbox,
                isPrice: detected
            )
        }
    }
}
