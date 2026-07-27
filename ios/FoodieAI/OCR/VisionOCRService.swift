// VisionOCRService.swift
// Day 5 — Apple Vision-backed OCR implementation (R12 D-096).
//
// Wraps `VNRecognizeTextRequest` with `.accurate` level + `.revision3`
// per R6/D-042. The revision3 unlocked iOS 26 features for Vision:
// - per-word bounding boxes (`usesWordBoxes = true`)
// - supports the new hierarchical language detection
// - quieter on `nil` resources (simulator runs it cleanly now)
//
// Per R10/Q5 we never persist the image to disk ourselves; the caller
// passes a `UIImage` and we extract a `CGImage` for the request handler.
// If extraction fails (HEIC with profile issues, PDF, etc.) we throw
// `OCRError.invalidImage`.
//
// The async surface matches `LLMService` and `CameraService`: one call
// in, one (throwing) output. Apple's Vision APIs are callback-based —
// we wire them through `withCheckedThrowingContinuation` (similar to
// CameraServiceMock).

import Foundation
#if canImport(Vision) && canImport(UIKit)
import Vision
import UIKit
#endif

public final class VisionOCRService: OCRService, @unchecked Sendable {
    public let displayLabel: String = "Apple Vision OCR"

    public init() {}

    public func recognize(image: UIImage) async throws -> [OCRLine] {
        #if canImport(Vision) && canImport(UIKit)
        if image.size == .zero { throw OCRError.emptyImage }

        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage(reason: "could not extract CGImage from UIImage")
        }

        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<[OCRLine], Error>) in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    cont.resume(throwing: OCRError.visionFailure(reason: String(describing: error)))
                    return
                }
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    cont.resume(throwing: OCRError.visionFailure(reason: "results not VNRecognizedTextObservation"))
                    return
                }
                let lines: [OCRLine] = observations.map { obs in
                    let text = obs.topCandidates(1).first?.string ?? ""
                    let confidence = Double(obs.confidence)
                    return OCRLine(
                        text: text,
                        confidence: confidence,
                        bbox: obs.boundingBox  // already normalized
                    )
                }
                cont.resume(returning: PriceDetector.classify(lines))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            if #available(iOS 26.0, *) {
                request.revision = VNRecognizeTextRequestRevision3
            } else if #available(iOS 18.0, *) {
                request.revision = VNRecognizeTextRequestRevision2
            }
            request.recognitionLanguages = ["en-US", "en-GB", "zh-Hans", "zh-Hant"]

            do {
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try handler.perform([request])
            } catch {
                cont.resume(throwing: OCRError.visionFailure(reason: String(describing: error)))
            }
        }
        #else
        throw OCRError.underlying(reason: "Apple Vision is not available on this platform")
        #endif
    }
}
