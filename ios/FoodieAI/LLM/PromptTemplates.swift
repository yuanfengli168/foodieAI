// PromptTemplates.swift
// Centralized prompt strings for the LLM glue (Day 3).
//
// Why this exists as a separate file:
//   - Prompts get iterated on. Keeping them out of the orchestrator lets us
//     swap in A/B variants without touching CardGenerator.
//   - Tests can pin exact strings (no risk of drift if someone rewords a
//     template in production code).
//
// Format policy (locked at R8 D-058):
//   - System prompt is short and enforces JSON-only output with snake_case.
//   - User prompt is two-line: WHO (the dish) + WHERE (the trigger query).
//   - On retry the system prompt adds a stricter reminder.

import Foundation

public enum PromptTemplates {

    // MARK: - System prompt

    /// First-try system prompt. Asks for JSON, snake_case keys, and a 2-3
    /// sentence English intro.
    public static let systemFirst: String = """
    You are a culinary translator for a foreign-menu app. Respond ONLY in valid JSON.
    Use exactly these snake_case keys: name_zh, name_en, intro_en, intro_zh, pair_with_en, region.
    intro_en is required (2-3 sentences, evocative, no marketing fluff).
    All other keys are optional and may be omitted when unknown.
    Never wrap output in markdown fences.
    """

    /// Retry system prompt. Same as `systemFirst` but with an explicit
    /// reminder that the previous response failed to parse.
    public static let systemRetry: String = """
    You are a culinary translator for a foreign-menu app. Respond ONLY in valid JSON.
    Your previous response could not be parsed — it likely had unescaped quotes or was not valid JSON.
    Use exactly these snake_case keys: name_zh, name_en, intro_en, intro_zh, pair_with_en, region.
    intro_en is required (2-3 sentences, evocative, no marketing fluff).
    All other keys are optional and may be omitted when unknown.
    Output must be parseable by JSON.parse with no preprocessing.
    """

    // MARK: - User prompt

    /// Build the user prompt for a dish the user has tapped on a menu.
    /// The prompt includes the already-curated `Dish.nameEn` so the model
    /// doesn't have to guess the canonical spelling.
    public static func userPrompt(for dish: Dish, query: String) -> String {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let dishName = dish.nameEn.isEmpty ? dish.id : dish.nameEn
        let zh = dish.nameZh.isEmpty ? "" : "Chinese name: \(dish.nameZh).\n"
        let pinyin = dish.pinyin.isEmpty ? "" : "Pinyin: \(dish.pinyin).\n"
        return """
        Dish: \(dishName)
        \(zh)\(pinyin)User typed: "\(q)"
        Return JSON.
        """
    }

    // MARK: - Sanity

    /// Marker used by `CardGenerator` to test whether a returned string
    /// "looks like" JSON (we do a lightweight pre-check before paying the
    /// cost of `JSONSerialization`).
    public static func looksLikeJSON(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("{") && trimmed.hasSuffix("}")
    }
}
