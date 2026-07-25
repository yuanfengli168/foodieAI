// Dish.swift
// Codable mirror of data/dishes/dishes.jsonl.
// Created as part of MVP0 Day 1 — data layer.

import Foundation

public struct Dish: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let nameZh: String
    public let nameEn: String
    public let pinyin: String
    public let aliasesEn: [String]
    public let aliasesZh: [String]
    public let photoPath: String
    public let emojiFallback: String
    public let source: CardSource
    public let sourceUrl: String
    public let isMenuVerified: Bool
    public let intro: String
    public let flavor: FlavorProfile
    public let pairWith: [String]
    public let region: String
    public let category: String
    public let tags: [String]

    public init(
        id: String, nameZh: String, nameEn: String, pinyin: String,
        aliasesEn: [String], aliasesZh: [String],
        photoPath: String, emojiFallback: String,
        source: CardSource, sourceUrl: String, isMenuVerified: Bool,
        intro: String, flavor: FlavorProfile,
        pairWith: [String], region: String, category: String, tags: [String]
    ) {
        self.id = id
        self.nameZh = nameZh
        self.nameEn = nameEn
        self.pinyin = pinyin
        self.aliasesEn = aliasesEn
        self.aliasesZh = aliasesZh
        self.photoPath = photoPath
        self.emojiFallback = emojiFallback
        self.source = source
        self.sourceUrl = sourceUrl
        self.isMenuVerified = isMenuVerified
        self.intro = intro
        self.flavor = flavor
        self.pairWith = pairWith
        self.region = region
        self.category = category
        self.tags = tags
    }

    enum CodingKeys: String, CodingKey {
        case id
        case nameZh = "name_zh"
        case nameEn = "name_en"
        case pinyin
        case aliasesEn = "aliases_en"
        case aliasesZh = "aliases_zh"
        case photoPath = "photo_path"
        case emojiFallback = "emoji_fallback"
        case source
        case sourceUrl = "source_url"
        case isMenuVerified = "is_menu_verified"
        case intro
        case flavor
        case pairWith = "pair_with"
        case region
        case category
        case tags
    }
}

public extension Dish {
    /// Display name: ZH if non-empty, else EN. Used in dish list rows.
    var displayName: String {
        nameZh.isEmpty ? nameEn : nameZh
    }

    /// Subtitle: opposite script. Shows "Mapo Tofu" under 麻婆豆腐, or vice versa.
    var displaySubtitle: String {
        nameZh.isEmpty ? "" : nameEn
    }

    /// True if this card has a real photo path (not the emoji fallback).
    var hasPhoto: Bool { !photoPath.isEmpty }

    /// True if this is an AI-only source. Used to gate the Settings toggle (D-030).
    var isAIGenerated: Bool { source == .llmOnly }
}
