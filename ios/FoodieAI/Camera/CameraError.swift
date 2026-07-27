// CameraError.swift
// Day 4 — Typed errors for the camera subsystem (R10 D-072).
//
// Five cases covers MVP0 — Day 7 will fold this into `FoodieAIError`
// (per testing-guidelines §1 pass criterion: unified error enum).

import Foundation

public enum CameraError: Error, LocalizedError, Equatable, Sendable {
    /// Authorization is not `.authorized`. Caller should branch on
    /// `authorizationStatus` and either show Settings or a friendly
    /// message; this error means "we tried anyway and it failed."
    case unauthorized(reason: String)

    /// The capture session was already running, or already stopped, or
    /// the requested operation doesn't apply.
    case invalidSessionState(reason: String)

    /// The AVFoundation layer (or library picker) reported an error we
    /// can't categorize. The wrapped `reason` is the iOS message; we
    /// don't attempt localization.
    case underlying(reason: String)

    /// The user cancelled (closed library picker, dismissed permission
    /// sheet) without picking a photo.
    case cancelled

    /// The captured UIImage was empty (zero pixel dimensions) or
    /// otherwise unusable. Day 5 OCR will produce its own error from
    /// the same condition; this is just the early signal.
    case emptyImage

    /// AVFoundation (or PhotosUI) is not available — simulator without
    /// hardware, iPad without rear camera, Mac Catalyst without a
    /// webcam, etc. Caller should either fall back to the library
    /// picker or show the "no camera" message.
    case unavailable(reason: String)

    public var errorDescription: String? {
        switch self {
        case .unauthorized(let reason):
            return "Camera access is not authorized. (\(reason))"
        case .invalidSessionState(let reason):
            return "Camera session state error. (\(reason))"
        case .underlying(let reason):
            return "Camera error. (\(reason))"
        case .cancelled:
            return "Camera operation was cancelled."
        case .emptyImage:
            return "Captured image was empty."
        case .unavailable(let reason):
            return "Camera is not available on this device. (\(reason))"
        }
    }

    public var tag: String {
        switch self {
        case .unauthorized:       return "unauthorized"
        case .invalidSessionState: return "invalid_session_state"
        case .underlying:         return "underlying"
        case .cancelled:          return "cancelled"
        case .emptyImage:         return "empty_image"
        case .unavailable:        return "unavailable"
        }
    }
}
