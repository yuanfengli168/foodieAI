// LibraryPicker.swift
// Day 4 — Photo-library picker (PHPicker) protocol (R10 D-076).
//
// Per Q4, we use PHPicker — modern, no permission needed for read.
// The protocol exists so the rest of Day 4's wiring doesn't depend
// on UIKit/PHPicker directly (mocks just return a bundled image).
//
// Lifecycle:
//   1. caller invokes `pickImage()` which presents the system picker UI
//   2. user picks an image → returns `UIImage`
//   3. user cancels → returns `nil` AND throws no error
//   4. system rejects (rare) → throws `LibraryPickerError`
//
// We do not include `present(from:)` in the protocol because the SwiftUI
// view tree doesn't have a UIViewController to present from without
// adding backtracking. The real impl decides how to present (Day 6+).

import Foundation
#if canImport(UIKit)
import UIKit
#endif

public enum LibraryPickerError: Error, LocalizedError, Equatable, Sendable {
    case cancelled
    case underlying(reason: String)
    case emptyImage

    public var errorDescription: String? {
        switch self {
        case .cancelled:           return "Photo-library selection was cancelled."
        case .underlying(let r):   return "Photo-library picker error. (\(r))"
        case .emptyImage:          return "The selected image is empty."
        }
    }

    public var tag: String {
        switch self {
        case .cancelled:  return "cancelled"
        case .underlying: return "underlying"
        case .emptyImage: return "empty_image"
        }
    }
}

public protocol LibraryPicker: Sendable {
    var displayLabel: String { get }

    /// Present the system picker and return the chosen `UIImage`.
    /// Returns `nil` if the user cancelled.
    func pickImage() async throws -> UIImage?
}

#if canImport(PhotosUI)
import PhotosUI

/// Real PHPicker-backed implementation (R10 D-077).
///
/// We deliberately do *not* wrap PHPickerViewController in a UIViewController
/// representable here — the SmokeTestView (and Day 6's ContentView) own
/// their own UIKit presentation surface. The real impl uses the new
/// `loadFileRepresentation(forTypeIdentifier:)` PHPicker callback that
/// returns a URL we can load asynchronously, then converts to UIImage.
///
/// Day 5 OCR does not need pixel-perfect rendering — a JPEG at quality
/// 0.9 is more than enough for Apple Vision accuracy per the benchmark
/// plan (`doc/ocr-benchmark-plan.md`).
///
/// Concurrency note (R10): PHPicker's delegate is invoked on the main
/// actor, but Swift 6 strict concurrency sees it as a non-isolated
/// callback. We use `nonisolated(unsafe)` plus a lock for the
/// continuation; the lock is uncontended in practice (the delegate
/// fires once per picker invocation).
public final class PHPPickerLibraryPicker: NSObject, LibraryPicker, @unchecked Sendable, PHPickerViewControllerDelegate {
    public let displayLabel: String = "Photo Library (PHPicker)"

    private let lock = NSLock()
    nonisolated(unsafe) private var continuation: CheckedContinuation<UIImage?, Error>?

    public override init() { super.init() }

    public func pickImage() async throws -> UIImage? {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<UIImage?, Error>) in
            lock.lock()
            continuation = cont
            lock.unlock()
        }
    }

    /// Bind the system PHPickerViewController. Called from the SwiftUI
    /// host via a UIViewControllerRepresentable wrapper.
    public func makePicker() -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        return picker
    }

    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard let result = results.first else {
            resumeWithImage(nil, error: nil)
            return
        }
        let provider = result.itemProvider
        guard provider.canLoadObject(ofClass: UIImage.self) else {
            resumeWithImage(nil, error: LibraryPickerError.underlying(
                reason: "selected item is not a UIImage"
            ))
            return
        }
        provider.loadObject(ofClass: UIImage.self) { [weak self] reading, _ in
            // The provider callback is on a background queue; capture the
            // image inside the closure (Sendable extraction) then hop
            // to the main actor with the value.
            let asImage: UIImage? = (reading as? UIImage)
            DispatchQueue.main.async {
                self?.resumeWithImage(asImage, error: nil)
            }
        }
    }

    private func resumeWithImage(_ image: UIImage?, error: Error?) {
        lock.lock()
        let pending = continuation
        continuation = nil
        lock.unlock()
        guard let pending else { return }
        if let error {
            pending.resume(throwing: error)
            return
        }
        guard let image else {
            pending.resume(returning: nil)
            return
        }
        if image.size == .zero {
            pending.resume(throwing: LibraryPickerError.emptyImage)
            return
        }
        pending.resume(returning: image)
    }
}
#endif
