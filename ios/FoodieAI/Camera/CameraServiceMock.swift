// CameraServiceMock.swift
// Day 4 — Test double for CameraService (R10 D-074).
//
// Two construction styles:
//   - `init(displayLabel:status:next:)` — return a fixed status and image
//   - `init(...scriptedImages:)` — return each scripted image in sequence
//   - `init(...scriptedErrors:thenImage:)` — fail N times then succeed
//
// All `requestAuthorization()` calls result in `status` (we don't model
// the iOS-modal transition here — that's an AVFoundation concern). For
// tests that want to verify the .notDetermined → .authorized transition,
// we'd need a separate "promoteNotDetermined" mock constructor; not
// needed on Day 4.

import Foundation
#if canImport(UIKit)
import UIKit
#endif

public final class CameraServiceMock: CameraService, @unchecked Sendable {
    public let displayLabel: String
    public var simulatedStatus: CameraAuthorizationStatus
    public var simulatedNextImage: UIImage?

    private let scriptedImages: Deque<UIImage>
    private let errorSchedule: Deque<CameraError>
    private let promoteNotDetermined: Bool

    public private(set) var requestAuthorizationCalls: Int
    public private(set) var configureSessionCalls: Int
    public private(set) var startSessionCalls: Int
    public private(set) var stopSessionCalls: Int
    public private(set) var capturePhotoCalls: Int
    public private(set) var ingestCalls: Int

    public init(
        displayLabel: String = "MockCamera",
        status: CameraAuthorizationStatus = .authorized,
        next image: UIImage? = nil,
        promoteNotDetermined: Bool = false
    ) {
        self.displayLabel = displayLabel
        self.simulatedStatus = status
        self.simulatedNextImage = image
        self.scriptedImages = Deque(initial: [])
        self.errorSchedule = Deque(initial: [])
        self.promoteNotDetermined = promoteNotDetermined
        self.requestAuthorizationCalls = 0
        self.configureSessionCalls = 0
        self.startSessionCalls = 0
        self.stopSessionCalls = 0
        self.capturePhotoCalls = 0
        self.ingestCalls = 0
    }

    public init(
        displayLabel: String = "MockCamera",
        status: CameraAuthorizationStatus = .authorized,
        scriptedImages images: [UIImage]
    ) {
        self.displayLabel = displayLabel
        self.simulatedStatus = status
        self.simulatedNextImage = nil
        self.scriptedImages = Deque(initial: images)
        self.errorSchedule = Deque(initial: [])
        self.promoteNotDetermined = false
        self.requestAuthorizationCalls = 0
        self.configureSessionCalls = 0
        self.startSessionCalls = 0
        self.stopSessionCalls = 0
        self.capturePhotoCalls = 0
        self.ingestCalls = 0
    }

    public init(
        displayLabel: String = "MockCamera",
        status: CameraAuthorizationStatus = .authorized,
        failFirstWith error: CameraError,
        thenImage: UIImage
    ) {
        self.displayLabel = displayLabel
        self.simulatedStatus = status
        self.simulatedNextImage = nil
        self.scriptedImages = Deque(initial: [thenImage])
        self.errorSchedule = Deque(initial: [error])
        self.promoteNotDetermined = false
        self.requestAuthorizationCalls = 0
        self.configureSessionCalls = 0
        self.startSessionCalls = 0
        self.stopSessionCalls = 0
        self.capturePhotoCalls = 0
        self.ingestCalls = 0
    }

    public var authorizationStatus: CameraAuthorizationStatus {
        get async { simulatedStatus }
    }

    public func requestAuthorization() async throws -> CameraAuthorizationStatus {
        requestAuthorizationCalls += 1
        // Tests that want the .notDetermined → .authorized transition can
        // set `promoteNotDetermined = true`; default behaviour is "instant
        // promotion to .authorized because we just grant it for the test."
        if promoteNotDetermined, simulatedStatus == .notDetermined {
            simulatedStatus = .authorized
        } else if simulatedStatus == .notDetermined {
            simulatedStatus = .authorized
        }
        return simulatedStatus
    }

    public func configureSession() async throws {
        configureSessionCalls += 1
    }

    public func startSession() throws {
        startSessionCalls += 1
    }

    public func stopSession() {
        stopSessionCalls += 1
    }

    public func capturePhoto() async throws -> UIImage {
        capturePhotoCalls += 1
        if let pendingError = errorSchedule.popFront() {
            throw pendingError
        }
        if let next = scriptedImages.popFront() {
            if next.size == .zero { throw CameraError.emptyImage }
            return next
        }
        if let next = simulatedNextImage {
            if next.size == .zero { throw CameraError.emptyImage }
            return next
        }
        // Fallback: throw underlying so the orchestrator surfaces a real error.
        throw CameraError.underlying(reason: "no scripted image left on call \(capturePhotoCalls)")
    }

    public func ingest(image: UIImage) throws {
        ingestCalls += 1
        if image.size == .zero { throw CameraError.emptyImage }
        simulatedNextImage = image
    }
}
