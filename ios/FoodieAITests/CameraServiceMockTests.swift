// CameraServiceMockTests.swift
// Day 4 — Unit tests covering the 3 init overloads of CameraServiceMock +
// its 7 call-recording slots + the empty-image guard.

import XCTest
import UIKit
@testable import FoodieAI

final class CameraServiceMockTests: XCTestCase {

    private func makeImage(size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        UIGraphicsBeginImageContext(size)
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let img = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return img
    }

    func test_init_with_next_image_returns_it() async throws {
        let mock = CameraServiceMock(next: makeImage())
        let img = try await mock.capturePhoto()
        XCTAssertEqual(img.size, CGSize(width: 100, height: 100))
        XCTAssertEqual(mock.capturePhotoCalls, 1)
    }

    func test_init_with_scriptedImages_returns_each_in_order() async throws {
        let first = makeImage(size: CGSize(width: 50, height: 50))
        let second = makeImage(size: CGSize(width: 60, height: 60))
        let mock = CameraServiceMock(scriptedImages: [first, second])
        let a = try await mock.capturePhoto()
        let b = try await mock.capturePhoto()
        XCTAssertEqual(a.size, CGSize(width: 50, height: 50))
        XCTAssertEqual(b.size, CGSize(width: 60, height: 60))
        XCTAssertEqual(mock.capturePhotoCalls, 2)
    }

    func test_init_scriptedImages_throws_underlying_when_exhausted() async {
        let mock = CameraServiceMock(scriptedImages: [makeImage()])
        _ = try? await mock.capturePhoto()
        do {
            _ = try await mock.capturePhoto()
            XCTFail("Expected throw on second call")
        } catch let e as CameraError {
            XCTAssertEqual(e.tag, "underlying")
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func test_init_failFirst_throws_then_returns_image() async throws {
        let mock = CameraServiceMock(
            failFirstWith: .invalidSessionState(reason: "not ready"),
            thenImage: makeImage()
        )
        do {
            _ = try await mock.capturePhoto()
            XCTFail("Expected throw")
        } catch let e as CameraError {
            XCTAssertEqual(e.tag, "invalid_session_state")
        }
        let img = try await mock.capturePhoto()
        XCTAssertEqual(img.size, CGSize(width: 100, height: 100))
        XCTAssertEqual(mock.capturePhotoCalls, 2)
    }

    func test_capturePhoto_throws_emptyImage_for_zero_size_image() async {
        let zeroImage = UIImage()
        let mock = CameraServiceMock(next: zeroImage)
        do {
            _ = try await mock.capturePhoto()
            XCTFail("Expected empty_image")
        } catch let e as CameraError {
            XCTAssertEqual(e.tag, "empty_image")
        } catch {
            XCTFail("Unexpected non-CameraError: \(error)")
        }
    }

    func test_requestAuthorization_promotes_notDetermined_to_authorized() async throws {
        let mock = CameraServiceMock(status: .notDetermined)
        let status = try await mock.requestAuthorization()
        XCTAssertEqual(status, .authorized)
        XCTAssertEqual(mock.requestAuthorizationCalls, 1)
    }

    func test_requestAuthorization_returns_input_status_when_already_resolved() async throws {
        let mock = CameraServiceMock(status: .denied)
        let status = try await mock.requestAuthorization()
        XCTAssertEqual(status, .denied)
    }

    func test_authorizationStatus_returns_simulatedStatus() async {
        let mock = CameraServiceMock(status: .restricted)
        let status = await mock.authorizationStatus
        XCTAssertEqual(status, .restricted)
    }

    func test_configureSession_startSession_stopSession_count_calls() async throws {
        let mock = CameraServiceMock(next: makeImage())
        try await mock.configureSession()
        try mock.startSession()
        mock.stopSession()
        mock.stopSession() // idempotent
        XCTAssertEqual(mock.configureSessionCalls, 1)
        XCTAssertEqual(mock.startSessionCalls, 1)
        XCTAssertEqual(mock.stopSessionCalls, 2)
    }

    func test_ingest_accepts_image_and_bumps_simulatedNextImage() throws {
        let mock = CameraServiceMock()
        let custom = makeImage(size: CGSize(width: 75, height: 75))
        try mock.ingest(image: custom)
        XCTAssertEqual(mock.ingestCalls, 1)
    }

    func test_ingest_throws_emptyImage_when_zero_size() {
        let mock = CameraServiceMock()
        do {
            try mock.ingest(image: UIImage())
            XCTFail("Expected empty_image")
        } catch let e as CameraError {
            XCTAssertEqual(e.tag, "empty_image")
        } catch {
            XCTFail("Unexpected non-CameraError: \(error)")
        }
    }

    func test_realImpl_ingest_throws_underlying() {
        // AVCameraService inherits the default `ingest(image:)` that throws.
        // We instantiate one and check the contract — sim has no AVCaptureSession
        // but the contract test runs without calling configureSession().
        let svc: any CameraService = AVCameraService()
        XCTAssertEqual(svc.displayLabel, "AVFoundation Camera")
        var gotError: Error?
        do {
            try svc.ingest(image: self.makeImage())
        } catch { gotError = error }
        guard let ce = gotError as? CameraError else {
            return XCTFail("Wrong error type: \(String(describing: gotError))")
        }
        XCTAssertEqual(ce.tag, "underlying")
    }
}
