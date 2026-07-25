// DishRepository.swift
// Loads the bundled dishes.jsonl, parses it, and provides indexed lookups.
// Created as part of MVP0 Day 1 — data layer.

import Foundation
import os.log

public enum DishRepositoryError: Error, LocalizedError {
    case bundleResourceMissing(name: String)
    case decodingFailed(line: Int, error: Error)
    case emptyDatabase

    public var errorDescription: String? {
        switch self {
        case .bundleResourceMissing(let name):
            return "Bundled resource '\(name)' is missing from the app bundle."
        case .decodingFailed(let line, let error):
            return "Failed to parse dishes.jsonl at line \(line): \(error.localizedDescription)"
        case .emptyDatabase:
            return "The dish database loaded 0 dishes. Bundled file may be empty."
        }
    }
}

public final class DishRepository: Sendable {
    public let dishes: [Dish]

    private static let log = Logger(subsystem: "com.foodieai.app", category: "DishRepository")

    /// Load the repository from the app bundle's `dishes.jsonl` resource.
    /// Tries multiple bundle locations to handle the main app, tests, and CLI tools.
    public static func loadFromBundle(resource: String = "dishes",
                                      bundle: Bundle = .main) throws -> DishRepository {
        // Search order: explicit bundle, main app bundle, all loaded bundles.
        let candidates: [Bundle] = [bundle, .main] +
            Bundle.allBundles + Bundle.allFrameworks
        for candidate in candidates {
            if let url = candidate.url(forResource: resource, withExtension: "jsonl") {
                return try load(from: url)
            }
        }
        throw DishRepositoryError.bundleResourceMissing(name: "\(resource).jsonl")
    }

    /// Load the repository from an explicit URL (used for tests and the dev script).
    public static func load(from url: URL) throws -> DishRepository {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw DishRepositoryError.bundleResourceMissing(name: url.lastPathComponent)
        }
        guard let text = String(data: data, encoding: .utf8) else {
            throw DishRepositoryError.emptyDatabase
        }
        var parsed: [Dish] = []
        let lines = text.split(separator: "\n", omittingEmptySubsequences: true)
        for (idx, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            do {
                let dish = try JSONDecoder().decode(Dish.self, from: Data(trimmed.utf8))
                parsed.append(dish)
            } catch {
                log.error("dishes.jsonl line \(idx + 1) failed: \(error.localizedDescription, privacy: .public)")
                throw DishRepositoryError.decodingFailed(line: idx + 1, error: error)
            }
        }
        if parsed.isEmpty {
            throw DishRepositoryError.emptyDatabase
        }
        log.info("Loaded \(parsed.count) dishes from \(url.lastPathComponent, privacy: .public)")
        return DishRepository(dishes: parsed)
    }

    public init(dishes: [Dish]) {
        self.dishes = dishes
    }

    public func dish(byId id: String) -> Dish? {
        dishes.first { $0.id == id }
    }

    public func dishes(matching predicate: (Dish) -> Bool) -> [Dish] {
        dishes.filter(predicate)
    }
}
