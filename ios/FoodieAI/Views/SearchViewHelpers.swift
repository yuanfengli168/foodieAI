// SearchViewHelpers.swift
// Pure functions extracted from the smoke-test view (R7 D-049) so they're
// unit-testable without standing up SwiftUI in a unit test.
//
// Mapping: FuzzyMatch score (0.0–1.0+) → warm-palette Color.
// Thresholds are tuned to the FuzzyIndex scoring bands:
//   ≥0.95  high confidence (exact match, pinyin exact, perfect substring
//           with menu_verified) → sage green
//   ≥0.70  medium confidence (strong substring, edit-distance close) → terracotta
//   ≥0.50  low confidence (over the minConfidentScore floor) → amber
//   <  0.50 below floor — but FuzzyIndex filters those out, so this never hits
//        in practice → secondary (defensive fallback)

import Foundation
import SwiftUI

/// Run a search against the FuzzyIndex for the given query.
/// Thin wrapper extracted from SmokeTestView (R7 D-049) so it's unit-testable
/// outside of SwiftUI. Returns an empty array when the dish list is empty or
/// the query is shorter than `FuzzyIndex.minQueryLength`.
public func searchDishes(_ query: String, in dishes: [Dish]) -> [FuzzyMatch] {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return [] }
    let index = FuzzyIndex(dishes: dishes)
    return index.search(trimmed)
}

/// Convert a FuzzyMatch score (0.0–1.0+) to the warm-palette Color used in
/// the smoke-test view (R7 D-050) and the future production search results.
public func scoreColor(_ score: Double) -> Color {
    if score >= 0.95 { return Color(red: 0x7A/255, green: 0x9A/255, blue: 0x6E/255) }
    if score >= 0.70 { return Color(red: 0xC7/255, green: 0x68/255, blue: 0x3D/255) }
    if score >= 0.50 { return Color(red: 0xC9/255, green: 0xA2/255, blue: 0x27/255) }
    return .secondary
}
