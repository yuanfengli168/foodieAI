// FuzzyIndex.swift
// Day 2 — fuzzy search across the 126-dish bundle.
//
// Strategy (locked 2026-07-26, MVP0):
//   1. Normalize input: lowercase, strip punctuation, trim whitespace.
//   2. Require minQueryLength chars (else return []).
//   3. Candidate generation across 3 channels:
//      a. EN substring match against name_en + aliases_en
//      b. EN Levenshtein (≤2 edits) against name_en + aliases_en
//      c. Pinyin Levenshtein (≤2 edits) against pinyin
//      d. ZH substring match against name_zh + aliases_zh
//   4. Score each candidate:
//        exact match > substring match > edit-distance match
//        exact_en = 1.0
//        substring_en = 0.6..0.9 (higher when overlap is larger)
//        edit_en = 1.0 - dist/max(len)
//        exact_pinyin = 1.0
//        edit_pinyin = 1.0 - dist/max(len) + 0.3
//        substring_zh = 0.6
//        + 0.2 if menu_verified (capped at 1.0)
//        + tiny tiebreak favoring exact matches
//   5. Return top N sorted by score desc.
//   6. If top score < 0.5: "no confident match" (caller decides).
//
// No synonym map in MVP0 (R5 Q5 -> deferred to MVP1).
// No pinyin library in MVP0 (R6 -> hand-rolled PinyinConverter for the 126 dishes).
//
// See doc/mvp0-plan.md §4 for the original spec.

import Foundation

public struct FuzzyMatch: Hashable, Sendable {
    public let dish: Dish
    public let score: Double
    /// Why this candidate matched. Useful for debugging and for the
    /// "no confident match" UX in MVP1's OCR review screen.
    public let reason: MatchReason

    public enum MatchReason: String, Hashable, Sendable {
        case exactEn = "exact-en"
        case substringEn = "substring-en"
        case editEn = "edit-en"
        case substringZh = "substring-zh"
        case exactPinyin = "exact-pinyin"
        case editPinyin = "edit-pinyin"
    }
}

public struct FuzzyIndex: Sendable {
    public static let topN = 10
    public static let minConfidentScore = 0.5
    /// Minimum query length to run a search. Below this, return empty.
    public static let minQueryLength = 2

    private let dishes: [Dish]
    private let pinyinConverter: PinyinConverter
    private let indexedPinyins: [(id: String, pinyin: String)]

    public init(dishes: [Dish]) {
        self.dishes = dishes
        let converter = PinyinConverter(dishes: dishes)
        self.pinyinConverter = converter
        self.indexedPinyins = dishes.compactMap { d in
            let p = d.pinyin.trimmingCharacters(in: .whitespacesAndNewlines)
            return p.isEmpty ? nil : (id: d.id, pinyin: p)
        }
    }

