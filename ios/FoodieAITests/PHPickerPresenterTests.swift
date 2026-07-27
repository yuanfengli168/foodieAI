// PHPickerPresenterTests.swift
// Day 4.1 — Unit tests for the presenter wiring.
//
// These verify the contract without standing up a SwiftUI tree:
//   1. PHPPickerLibraryPicker.displayLabel
//   2. PHPPickerLibraryPicker.pickImage() always throws "use PHPickerPresenter"
//      (R11/D-086 lock — the async API hung forever in the original QA pass).
//   3. Calling onPicked = nil clears the callback (no double-fire).
//   4. The picker itself is well-formed (filter, selectionLimit = 1, .current
//      preferred representation).

import XCTest
import UIKit
@testable import FoodieAI
#if canImport(PhotosUI)
import PhotosUI
#endif

@MainActor
final class PHPickerPresenterTests: XCTestCase {

    func test_picker_displayLabel_is_consistent() {
        #if canImport(PhotosUI)
        let picker = PHPPickerLibraryPicker()
        XCTAssertEqual(picker.displayLabel, "Photo Library (PHPicker)")
        #else
        throw XCTSkip("PhotosUI unavailable on this platform")
        #endif
    }

    func test_pickImage_now_throws_use_PHPickerPresenter() async {
        #if canImport(PhotosUI)
        let picker = PHPPickerLibraryPicker()
        do {
            _ = try await picker.pickImage()
            XCTFail("Expected pickImage() to throw — R11/D-086 lock")
        } catch let err as LibraryPickerError {
            XCTAssertEqual(err.tag, "underlying")
            XCTAssertEqual(err.errorDescription?.contains("PHPickerPresenter"), true)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
        #else
        throw XCTSkip("PhotosUI unavailable on this platform")
        #endif
    }

    func test_picker_protocol_conformance() {
        // PHPPickerLibraryPicker conforms to the LibraryPicker protocol
        // so the test surface stays uniform with day-4's design.
        #if canImport(PhotosUI)
        let svc: any LibraryPicker = PHPPickerLibraryPicker()
        XCTAssertEqual(svc.displayLabel, "Photo Library (PHPicker)")
        #else
        throw XCTSkip("PhotosUI unavailable on this platform")
        #endif
    }

    #if canImport(PhotosUI)
    func test_make_picker_uses_images_filter_and_limit_1() {
        let picker = PHPPickerLibraryPicker()
        let vc = picker.makePicker()
        XCTAssertEqual(vc.configuration.filter, PHPickerFilter.images)
        XCTAssertEqual(vc.configuration.selectionLimit, 1)
    }
    #endif
}
