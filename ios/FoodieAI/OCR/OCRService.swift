// OCRService.swift
// Day 5 — OCR abstraction protocol (R12 D-093).
//
// Pattern mirrors `LLMService` (R9 D-064) and `CameraService` (R10 D-073):
// one method `recognize(image:)`, async-throws, never raw `throws`.
// Implementations:
//
//   - OCRServiceMock    (test double)
//   - VisionOCRService  (real, used in smoke view + Day 8 device test)
//
// Day 6+ may add a remote OCR fallback for "third-party cloud" pricing
// tiers; until then the real impl is the only one.

import Foundation
#if canImport(UIKit)
import UIKit
#endif

public protocol OCRService: Sendable {
    var displayLabel: String { get }

    /// Recognize all lines of text in `image`. Throws `OCRError` on any
    /// failure (no text is not a throw — see `OCRResult` for that case).
    func recognize(image: UIImage) async throws -> [OCRLine]
}
