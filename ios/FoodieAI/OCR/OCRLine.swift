// OCRLine.swift
// Day 5 — Per-line text recognition result (R12 D-092).
//
// One `OCRLine` represents a single line Apple Vision recognized in the
// source image. We keep the model small and Codable so it's straightforward
// to serialize for the smoke view or unit-test fixtures.
//
// `bbox` is in normalized image coordinates (0..1), matching the unit
// bounds Vision returns when `request.usesLanguageCorrection = true`.
// We don't convert to UIKit/pixel coordinates here because Day-5 callers
// only need relative positioning to drive the OCR result panel layout.
//
// `isPrice` is filled in by `PriceDetector` after Vision returns. We store
// it on the same struct so downstream code (`VisionMenuProcessor` filters
// price lines out before FuzzyIndex lookup) doesn't need a second pass.

import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

public struct OCRLine: Codable, Equatable, Sendable {
    public let text: String
    public let confidence: Double
    public let bbox: CGRect
    public let isPrice: Bool

    public init(text: String, confidence: Double, bbox: CGRect, isPrice: Bool = false) {
        self.text = text
        self.confidence = confidence
        self.bbox = bbox
        self.isPrice = isPrice
    }

    enum CodingKeys: String, CodingKey {
        case text
        case confidence
        case bboxX, bboxY, bboxW, bboxH
        case isPrice = "is_price"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        text = try c.decode(String.self, forKey: .text)
        confidence = try c.decode(Double.self, forKey: .confidence)
        let x = try c.decode(Double.self, forKey: .bboxX)
        let y = try c.decode(Double.self, forKey: .bboxY)
        let w = try c.decode(Double.self, forKey: .bboxW)
        let h = try c.decode(Double.self, forKey: .bboxH)
        bbox = CGRect(x: x, y: y, width: w, height: h)
        isPrice = try c.decodeIfPresent(Bool.self, forKey: .isPrice) ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(text, forKey: .text)
        try c.encode(confidence, forKey: .confidence)
        try c.encode(Double(bbox.origin.x), forKey: .bboxX)
        try c.encode(Double(bbox.origin.y), forKey: .bboxY)
        try c.encode(Double(bbox.size.width), forKey: .bboxW)
        try c.encode(Double(bbox.size.height), forKey: .bboxH)
        try c.encode(isPrice, forKey: .isPrice)
    }
}
