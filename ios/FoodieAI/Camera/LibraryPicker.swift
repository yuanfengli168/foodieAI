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

/// Callback-driven PHPicker-backed delegate (R11/D-085).
///
/// This is the underlying UIKit delegate that the SwiftUI host
/// (`Views/PHPickerPresenter.swift`, R11/D-086) drives. We used to expose
/// `pickImage() async throws -> UIImage?` here (R10/D-077), but that
/// never had a host that actually presented the picker — which meant
/// the system alert never showed, the continuation hung forever, and
/// "From library" looked like a frozen button (verified by Jacky during
/// QA, R11/D-084). The fix is to flip the surface:
///
///   - the representable owns the picker lifecycle
///   - the picker reports back via an `onPicked: (Result<UIImage, Error>) -> Void`
///     callback
///   - the (old) async API stays around for unit tests but is no longer
///     called from `CameraPanel` (which uses the SwiftUI binding instead)
///
/// Day 5 OCR doesn't need pixel-perfect rendering — a JPEG at quality
/// 0.9 from `itemProvider.loadDataRepresentation(forTypeIdentifier:)`
/// is more than enough for Apple Vision accuracy.
public final class PHPPickerLibraryPicker: NSObject, @unchecked Sendable, PHPickerViewControllerDelegate {
    public let displayLabel: String = "Photo Library (PHPicker)"

    /// Called on the main actor when the picker resolves (or the user
    /// cancels). Cancellations are reported as `.success(nil)`.
    public var onPicked: (@Sendable @MainActor (Swift.Result<UIImage?, LibraryPickerError>) -> Void)?

    public override init() { super.init() }

    /// Build a configured picker with this object as the delegate.
    /// Intended to be called once per presentation by the SwiftUI host.
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
            deliver(.success(nil))
            return
        }
        let provider = result.itemProvider
        guard provider.canLoadObject(ofClass: UIImage.self) else {
            deliver(.failure(.underlying(reason: "selected item is not a UIImage")))
            return
        }
        provider.loadObject(ofClass: UIImage.self) { [weak self] reading, _ in
            // Provider callback is on a background queue; Sendable
            // extraction at the boundary then hop to main.
            let asImage: UIImage? = (reading as? UIImage)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if let asImage, asImage.size == .zero {
                    self.deliver(.failure(.emptyImage))
                    return
                }
                self.deliver(.success(asImage))
            }
        }
    }

    private func deliver(_ result: Swift.Result<UIImage?, LibraryPickerError>) {
        let cb = onPicked
        onPicked = nil
        Task { @MainActor in cb?(result) }
    }
}

/// LibraryPicker async API retained for unit tests (R11). Day-4 smoke
/// view no longer uses this — it goes through `PHPickerPresenter`.
extension PHPPickerLibraryPicker: LibraryPicker {
    public func pickImage() async throws -> UIImage? {
        // The async API can never be reached in production after
        // R11/D-086 fixed the presentation. We throw so any future
        // caller that forgets to use the presenter sees a clear error
        // instead of a silent hang.
        throw LibraryPickerError.underlying(
            reason: "use PHPickerPresenter via SwiftUI; pickImage() is test-only"
        )
    }
}
#endif
