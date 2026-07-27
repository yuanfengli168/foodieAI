// CameraAuthorizationStatus.swift
// Day 4 — Tristate AV authorization enum (R10 D-071).
//
// We mirror Apple's `AVAuthorizationStatus` to keep our protocol surface
// testable without dragging `AVFoundation` into unit tests. The AV-backed
// impl maps from Apple's enum into ours; the rest of the app only sees
// this enum.
//
// Day 7 may swap to a unified `FoodieAIError.permissionDenied` — for
// now we keep this standalone so the camera subsystem is self-contained.

import Foundation

public enum CameraAuthorizationStatus: String, Sendable, Equatable {
    /// User has not yet been asked. The next call to `requestAuthorization()`
    /// will surface the iOS permission alert.
    case notDetermined

    /// User granted camera access.
    case authorized

    /// User explicitly denied camera access. The app must direct the user
    /// to Settings (iOS HIG).
    case denied

    /// Parental controls / MDM / enterprise policy blocks camera access.
    case restricted

    /// A camera is not available on this device (simulator without depth,
    /// iPad without rear lens, Mac Catalyst).
    case unavailable

    /// User-facing explanation of what to do for each non-authorized case.
    public var userMessage: String {
        switch self {
        case .notDetermined:
            return "We'll ask for camera access once."
        case .denied:
            return "Camera access denied. Open Settings → foodieAI → Camera to enable."
        case .restricted:
            return "Camera is restricted on this device by policy."
        case .unavailable:
            return "No camera available on this device."
        case .authorized:
            return "Camera access granted."
        }
    }
}
