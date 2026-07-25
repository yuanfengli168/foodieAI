// LLMBackend.swift
// Available LLM backends for card generation.
// Created as part of MVP0 Day 1 — data layer.
// Locked: 2026-07-26 (Round 6 D-039, D-041).
// Priority order: Apple Foundation Models -> Qwen 4B -> Qwen 3B.

import Foundation

public enum LLMBackend: String, Codable, Sendable, CaseIterable {
    case appleFoundation = "appleFoundation"
    case qwen4b = "qwen4b"
    case qwen3b = "qwen3b"

    /// User-facing label for the Settings picker.
    public var displayLabel: String {
        switch self {
        case .appleFoundation: return "Apple Foundation Models"
        case .qwen4b: return "Qwen 2.5 4B"
        case .qwen3b: return "Qwen 2.5 3B"
        }
    }

    public var subtitle: String {
        switch self {
        case .appleFoundation: return "Default · Free · 0 GB app size"
        case .qwen4b: return "Bundled · Best quality"
        case .qwen3b: return "Bundled · Lower thermals"
        }
    }

    /// Priority order for auto-fallback (lower number = higher priority).
    public var fallbackPriority: Int {
        switch self {
        case .appleFoundation: return 0
        case .qwen4b: return 1
        case .qwen3b: return 2
        }
    }

    /// All backends sorted by fallback priority.
    public static var allByPriority: [LLMBackend] {
        allCases.sorted { $0.fallbackPriority < $1.fallbackPriority }
    }
}
