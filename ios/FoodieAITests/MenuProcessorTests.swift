// MenuProcessorTests.swift
// Day 4 — Unit tests for StubMenuProcessor — the Day 4 → Day 5 handoff.

import XCTest
import UIKit
@testable import FoodieAI

final class MenuProcessorTests: XCTestCase {

    private func makeImage(size: CGSize = CGSize(width: 320, height: 480)) -> UIImage {
        UIGraphicsBeginImageContext(size)
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let img = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return img
    }

    func test_process_with_valid_image_returns_received() async {
        let processor = StubMenuProcessor()
        let img = makeImage(size: CGSize(width: 100, height: 200))
        let result = await processor.process(image: img, onDiskPath: "/tmp/x.jpg")
        if case .received(let bytes, let path, let label) = result {
            XCTAssertEqual(bytes, 100 * 200 * 4)
            XCTAssertEqual(path, "/tmp/x.jpg")
            XCTAssertEqual(label, "MenuProcessor (stub)")
        } else {
            XCTFail("Expected .received, got \(result)")
        }
        XCTAssertEqual(processor.callCount, 1)
        XCTAssertEqual(processor.lastImageBytes, 100 * 200 * 4)
    }

    func test_process_with_nil_path_still_returns_received() async {
        let processor = StubMenuProcessor()
        let img = makeImage(size: CGSize(width: 10, height: 20))
        let result = await processor.process(image: img, onDiskPath: nil)
        if case .received(_, let path, _) = result {
            XCTAssertNil(path)
        } else {
            XCTFail("Expected .received")
        }
    }

    func test_process_with_empty_image_returns_errored() async {
        let processor = StubMenuProcessor()
        let result = await processor.process(image: UIImage(), onDiskPath: nil)
        if case .errored(let reason) = result {
            XCTAssertTrue(reason.lowercased().contains("empty"))
        } else {
            XCTFail("Expected .errored, got \(result)")
        }
        XCTAssertEqual(processor.callCount, 1)
        XCTAssertEqual(processor.lastImageBytes, 0)
    }

    func test_process_callCount_increments_across_calls() async {
        let processor = StubMenuProcessor()
        let img = makeImage()
        _ = await processor.process(image: img, onDiskPath: nil)
        _ = await processor.process(image: img, onDiskPath: nil)
        _ = await processor.process(image: img, onDiskPath: nil)
        XCTAssertEqual(processor.callCount, 3)
    }

    func test_displayLabel_does_not_change_across_calls() async {
        let processor = StubMenuProcessor()
        XCTAssertEqual(processor.displayLabel, "MenuProcessor (stub)")
        _ = await processor.process(image: makeImage(), onDiskPath: nil)
        XCTAssertEqual(processor.displayLabel, "MenuProcessor (stub)")
    }

    func test_menu_processing_result_is_equatable() async {
        // .received shape equality
        let a = MenuProcessingResult.received(
            imageBytes: 100, onDiskPath: nil, modelLabel: "X"
        )
        let b = MenuProcessingResult.received(
            imageBytes: 100, onDiskPath: nil, modelLabel: "X"
        )
        XCTAssertEqual(a, b)
        let c = MenuProcessingResult.errored(reason: "bad")
        XCTAssertNotEqual(a, c)
    }
}
