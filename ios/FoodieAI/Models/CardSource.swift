// CardSource.swift
// Where the dish card's content originated.
// Created as part of MVP0 Day 1 — data layer.

import Foundation

public enum CardSource: String, Codable, Sendable, CaseIterable {
    case wikipedia
    case baiduBaike = "baidu_baike"
    case wikipediaPlusBaidu = "wikipedia+baidu"
    case menuVerified = "menu_verified"
    case llmOnly = "llm_only"

    /// User-facing tag emoji + short label, for the SourceTag UI component.
    public var tagEmoji: String {
        switch self {
        case .wikipedia, .baiduBaike, .wikipediaPlusBaidu: return "📖"
        case .menuVerified: return "📷"
        case .llmOnly: return "🤖"
        }
    }

    public var shortLabel: String {
        switch self {
        case .wikipedia: return "Wikipedia"
        case .baiduBaike: return "百度百科"
        case .wikipediaPlusBaidu: return "Wiki + Baidu"
        case .menuVerified: return "Menu"
        case .llmOnly: return "AI"
        }
    }
}
