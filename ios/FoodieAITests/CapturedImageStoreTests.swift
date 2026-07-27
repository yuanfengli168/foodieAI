// CapturedImageStoreTests.swift
// Day 4 — Unit tests for the in-memory image store + tmp-dir persistence.

import XCTest
import UIKit
@testable import FoodieAI

@MainActor
final class CapturedImageStoreTests: XCTestCase {

    private func makeImage(size: CGSize = CGSize(width: 80, height: 60)) -> UIImage {
        UIGraphicsBeginImageContext(size)
        UIColor.green.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let img = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return img
    }

    func test_set_stores_image_and_publishes_current() throws {
        let store = CapturedImageStore()
        let img = makeImage()
        let url = try store.set(img)
        XCTAssertNotNil(store.current)
        XCTAssertEqual(store.current?.size, img.size)
        XCTAssertEqual(store.onDiskPath, url.path)
        XCTAssertNotNil(store.capturedAt)
        // File should exist on disk
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func test_set_throws_emptyImage_for_zero_size() {
        let store = CapturedImageStore()
        XCTAssertThrowsError(try store.set(UIImage())) { err in
            guard let ce = err as? CameraError else {
                return XCTFail("Wrong error type: \(err)")
            }
            XCTAssertEqual(ce.tag, "empty_image")
        }
    }

    func test_clear_removes_image_and_tmp_file() throws {
        let store = CapturedImageStore()
        let url = try store.set(makeImage())
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        store.clear()
        XCTAssertNil(store.current)
        XCTAssertNil(store.onDiskPath)
        XCTAssertNil(store.capturedAt)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path),
                       "clear() must remove the on-disk JPEG")
    }

    func test_set_overwrites_previous_tmp_file() throws {
        let store = CapturedImageStore()
        let first = try store.set(makeImage(size: CGSize(width: 100, height: 100)))
        XCTAssertTrue(FileManager.default.fileExists(atPath: first.path))
        let second = try store.set(makeImage(size: CGSize(width: 120, height: 90)))
        // The two URLs must be distinct (UUID-based filenames) so we
        // don't accidentally nuke the file we just wrote.
        XCTAssertNotEqual(first.path, second.path)
        XCTAssertFalse(FileManager.default.fileExists(atPath: first.path),
                       "Replacing the image must delete the previous tmp file")
        XCTAssertTrue(FileManager.default.fileExists(atPath: second.path))
    }

    func test_set_returns_url_in_tmp_directory() throws {
        let store = CapturedImageStore()
        let url = try store.set(makeImage())
        // We allow FileManager's canonical path so we can compare on case-insensitive
        // tmp dirs. The shared TmpDir should be a parent of our path.
        let tmp = FileManager.default.temporaryDirectory.standardizedFileURL.path
        XCTAssertTrue(url.standardizedFileURL.path.hasPrefix(tmp),
                      "Captured JPEG should land in the temporary directory")
    }

    func test_multiple_stores_independent() throws {
        let a = CapturedImageStore()
        let b = CapturedImageStore()
        let ia = makeImage(size: CGSize(width: 33, height: 33))
        _ = try a.set(ia)
        XCTAssertNil(b.current)
        XCTAssertNotNil(a.current)
    }
}
