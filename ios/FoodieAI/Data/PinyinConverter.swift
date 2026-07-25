// PinyinConverter.swift
// Day 2 — fuzzy search support.
// MVP0 strategy: hand-rolled lookup table for the 126 bundled dishes
// (no full pinyin library, which would be ~5MB).
// MVP1 can swap in a real library (Pinyin-Swift, MIT) for arbitrary input.
//
// Locked: 2026-07-26 (Day 2, MVP0). See doc/mvp0-plan.md §4.

import Foundation

/// Maps a Chinese dish name (or a substring of it) to its pinyin
/// without tone marks. Used by `FuzzyIndex` to support queries
/// like "ma po dou fu" -> 麻婆豆腐.
public struct PinyinConverter: Sendable {
    /// id -> pinyin lookup, populated from the bundled dishes.jsonl.
    private let byId: [String: String]
    /// name_zh -> pinyin lookup, for direct pinyin-by-name lookups
    /// (e.g. when user types "麻婆豆腐" and we want to fuzzy-match by pinyin).
    private let byName: [String: String]

    public init(dishes: [Dish]) {
        var byId: [String: String] = [:]
        var byName: [String: String] = [:]
        for d in dishes {
            let p = d.pinyin.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !p.isEmpty else { continue }
            byId[d.id] = p
            if !d.nameZh.isEmpty {
                byName[d.nameZh] = p
            }
        }
        self.byId = byId
        self.byName = byName
    }

    /// Pinyin for a dish id, or nil if the id is unknown.
    public func pinyin(forDishId id: String) -> String? {
        byId[id]
    }

    /// Pinyin for a Chinese dish name, or nil if the name is unknown.
    public func pinyin(forName name: String) -> String? {
        byName[name]
    }

    /// All pinyins in the bundle, for iteration / debugging.
    public var allPinyins: [String] {
        Array(byId.values)
    }

    /// How many dishes have a non-empty pinyin in the bundle.
    public var count: Int { byId.count }
}
