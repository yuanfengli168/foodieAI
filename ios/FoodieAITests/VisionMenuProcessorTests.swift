// VisionMenuProcessorTests.swift
// Day 5 — Integration tests for the OCR → match pipeline (R12 D-103).
//
// We exercise VisionMenuProcessor against an OCRServiceMock that returns
// a fixed array of OCRLine values (some prices, some dish-name hits)
// against the bundled DishRepository.
//
// Test data: bundled dishes include "sesame_chicken" (zhi ma ji), so a
// vision mock returning ["$12", "Sesame Chicken"] should pair $12
// (classified as price) with sesame_chicken.

import XCTest
import UIKit
@testable import FoodieAI

@MainActor
final class VisionMenuProcessorTests: XCTestCase {
    private var repo: DishRepository!
    private func makeImage() -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: 200, height: 200))
        UIColor.white.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: 200, height: 200))
        let img = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return img
    }

    override func setUpWithError() throws {
        repo = try DishRepository.loadFromBundle()
    }

    func test_empty_image_returns_errored() async {
        let mock = OCRServiceMock(scripted: [])
        let proc = VisionMenuProcessor(ocr: mock, repository: repo)
        let result = await proc.process(image: UIImage(), onDiskPath: nil)
        if case .errored(let reason) = result {
            XCTAssertTrue(reason.lowercased().contains("empty"))
        } else {
            XCTFail("Expected .errored, got \(result)")
        }
        XCTAssertEqual(mock.callCount, 0)
    }

    func test_ocr_failure_surfaces_errored_with_tag() async {
        let mock = OCRServiceMock(alwaysThrows: OCRError.visionFailure(reason: "demo"))
        let proc = VisionMenuProcessor(ocr: mock, repository: repo)
        let result = await proc.process(image: makeImage(), onDiskPath: "/tmp/x.jpg")
        if case .errored(let reason) = result {
            XCTAssertTrue(reason.contains("vision_failure"), "Reason should carry tag, got: \(reason)")
            XCTAssertTrue(reason.contains("demo"))
        } else {
            XCTFail("Expected .errored, got \(result)")
        }
    }

    func test_classified_lines_pair_with_bundled_dishes() async {
        // Two lines that both should resolve cleanly: Sesame Chicken has
        // exact alias + menu_verified bonus; combo A is a typo for
        // general_tsos_chicken in some test setups — we instead use
        // a deliberately novel phrase to keep the assertion precise.
        let lines = [
            OCRLine(text: "$12.50", confidence: 0.99, bbox: .zero),
            OCRLine(text: "Sesame Chicken", confidence: 0.85, bbox: .zero),
            OCRLine(text: "somethingdefinitelynotintherdb", confidence: 0.7, bbox: .zero),
        ]
        let mock = OCRServiceMock(scripted: lines)
        let proc = VisionMenuProcessor(ocr: mock, repository: repo, minConfidenceForMatch: 0.5)
        let result = await proc.process(image: makeImage(), onDiskPath: nil)
        if case .parsed(let ocrLines, let matched, let unmatched, let label) = result {
            XCTAssertEqual(label, "VisionMenuProcessor")
            XCTAssertEqual(ocrLines.count, 3)
            // Sesame Chicken should be a positive match
            XCTAssertTrue(matched.contains { $0.id == "sesame_chicken" },
                          "Sesame Chicken should match from the bundled 126 dishes, matched=\(matched.map(\.id))")
            // The deliberately-novel phrase should fall through unmatched
            XCTAssertTrue(unmatched.contains("somethingdefinitelynotintherdb"))
            // $12.50 should not appear in matched or unmatched (it's a price line)
            XCTAssertFalse(matched.contains { $0.id == "$12.50" })
            XCTAssertFalse(unmatched.contains("$12.50"))
        } else {
            XCTFail("Expected .parsed, got \(result)")
        }
    }

    func test_price_lines_dropped_before_match() async {
        let lines = [
            OCRLine(text: "Combination Platter", confidence: 0.85, bbox: .zero, isPrice: true),  // mis-classified as price
            OCRLine(text: "Sesame Chicken", confidence: 0.85, bbox: .zero),
        ]
        let mock = OCRServiceMock(scripted: lines)
        let proc = VisionMenuProcessor(ocr: mock, repository: repo)
        let result = await proc.process(image: makeImage(), onDiskPath: nil)
        if case .parsed(_, _, let unmatched, _) = result {
            // Combination Platter should fall through to unmatched because
            // it's classified as price and dropped.
            XCTAssertFalse(unmatched.contains("Combination Platter"))
        } else {
            XCTFail("Expected .parsed")
        }
    }

    func test_unmatched_lines_surface_in_the_field() async {
        let lines = [
            OCRLine(text: "$5", confidence: 0.99, bbox: .zero),
            OCRLine(text: "Dinosaur-shaped Dumpling", confidence: 0.5, bbox: .zero),
        ]
        let mock = OCRServiceMock(scripted: lines)
        let proc = VisionMenuProcessor(ocr: mock, repository: repo, minConfidenceForMatch: 0.7)
        let result = await proc.process(image: makeImage(), onDiskPath: nil)
        if case .parsed(_, let matched, let unmatched, _) = result {
            XCTAssertTrue(unmatched.contains("Dinosaur-shaped Dumpling"))
            XCTAssertEqual(matched.count, 0)
        } else {
            XCTFail("Expected .parsed")
        }
    }

    func test_displayLabel_is_constant() async {
        let mock = OCRServiceMock(scripted: [])
        let proc = VisionMenuProcessor(ocr: mock, repository: repo)
        XCTAssertEqual(proc.displayLabel, "VisionMenuProcessor")
    }

    func test_one_ocr_call_per_process() async {
        let mock = OCRServiceMock(scripted: [OCRLine(text: "sesame chicken", confidence: 0.9, bbox: .zero)])
        let proc = VisionMenuProcessor(ocr: mock, repository: repo)
        _ = await proc.process(image: makeImage(), onDiskPath: nil)
        XCTAssertEqual(mock.callCount, 1, "OCRService should be called exactly once per process() invocation")
    }
}
