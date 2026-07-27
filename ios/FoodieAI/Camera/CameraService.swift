// CameraService.swift
// Day 4 — Camera capture protocol (R10 D-073).
//
// Lives behind a protocol so the rest of the app never touches AVFoundation
// directly. The real impl (`AVCameraService`) wraps `AVCaptureSession`;
// the test double (`CameraServiceMock`) returns canned `UIImage`s so the
// orchestrator and the smoke-test view can both be unit-tested.
//
// Lifecycle (designed to match what AVCaptureSession needs):
//   1. caller checks `authorizationStatus`
//   2. if `.notDetermined`, caller invokes `requestAuthorization()`
//   3. caller invokes `configureSession()` once per capture session
//   4. caller invokes `startSession()` to begin the preview
//   5. caller invokes `capturePhoto()` and awaits a `UIImage`
//   6. caller invokes `stopSession()` when the view dismisses
//
// We do not include `startPreview()`/`stopPreview()` separately — they're
// the same lifecycle as the session.

import Foundation
#if canImport(UIKit)
import UIKit
#endif

public protocol CameraService: Sendable {
    /// Human-readable label for Settings + logs.
    var displayLabel: String { get }

    /// Current authorization state. Cached after the first read in a session.
    var authorizationStatus: CameraAuthorizationStatus { get async }

    /// Ask the user for camera permission. Returns the resulting status.
    /// Throws `CameraError.cancelled` only if the user dismissed before
    /// the system decision landed (rare path).
    @discardableResult
    func requestAuthorization() async throws -> CameraAuthorizationStatus

    /// Configure the capture pipeline (input device, photo output). Called
    /// once per session. Idempotent.
    func configureSession() async throws

    /// Start the capture session (preview live). No-op if already running.
    /// Throws `CameraError.invalidSessionState` if `configureSession()`
    /// wasn't called first.
    func startSession() throws

    /// Stop the capture session. Always safe to call.
    func stopSession()

    /// Capture one photo from the live session. Awaits the AVFoundation
    /// callback. Throws `CameraError.emptyImage` if the returned buffer
    /// has zero pixels.
    func capturePhoto() async throws -> UIImage

    /// Synchronously inject a synthetic image (used by the Library Picker
    /// to feed the same store as the camera). Default impl throws
    /// `CameraError.unsupportedOnRealImpl`; mocks accept it directly.
    func ingest(image: UIImage) throws
}

extension CameraService {
    /// Default implementation that real backends inherit; mocks override.
    public func ingest(image: UIImage) throws {
        throw CameraError.underlying(reason: "ingest(image:) is mock-only on Day 4")
    }
}
