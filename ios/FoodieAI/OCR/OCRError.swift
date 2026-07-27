// OCRError.swift
// Day 5 — Typed errors for the OCR subsystem (R12 D-091).
//
// Pattern mirrors LLMError (R9 D-063) and CameraError (R10 D-072): stable
// enum cases with `errorDescription` and `tag` for the UI layer. Day 7
// will fold OCR + Camera + LLM errors into the unified `FoodieAIError`.

import Foundation

public enum OCRError: Error, LocalizedError, Equatable, Sendable {
    /// The supplied `UIImage` was zero-size or otherwise unusable.
    case emptyImage

    /// Vision recognized the image but found no text (e.g. photo of a wall).
    case noTextFound

    /// Apple's Vision framework returned an error we can't categorize.
    /// Wraps the underlying message so the smoke view can show it.
    case visionFailure(reason: String)

    /// The image source could not be turned into a `CGImage` (PDF page,
    /// HEIC corruption, etc.). Day 7 may move this into `CameraError`.
    case invalidImage(reason: String)

    /// Anything else (VNImageRequestHandler init failure, context overflow,
    /// simulator oddities the unit tests don't cover).
    case underlying(reason: String)

    public var errorDescription: String? {
        switch self {
        case .emptyImage:
            return "OCR input image was empty."
        case .noTextFound:
            return "No text was found in the image."
        case .visionFailure(let reason):
            return "Apple Vision failed. (\(reason))"
        case .invalidImage(let reason):
            return "OCR could not read this image. (\(reason))"
        case .underlying(let reason):
            return "OCR error. (\(reason))"
        }
    }

    public var tag: String {
        switch self {
        case .emptyImage:     return "empty_image"
        case .noTextFound:    return "no_text_found"
        case .visionFailure:  return "vision_failure"
        case .invalidImage:   return "invalid_image"
        case .underlying:     return "underlying"
        }
    }
}
