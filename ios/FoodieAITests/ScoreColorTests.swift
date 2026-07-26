// ScoreColorTests.swift
// Day 2.5 — Unit tests for the scoreColor() helper.
//
// The smoke test view (R7 D-049) and the future production search results
// (Day 6+) both rely on this function to map a FuzzyMatch score to a
// warm-palette Color. We test the boundaries explicitly so a future threshold
// tweak is caught by CI.

import XCTest
import SwiftUI
@testable import FoodieAI

final class ScoreColorTests: XCTestCase {
    // Sage = (0x7A, 0x9A, 0x6E), Terracotta = (0xC7, 0x68, 0x3D),
    // Amber = (0xC9, 0xA2, 0x27), .secondary → sentinel (-1, -1, -1).

    func test_high_score_sage() {
        XCTAssertTrue(scoreColor(1.21) ~= sageTriple)
        XCTAssertTrue(scoreColor(1.00) ~= sageTriple)
        XCTAssertTrue(scoreColor(0.95) ~= sageTriple)
    }

    func test_medium_score_terracotta() {
        XCTAssertTrue(scoreColor(0.94999) ~= terracottaTriple)
        XCTAssertTrue(scoreColor(0.70) ~= terracottaTriple)
        XCTAssertTrue(scoreColor(0.80) ~= terracottaTriple)
    }

    func test_low_score_amber() {
        XCTAssertTrue(scoreColor(0.69999) ~= amberTriple)
        XCTAssertTrue(scoreColor(0.50) ~= amberTriple)
    }

    func test_below_floor_falls_through() {
        // Below 0.50 falls through to the default branch (.secondary).
        // We don't pin the exact color since .secondary is a system style
        // without stable RGBA — we just verify the function doesn't crash
        // and stays consistent across calls.
        let low1 = scoreColor(0.0)
        let low2 = scoreColor(0.49999)
        XCTAssertEqual(low1.colorTriple(), low2.colorTriple(),
                       "All sub-floor scores should map to the same fallback color")
    }
}

// MARK: - Color extraction

private let sageTriple = ColorTriple(r: 0x7A, g: 0x9A, b: 0x6E)
private let terracottaTriple = ColorTriple(r: 0xC7, g: 0x68, b: 0x3D)
private let amberTriple = ColorTriple(r: 0xC9, g: 0xA2, b: 0x27)

private struct ColorTriple: Equatable {
    let r: Int
    let g: Int
    let b: Int
}

private extension Color {
    /// Decode a SwiftUI Color to a ColorTriple on 0–255.
    func colorTriple() -> ColorTriple {
        #if canImport(UIKit)
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return ColorTriple(
            r: Int((r * 255).rounded()),
            g: Int((g * 255).rounded()),
            b: Int((b * 255).rounded())
        )
        #else
        return ColorTriple(r: -1, g: -1, b: -1)
        #endif
    }

    static func ~=(lhs: Color, rhs: ColorTriple) -> Bool {
        lhs.colorTriple() == rhs
    }
}
