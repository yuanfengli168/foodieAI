// OCRServiceMockTests.swift
// Day 5 — Unit tests for the OCRServiceMock (R12 D-101).
//
// We test 3 inits (scripted, alwaysThrows, failFirstThenReturn) plus the
// recording slots.

import XCTest
import UIKit
@testable import FoodieAI

final class OCRServiceMockTests: XCTestCase {
    private func makeLine(_ text: String) -> OCRLine {
        OCRLine(text: text, confidence: 0.9, bbox: .zero)
    }

    func test_scripted_returns_each_call_in_order() async throws {
        let mock = OCRServiceMock(scripted: [
            makeLine("a"), makeLine("b"), makeLine("c")
        ])
        let first = try await mock.recognize(image: UIImage())
        XCTAssertEqual(first.count, 3)
        XCTAssertEqual(first.first?.text, "a")
        XCTAssertEqual(mock.callCount, 1)
    }

    func test_alwaysThrows_surfaces_error_on_every_call() async {
        let mock = OCRServiceMock(alwaysThrows: OCRError.noTextFound)
        do {
            _ = try await mock.recognize(image: UIImage())
            XCTFail("Expected throw")
        } catch let e as OCRError {
            XCTAssertEqual(e.tag, "no_text_found")
        } catch {
            XCTFail("Wrong error type")
        }
    }

    func test_failFirst_surfaces_error_then_succeeds() async throws {
        let mock = OCRServiceMock(
            failFirstWith: OCRError.visionFailure(reason: "demo"),
            thenReturn: [makeLine("sesame chicken")]
        )
        do {
            _ = try await mock.recognize(image: UIImage())
            XCTFail("Expected throw on first call")
        } catch let e as OCRError {
            XCTAssertEqual(e.tag, "vision_failure")
        }
        let second = try await mock.recognize(image: UIImage())
        XCTAssertEqual(second.count, 1)
        XCTAssertEqual(mock.callCount, 2)
    }

    func test_displayLabel_is_Defaulted() {
        let m1 = OCRServiceMock(scripted: [])
        XCTAssertEqual(m1.displayLabel, "MockOCR")
        let m2 = OCRServiceMock(displayLabel: "Fake", scripted: [])
        XCTAssertEqual(m2.displayLabel, "Fake")
    }

    func test_callCount_starts_at_zero_and_increments() async throws {
        let mock = OCRServiceMock(scripted: [makeLine("x")])
        XCTAssertEqual(mock.callCount, 0)
        _ = try await mock.recognize(image: UIImage())
        XCTAssertEqual(mock.callCount, 1)
    }
}
