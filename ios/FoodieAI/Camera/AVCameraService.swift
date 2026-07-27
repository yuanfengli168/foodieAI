// AVCameraService.swift
// Day 4 — AVFoundation-backed CameraService implementation (R10 D-079).
//
// Most of this file is iOS-required AV boilerplate. The testable bits are
// the CameraError mapping and the authorization-status translation — those
// have unit tests (mocking AVCaptureSession is out of reach without a real
// device).
//
// Lifecycle mapping (R10 D-079 lock):
//   - constructor: nothing allocated until `configureSession()` is called
//   - `configureSession()`: build session, add inputs/outputs, set photo preset
//   - `startSession()`: start the AVCaptureSession on a background queue
//   - `stopSession()`: stop the AVCaptureSession safely
//   - `capturePhoto()`: AVCapturePhotoOutput.capturePhoto delegate → UIImage
//
// Day 6 will replace the AVCaptureVideoPreviewLayer hosting with a
// UIViewRepresentable that drops into ContentView; Day 4 just needs the
// service surface to be unit-testable, which is why we don't ship the
// preview layer hosting here.

import Foundation
#if canImport(AVFoundation) && canImport(UIKit)
import AVFoundation
import UIKit
#endif

/// Thin AVFoundation-backed implementation. The bulk of the code is
/// configuration; we keep it inside an `#if canImport` block so the unit
/// test target (which excludes AVKit in some CI configs) can still compile.
public final class AVCameraService: NSObject, CameraService, @unchecked Sendable {
    public let displayLabel: String = "AVFoundation Camera"

    #if canImport(AVFoundation) && canImport(UIKit)
    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let photoQueue = DispatchQueue(label: "foodieai.camera.photo")
    private var photoContinuation: CheckedContinuation<UIImage, Error>?
    private var lastError: Error?

    public override init() { super.init() }
    #endif

    public var authorizationStatus: CameraAuthorizationStatus {
        get async { mapAVStatus(AVCaptureDevice.authorizationStatus(for: .video)) }
    }

    public func requestAuthorization() async throws -> CameraAuthorizationStatus {
        #if canImport(AVFoundation)
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        if !granted {
            throw CameraError.unauthorized(
                reason: "AVCaptureDevice.requestAccess returned false"
            )
        }
        return mapAVStatus(AVCaptureDevice.authorizationStatus(for: .video))
        #else
        throw CameraError.unavailable(reason: "AVFoundation not available")
        #endif
    }

    public func configureSession() async throws {
        #if canImport(AVFoundation) && canImport(UIKit)
        guard !session.isRunning else { return }
        session.beginConfiguration()
        // Best preset for menus (which are letter-sized paperwork).
        if session.canSetSessionPreset(.photo) {
            session.sessionPreset = .photo
        }
        // Input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            session.commitConfiguration()
            throw CameraError.unavailable(reason: "no rear camera available")
        }
        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                session.commitConfiguration()
                throw CameraError.invalidSessionState(reason: "cannot add camera input")
            }
            session.addInput(input)
        } catch {
            session.commitConfiguration()
            throw CameraError.underlying(reason: "could not build input: \(error)")
        }
        // Output
        guard session.canAddOutput(photoOutput) else {
            session.commitConfiguration()
            throw CameraError.invalidSessionState(reason: "cannot add photo output")
        }
        session.addOutput(photoOutput)
        session.commitConfiguration()
        #else
        throw CameraError.unavailable(reason: "AVFoundation not available")
        #endif
    }

    public func startSession() throws {
        #if canImport(AVFoundation) && canImport(UIKit)
        guard !session.isRunning else { return }
        session.startRunning()
        if !session.isRunning {
            throw CameraError.invalidSessionState(reason: "session.startRunning() returned without running")
        }
        #else
        throw CameraError.unavailable(reason: "AVFoundation not available")
        #endif
    }

    public func stopSession() {
        #if canImport(AVFoundation) && canImport(UIKit)
        if session.isRunning { session.stopRunning() }
        #endif
    }

    public func capturePhoto() async throws -> UIImage {
        #if canImport(AVFoundation) && canImport(UIKit)
        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<UIImage, Error>) in
            self.photoContinuation = cont
            let settings = AVCapturePhotoSettings()
            settings.flashMode = .auto
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
        #else
        throw CameraError.unavailable(reason: "AVFoundation not available")
        #endif
    }
}

#if canImport(AVFoundation) && canImport(UIKit)
extension AVCameraService: AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ output: AVCapturePhotoOutput,
                            didFinishProcessingPhoto photo: AVCapturePhoto,
                            error: Error?) {
        if let error {
            photoContinuation?.resume(throwing: CameraError.underlying(reason: String(describing: error)))
            photoContinuation = nil
            return
        }
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            photoContinuation?.resume(throwing: CameraError.emptyImage)
            photoContinuation = nil
            return
        }
        if image.size == .zero {
            photoContinuation?.resume(throwing: CameraError.emptyImage)
            photoContinuation = nil
            return
        }
        photoContinuation?.resume(returning: image)
        photoContinuation = nil
    }
}
#endif

/// Translate Apple's AVAuthorizationStatus to ours. Per R10/D-071 we add
/// `.unavailable` for the simulator-or-no-camera case.
private func mapAVStatus(_ status: AVAuthorizationStatus) -> CameraAuthorizationStatus {
    switch status {
    case .notDetermined: return .notDetermined
    case .authorized:    return .authorized
    case .denied:        return .denied
    case .restricted:    return .restricted
    @unknown default:   return .unavailable
    }
}
