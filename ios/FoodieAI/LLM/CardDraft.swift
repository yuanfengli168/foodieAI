// CardDraft.swift
// Lean representation of an LLM-generated dish card (Day 3).
//
// We intentionally do NOT reuse `Dish` here for three reasons:
//   1. LLMs sometimes produce only a subset of fields (flavor profile often
//      gets truncated). Treat the draft as a partial / candidate record.
//   2. We want the parser to fail loudly on type mismatches; `Dish` has
//      Codable as the primary contract and we don't want JSON coming from
//      a model to silently overwrite the curated data layer.
//   3. MVP0 only needs the "human-readable" fields — name, intro, pair_with.
//      Flavor profile + region are not in this draft; Day 5 may extend.
//
// `JSONCardDecoder` parses raw JSON into `CardDraft` with strict type checks.

import Foundation

public struct CardDraft: Equatable, Sendable {
    public let nameZh: String?
    public let nameEn: String?
    public let introEn: String
    public let introZh: String?
    public let pairWithEn: [String]
    public let region: String?

    public init(
        nameZh: String? = nil,
        nameEn: String? = nil,
        introEn: String,
        introZh: String? = nil,
        pairWithEn: [String] = [],
        region: String? = nil
    ) {
        self.nameZh = nameZh
        self.nameEn = nameEn
        self.introEn = introEn
        self.introZh = introZh
        self.pairWithEn = pairWithEn
        self.region = region
    }
}

/// Parses raw JSON from the LLM into a `CardDraft`.
///
/// Strict policy (deliberate choice — see Decision-AI question Q-001):
///   - JSON must decode without throwing.
///   - The `intro_en` field is REQUIRED. If missing, throw a typed error so
///     the orchestrator can retry once with a stricter prompt.
///   - Other fields are optional. A missing `name_zh` is acceptable for
///     English-only menus; the orchestrator fills it from `Dish.nameZh`.
///
/// The actual JSON keys are snake_case to match what the prompt tells the
/// model to emit ("respond in JSON with these snake_case keys").
public enum CardJSONDecoder {
    public struct DecodingError: Error, LocalizedError {
        public let detail: String
        public var errorDescription: String? {
            "Card JSON could not be parsed: \(detail)"
        }
    }

    /// Try to decode a JSON string into a CardDraft.
    /// Throws `DecodingError` for any parse failure with a human-readable
    /// detail string.
    public static func decode(_ raw: String) throws -> CardDraft {
        let data = Data(raw.utf8)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw DecodingError(detail: "top-level is not a JSON object")
        }

        let nameZh = json["name_zh"] as? String
        let nameEn = json["name_en"] as? String

        guard let introEn = json["intro_en"] as? String, !introEn.isEmpty else {
            throw DecodingError(detail: "missing required `intro_en` field")
        }

        let introZh = json["intro_zh"] as? String
        let region = json["region"] as? String

        let pairWithEn: [String]
        if let rawList = json["pair_with_en"] as? [Any] {
            pairWithEn = rawList.compactMap { $0 as? String }
        } else {
            pairWithEn = []
        }

        return CardDraft(
            nameZh: nameZh,
            nameEn: nameEn,
            introEn: introEn,
            introZh: introZh,
            pairWithEn: pairWithEn,
            region: region
        )
    }

    /// Convenience: encode a `CardDraft` back to JSON (used in tests only).
    public static func encode(_ draft: CardDraft) throws -> String {
        var dict: [String: Any] = [:]
        if let v = draft.nameZh     { dict["name_zh"]      = v }
        if let v = draft.nameEn     { dict["name_en"]      = v }
        dict["intro_en"] = draft.introEn
        if let v = draft.introZh    { dict["intro_zh"]     = v }
        if !draft.pairWithEn.isEmpty { dict["pair_with_en"] = draft.pairWithEn }
        if let v = draft.region     { dict["region"]       = v }
        let data = try JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys])
        return String(decoding: data, as: UTF8.self)
    }
}
