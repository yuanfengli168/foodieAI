// DishRepositoryEdgeCaseTests.swift
// Day 1.6: push DishRepository coverage above 80% by testing:
// - the matching(predicate:) lookup
// - the 3 DishRepositoryError cases
// - the bundle-missing and empty-DB error paths
// - the URL load with bad data error path

import XCTest
@testable import FoodieAI

final class DishRepositoryEdgeCaseTests: XCTestCase {
    func testDishesMatchingReturnsFiltered() throws {
        let repo = try DishRepository.loadFromBundle()
        let spicy = repo.dishes(matching: { $0.flavor.spicy >= 4 })
        XCTAssertGreaterThan(spicy.count, 0, "MVP0 DB has multiple spicy dishes")
        for dish in spicy { XCTAssertGreaterThanOrEqual(dish.flavor.spicy, 4) }
    }

    func testDishesMatchingWithFalsePredicateReturnsEmpty() throws {
        let repo = try DishRepository.loadFromBundle()
        let none = repo.dishes(matching: { _ in false })
        XCTAssertTrue(none.isEmpty)
    }

    func testDishesMatchingWithAlwaysTrueReturnsAll() throws {
        let repo = try DishRepository.loadFromBundle()
        let all = repo.dishes(matching: { _ in true })
        XCTAssertEqual(all.count, repo.dishes.count)
    }

    func testInitWithEmptyDishesSucceeds() {
        let repo = DishRepository(dishes: [])
        XCTAssertEqual(repo.dishes.count, 0)
    }

    func testLoadFromMissingBundleThrows() {
        let bogus = Bundle()
        XCTAssertThrowsError(try DishRepository.loadFromBundle(resource: "nonexistent_xyz", bundle: bogus)) { error in
            guard case DishRepositoryError.bundleResourceMissing(let name) = error else {
                XCTFail("Expected bundleResourceMissing, got \(error)")
                return
            }
            XCTAssertEqual(name, "nonexistent_xyz.jsonl")
        }
    }

    func testLoadFromMissingFileURLThrows() {
        let bogus = URL(fileURLWithPath: "/tmp/does-not-exist-\(UUID().uuidString).jsonl")
        XCTAssertThrowsError(try DishRepository.load(from: bogus)) { error in
            // The implementation throws bundleResourceMissing for any file IO error
            guard case DishRepositoryError.bundleResourceMissing = error else {
                XCTFail("Expected bundleResourceMissing, got \(error)")
                return
            }
        }
    }

    func testErrorDescriptionForMissingBundle() throws {
        let err = DishRepositoryError.bundleResourceMissing(name: "x.jsonl")
        XCTAssertEqual(try XCTUnwrap(err.errorDescription), "Bundled resource 'x.jsonl' is missing from the app bundle.")
    }

    func testErrorDescriptionForDecodingFailed() throws {
        let underlying = NSError(domain: "test", code: 1)
        let err = DishRepositoryError.decodingFailed(line: 42, error: underlying)
        let desc = try XCTUnwrap(err.errorDescription)
        XCTAssertTrue(desc.contains("42"))
        XCTAssertTrue(desc.contains("dishes.jsonl"))
    }

    func testErrorDescriptionForEmptyDatabase() throws {
        let err = DishRepositoryError.emptyDatabase
        XCTAssertEqual(try XCTUnwrap(err.errorDescription), "The dish database loaded 0 dishes. Bundled file may be empty.")
    }

    func testLoadFromDirectoryWithEmptyFileThrows() throws {
        // Create an empty .jsonl file in tmp and confirm load(from:) throws emptyDatabase.
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("foodieai-empty-\(UUID().uuidString).jsonl")
        try Data().write(to: tmp)
        defer { try? FileManager.default.removeItem(at: tmp) }

        // An empty file with valid UTF-8 will parse to 0 lines, but not throw
        // because our trim/split logic doesn't trigger the emptyDatabase branch.
        // (Empty file -> 0 lines -> parsed.isEmpty -> throws emptyDatabase.)
        XCTAssertThrowsError(try DishRepository.load(from: tmp)) { error in
            guard case DishRepositoryError.emptyDatabase = error else {
                XCTFail("Expected emptyDatabase, got \(error)")
                return
            }
        }
    }

    func testLoadFromFileWithMalformedLineThrows() throws {
        // Create a file with a malformed JSON line and confirm load(from:) throws decodingFailed.
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("foodieai-bad-\(UUID().uuidString).jsonl")
        let bad = """
        {"id":"ok","name_zh":"","name_en":"OK","pinyin":"","aliases_en":[],"aliases_zh":[],"photo_path":"","emoji_fallback":"🍽️","source":"wikipedia","source_url":"","is_menu_verified":false,"intro":"x","flavor":{"spicy":0,"sour":0,"salty":0,"sweet":0,"numbing":0},"pair_with":[],"region":"x","category":"main","tags":[]}
        {this is not valid json
        """
        try bad.data(using: .utf8)?.write(to: tmp)
        defer { try? FileManager.default.removeItem(at: tmp) }

        XCTAssertThrowsError(try DishRepository.load(from: tmp)) { error in
            guard case DishRepositoryError.decodingFailed(let line, _) = error else {
                XCTFail("Expected decodingFailed, got \(error)")
                return
            }
            XCTAssertEqual(line, 2, "Second line should fail")
        }
    }
}