    /// Public for testing. Normalize a query: lowercase, drop non-letter/non-number/non-CJK punctuation to spaces, trim.
    public static func normalize(_ s: String) -> String {
        var out = ""
        for ch in s.lowercased() {
            if ch.isLetter || ch.isNumber || ch.isWhitespace {
                out.append(ch)
            } else if let v = ch.unicodeScalars.first?.value, v > 0x2E80 {
                // CJK Unified Ideographs and beyond — keep as-is
                out.append(ch)
            } else {
                // punctuation / other symbols — drop to space
                out.append(" ")
            }
        }
        return out.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    /// Run the fuzzy search pipeline on the query.
    /// Returns up to `Self.topN` matches, sorted by score desc.
    public func search(_ query: String) -> [FuzzyMatch] {
        let q = Self.normalize(query)
        guard q.count >= Self.minQueryLength else { return [] }

        var matches: [String: (score: Double, reason: FuzzyMatch.MatchReason)] = [:]

        // Channel A + B: EN substring + Levenshtein against name_en + aliases_en
        for d in dishes {
            let enTargets = [d.nameEn.lowercased()] + d.aliasesEn.map { $0.lowercased() }
            for t in enTargets where !t.isEmpty {
                if t == q {
                    // Exact match wins
                    record(dishId: d.id, score: 1.0, reason: .exactEn, into: &matches)
                } else if t.contains(q) {
                    // Query is a substring of target — favor shorter targets (more specific).
                    // Perfect coverage (t.count == q.count) gets a 0.95 to beat partial matches.
                    let coverage = Double(q.count) / Double(t.count)
                    let s: Double = (coverage >= 0.999) ? 0.95 : (0.6 + 0.3 * coverage)
                    record(dishId: d.id, score: s, reason: .substringEn, into: &matches)
                } else if q.contains(t) && t.count >= 3 {
                    // Target is a substring of query (rare) — also count
                    let coverage = Double(t.count) / Double(q.count)
                    let s = 0.6 + 0.2 * coverage  // range 0.6..0.8
                    record(dishId: d.id, score: s, reason: .substringEn, into: &matches)
                } else {
                    let dist = Self.levenshtein(q, t, maxDistance: 2)
                    if dist <= 2 {
                        let norm = 1.0 - Double(dist) / Double(max(q.count, t.count))
                        record(dishId: d.id, score: norm, reason: .editEn, into: &matches)
                    }
                }
            }
        }

        // Channel C: Pinyin Levenshtein against dish pinyin
        for (id, pinyin) in indexedPinyins {
            if pinyin == q {
                record(dishId: id, score: 1.0, reason: .exactPinyin, into: &matches)
            } else if pinyin.contains(q) || q.contains(pinyin) {
                let coverage = Double(min(q.count, pinyin.count)) / Double(max(q.count, pinyin.count))
                let s = 0.6 + 0.3 * coverage + 0.3  // substring pinyin boost
                record(dishId: id, score: s, reason: .editPinyin, into: &matches)
            } else {
                let dist = Self.levenshtein(q, pinyin, maxDistance: 2)
                if dist <= 2 {
                    let norm = 1.0 - Double(dist) / Double(max(q.count, pinyin.count))
                    let boosted = norm + 0.3  // pinyin match is a strong signal
                    record(dishId: id, score: boosted, reason: .editPinyin, into: &matches)
                }
            }
        }

        // Channel D: ZH substring against name_zh + aliases_zh
        for d in dishes {
            let zhTargets = [d.nameZh] + d.aliasesZh
            for t in zhTargets where !t.isEmpty {
                if t.contains(q) || q.contains(t) {
                    record(dishId: d.id, score: 0.6, reason: .substringZh, into: &matches)
                }
            }
        }

        // Bonus: menu_verified (per MVP0 spec) + exact-match tiebreaker.
        // We allow scores to exceed 1.0 internally so the exact-match tiebreak survives;
        // the caller can clamp if needed (the "no confident match" check uses
        // minConfidentScore which is well below 1.0 anyway).
        var scored: [FuzzyMatch] = []
        for (id, entry) in matches {
            guard let dish = dishes.first(where: { $0.id == id }) else { continue }
            var score = entry.score
            if dish.isMenuVerified { score += 0.2 }
            // Tiebreak: exact-match reasons sort ahead of substring, substring ahead of edit
            let tieBreak: Double
            switch entry.reason {
            case .exactEn, .exactPinyin: tieBreak = 0.01
            case .substringEn, .substringZh: tieBreak = 0.005
            case .editEn, .editPinyin: tieBreak = 0.0
            }
            scored.append(FuzzyMatch(dish: dish, score: score + tieBreak, reason: entry.reason))
        }
        return scored.sorted { $0.score > $1.score }.prefix(Self.topN).map { $0 }
    }

    private func record(dishId: String, score: Double, reason: FuzzyMatch.MatchReason,
                        into matches: inout [String: (score: Double, reason: FuzzyMatch.MatchReason)]) {
        if let existing = matches[dishId] {
            if score > existing.score {
                matches[dishId] = (score, reason)
            }
        } else {
            matches[dishId] = (score, reason)
        }
    }

    /// Iterative Levenshtein with early termination. Returns edit distance,
    /// or `maxDistance + 1` if it exceeds the cap (signals "no match").
    public static func levenshtein(_ a: String, _ b: String, maxDistance: Int) -> Int {
        let aChars = Array(a)
        let bChars = Array(b)
        let n = aChars.count
        let m = bChars.count
        if abs(n - m) > maxDistance { return maxDistance + 1 }
        if n == 0 { return m <= maxDistance ? m : maxDistance + 1 }
        if m == 0 { return n <= maxDistance ? n : maxDistance + 1 }

        var prev = Array(0...m)
        var curr = [Int](repeating: 0, count: m + 1)
        for i in 1...n {
            curr[0] = i
            var rowMin = i
            for j in 1...m {
                let cost = aChars[i - 1] == bChars[j - 1] ? 0 : 1
                curr[j] = min(
                    curr[j - 1] + 1,        // insertion
                    prev[j] + 1,            // deletion
                    prev[j - 1] + cost      // substitution
                )
                if curr[j] < rowMin { rowMin = curr[j] }
            }
            if rowMin > maxDistance { return maxDistance + 1 }
            swap(&prev, &curr)
        }
        return prev[m] <= maxDistance ? prev[m] : maxDistance + 1
    }
}
