// PHPickerPresenter.swift
// Day 4.1 — UIViewControllerRepresentable that drives PHPickerViewController
// from a SwiftUI sheet (R11/D-086).
//
// Why this exists (R11/D-084): the old `PHPPickerLibraryPicker.pickImage()`
// API used a continuation that only fired when the delegate callback ran
// — but the delegate only runs if iOS actually presented the picker,
// which requires a UIViewController to call `present(_:animated:)`. Our
// SmokeTestView's `CameraPanel` had no host VC, so the system prompt
// never showed and the user's "From library" tap hung indefinitely.
//
// This file flips the lifecycle:
//   - SwiftUI state (`isPresented: Bool`) drives a `.sheet(isPresented:)`
//   - `PHPickerPresenter` is the body of that sheet
//   - when the user picks an image (or cancels), `onResolve` fires
//   - SwiftUI dismisses the sheet by clearing the binding
//
// Day 6's ContentView will use the exact same pattern.

import SwiftUI
#if canImport(PhotosUI) && canImport(UIKit)
import PhotosUI
import UIKit

public struct PHPickerPresenter: UIViewControllerRepresentable {
    public typealias UIViewControllerType = UIViewController

    private let onResolve: (Swift.Result<UIImage?, LibraryPickerError>) -> Void

    public init(onResolve: @escaping (Swift.Result<UIImage?, LibraryPickerError>) -> Void) {
        self.onResolve = onResolve
    }

    public func makeUIViewController(context: Context) -> UIViewController {
        // Wrap the picker in a container VC so SwiftUI doesn't try to size it.
        let wrapper = PickerHostingController(onResolve: onResolve)
        return wrapper
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Nothing — the picker is presented once at make and resolves
        // itself when the user picks or cancels.
    }
}

/// The wrapper view controller. As soon as it loads, it builds a
/// PHPPickerViewController, presents it as a full-screen modal, and
/// waits for the delegate callback to resolve the sheet.
///
/// Note: this VC is NOT the PHPickerViewControllerDelegate — the
/// `PHPPickerLibraryPicker` instance handles that, since the picker
/// requires the delegate outlive the call to `present(_:)`.
final class PickerHostingController: UIViewController {
    private let onResolve: (Swift.Result<UIImage?, LibraryPickerError>) -> Void
    private var pickerDelegate: PHPPickerLibraryPicker?

    init(onResolve: @escaping (Swift.Result<UIImage?, LibraryPickerError>) -> Void) {
        self.onResolve = onResolve
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("nope") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentPickerOnce()
    }

    private func presentPickerOnce() {
        guard pickerDelegate == nil else { return }
        let delegate = PHPPickerLibraryPicker()
        let picker = delegate.makePicker()
        self.pickerDelegate = delegate
        // Closure capture: when the delegate fires, forward the result
        // back to the SwiftUI layer, which will dismiss the sheet.
        delegate.onPicked = { [weak self] result in
            guard let self else { return }
            self.onResolve(result)
        }
        present(picker, animated: true)
    }
}

// MARK: - Empty fallback when PhotosUI is unavailable (Mac Catalyst etc.)
public struct PHPickerPresenterFallback: View {
    private let onResolve: (Swift.Result<UIImage?, LibraryPickerError>) -> Void

    public init(onResolve: @escaping (Swift.Result<UIImage?, LibraryPickerError>) -> Void) {
        self.onResolve = onResolve
    }

    public var body: some View {
        VStack(spacing: 12) {
            Text("Photo library is not available on this device.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            Button("Dismiss") {
                onResolve(.success(nil))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color(red: 0xC7/255, green: 0x68/255, blue: 0x3D/255))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
    }
}
#else
public struct PHPickerPresenter: View {
    private let onResolve: (Swift.Result<UIImage?, LibraryPickerError>) -> Void

    public init(onResolve: @escaping (Swift.Result<UIImage?, LibraryPickerError>) -> Void) {
        self.onResolve = onResolve
    }

    public var body: some View {
        Text("Photo library requires PhotosUI; this platform doesn't ship it.")
            .padding()
    }
}
#endif
