// FlavorProfile.swift
// 5-dimension flavor profile for a dish, 0-5 scale.
// Created as part of MVP0 Day 1 — data layer.
//
// Locked: 2026-07-26 (Round 6). Schema matches data/dishes/dishes.jsonl.

import Foundation

public struct FlavorProfile: Codable, Hashable, Sendable {
    public let spicy: Int
    public let sour: Int
    public let salty: Int
    public let sweet: Int
    public let numbing: Int

    public init(spicy: Int, sour: Int, salty: Int, sweet: Int, numbing: Int) {
        self.spicy = spicy
        self.sour = sour
        self.salty = salty
        self.sweet = sweet
        self.numbing = numbing
    }

    /// 0 = none, 5 = extreme. Returns nil if any field is out of range.
    public static func validate(_ p: FlavorProfile) -> String? {
        let fields: [(String, Int)] = [
            ("spicy", p.spicy), ("sour", p.sour), ("salty", p.salty),
            ("sweet", p.sweet), ("numbing", p.numbing)
        ]
        for (name, v) in fields where v < 0 || v > 5 {
            return "flavor.\(name)=\(v) out of range [0,5]"
        }
        return nil
    }
}
