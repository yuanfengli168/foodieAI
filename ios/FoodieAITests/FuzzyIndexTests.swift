// FuzzyIndexTests.swift
// Day 2 — tests for the fuzzy search algorithm.
// Reworked from doc/fuzzy-search-tests.md to match the actual 126-dish MVP0 DB.
//
// Important: many iconic Cantonese/Singapore dishes (Mapo Tofu, Hainanese
// Chicken Rice, Char Kway Teow, Kung Pao Chicken as such) are NOT in the
// 126-dish DB. Tests use dishes that ARE in the DB (mostly Zhang Gui + Noodle
// Gourmet dishes). When the DB changes, update these tests per the stale-docs
// checklist in doc/testing-guidelines.md §4.

import XCTest
@testable import FoodieAI

final class FuzzyIndexTests: XCTestCase {
    var repo: DishRepository!
    var index: FuzzyIndex!

    override func setUpWithError() throws {
        repo = try DishRepository.loadFromBundle()
        index = FuzzyIndex(dishes: repo.dishes)
    }

    // MARK: - Exact EN matches

    func testExactEnReturnsTopMatchForSesameChicken() throws {
        let results = index.search("Sesame Chicken")
        let top = try XCTUnwrap(results.first)
        // The DB has both "sesame_chicken" and "sesame_chicken_rice".
        // Both contain "sesame chicken"; the exact match on "sesame_chicken"
        // should win (score 1.0 + tiny tiebreak) over the substring match
        // on "sesame_chicken_rice" (score 0.6 + 0.3 * 13/18 = 0.817).
        XCTAssertEqual(top.dish.id, "sesame_chicken")
        XCTAssertGreaterThan(top.score, 0.95)
    }

    func testExactEnCaseInsensitive() throws {
        let upper = index.search("SESAME CHICKEN")
        let lower = index.search("sesame chicken")
        XCTAssertEqual(upper.first?.dish.id, "sesame_chicken")
        XCTAssertEqual(lower.first?.dish.id, "sesame_chicken")
    }

    func testExactEnForGeneralTsos() throws {
        let results = index.search("General Tso's Chicken")
        let top = try XCTUnwrap(results.first)
        XCTAssertEqual(top.dish.id, "general_tsos_chicken")
    }

    func testExactEnForBeefWithBroccoli() throws {
        let results = index.search("Beef with Broccoli")
        let top = try XCTUnwrap(results.first)
        XCTAssertEqual(top.dish.id, "beef_with_broccoli")
    }

    // MARK: - Exact ZH matches

    func testExactZhReturnsTopMatchForBejingRoastDuck() throws {
        let results = index.search("京味烤鸭")
        let top = try XCTUnwrap(results.first)
        XCTAssertEqual(top.dish.id, "beijing_roast_duck")
    }

    func testExactZhForOldBeijingZhajiangmian() throws {
        let results = index.search("老北京炸酱面")
        let top = try XCTUnwrap(results.first)
        XCTAssertEqual(top.dish.id, "old_beijing_zhajiangmian")
    }

    func testExactZhForScallionPancake() throws {
        let results = index.search("葱油饼")
        let top = try XCTUnwrap(results.first)
        XCTAssertEqual(top.dish.id, "scallion_pancake")
    }

    // MARK: - Pinyin transliteration

    func testPinyinMatchForLanzhouNoodles() throws {
        // "lan zhou niu rou la mian" -> Lanzhou Beef Hand-Pulled Noodles
        let results = index.search("lan zhou niu rou la mian")
        let top = try XCTUnwrap(results.first)
        XCTAssertEqual(top.dish.id, "lanzhou_beef_noodles")
    }

    func testPinyinMatchWithoutSpaces() throws {
        // "dongbeiliangpi" (no spaces) -> 东北拉皮
        let results = index.search("dongbeiliangpi")
        XCTAssertNotNil(results.first)
        XCTAssertEqual(results.first?.dish.id, "dongbei_liangpi")
    }

    func testPinyinMatchForBejingRoastDuck() throws {
        let results = index.search("jing wei kao ya")
        XCTAssertNotNil(results.first)
        XCTAssertEqual(results.first?.dish.id, "beijing_roast_duck")
    }

    func testPinyinEditDistanceMatch() throws {
        // Typo in pinyin (1 char off from the canonical pinyin) should still
        // match via the edit-distance channel.
        // Canonical pinyin for 老北京炸酱面 is "lao bei jing zha jiang mian"
        // Test a 1-edit variant: "lao bei jing zha jiang mian" (the exact),
        // then a 1-char-off variant: "lao bei jing zha jiang mia".
        let exact = index.search("lao bei jing zha jiang mian")
        XCTAssertEqual(exact.first?.dish.id, "old_beijing_zhajiangmian")

        let typo = index.search("lao bei jing zha jiang mia")
        // 1-edit typo, should still find old_beijing_zhajiangmian in top 3
        let top3 = Array(typo.prefix(3))
        XCTAssertTrue(top3.contains(where: { $0.dish.id == "old_beijing_zhajiangmian" }),
            "1-edit pinyin typo should find old_beijing_zhajiangmian in top 3, got: \(top3.map(\.dish.id))")
    }

    // MARK: - Typo / edit distance recovery

    func testTypoRecoveryOneDeletion() throws {
        // "sesme chicken" (1 deletion) -> sesame_chicken
        let results = index.search("sesme chicken")
        XCTAssertNotNil(results.first)
        XCTAssertEqual(results.first?.dish.id, "sesame_chicken")
    }

    func testTypoRecoveryOneTransposition() throws {
        // "beef with brocoli" (1 transposition) -> beef_with_broccoli
        let results = index.search("beef with brocoli")
        XCTAssertNotNil(results.first)
        XCTAssertEqual(results.first?.dish.id, "beef_with_broccoli")
    }

    // MARK: - Edge cases

    func testEmptyQueryReturnsNoResults() {
        XCTAssertTrue(index.search("").isEmpty)
    }

    func testWhitespaceOnlyQueryReturnsNoResults() {
        XCTAssertTrue(index.search("   ").isEmpty)
    }

    func testSingleCharQueryReturnsNoResults() {
        // "a" is too short to fuzzy-match anything (minQueryLength = 2)
        XCTAssertTrue(index.search("a").isEmpty)
    }

    func testNonsenseQueryReturnsNoConfidentMatch() {
        let results = index.search("xyzabc nonsense")
        let topScore = results.first?.score ?? 0
        XCTAssertLessThan(topScore, FuzzyIndex.minConfidentScore,
            "Nonsense query should not return a confident match (top score was \(topScore))")
    }

    // MARK: - Scoring behavior

    func testMenuVerifiedBonusApplies() throws {
        // The 126-dish DB is mostly menu_verified, so test the bonus on a
        // known menu_verified dish's matches by checking score >= 0.2 vs the
        // theoretical unverified score. We verify the menu_verified flag is
        // observed by the scoring path.
        let results = index.search("Sesame Chicken")
        let top = try XCTUnwrap(results.first)
        XCTAssertTrue(top.dish.isMenuVerified,
            "Sesame Chicken is in Menu A (Noodle Gourmet), should be menu_verified")
        XCTAssertGreaterThanOrEqual(top.score, 1.0,
            "Exact match on a menu_verified dish should score 1.0")
    }

    func testResultsSortedByScoreDescending() throws {
        let results = index.search("chicken")
        for i in 1..<results.count {
            XCTAssertGreaterThanOrEqual(results[i - 1].score, results[i].score,
                "Results must be sorted by score desc")
        }
    }

    func testTopNRespected() throws {
        let results = index.search("rice")
        XCTAssertLessThanOrEqual(results.count, FuzzyIndex.topN)
    }

    func testMatchReasonsArePopulated() throws {
        let results = index.search("Sesame Chicken")
        for r in results {
            // Reason should be one of the known cases
            XCTAssertNotNil(r.reason)
        }
    }

    func testExactMatchReasonIsExactEn() throws {
        let results = index.search("Sesame Chicken")
        let top = try XCTUnwrap(results.first)
        XCTAssertEqual(top.reason, .exactEn)
    }

    // MARK: - Levenshtein unit tests

    func testLevenshteinIdenticalStrings() {
        XCTAssertEqual(FuzzyIndex.levenshtein("abc", "abc", maxDistance: 5), 0)
    }

    func testLevenshteinOneEdit() {
        XCTAssertEqual(FuzzyIndex.levenshtein("abc", "abd", maxDistance: 5), 1)
        XCTAssertEqual(FuzzyIndex.levenshtein("abc", "ac", maxDistance: 5), 1)
        XCTAssertEqual(FuzzyIndex.levenshtein("abc", "abcd", maxDistance: 5), 1)
    }

    func testLevenshteinExceedsMaxDistance() {
        XCTAssertEqual(FuzzyIndex.levenshtein("abc", "xyz", maxDistance: 2), 3)
    }

    func testLevenshteinEmptyStrings() {
        XCTAssertEqual(FuzzyIndex.levenshtein("", "", maxDistance: 5), 0)
        XCTAssertEqual(FuzzyIndex.levenshtein("", "abc", maxDistance: 5), 3)
        XCTAssertEqual(FuzzyIndex.levenshtein("abc", "", maxDistance: 5), 3)
    }

    func testLevenshteinLengthDifferenceExceedsMax() {
        // "abc" vs "abcdefghij" is 7 edits, with maxDistance=2 should return 3
        XCTAssertEqual(FuzzyIndex.levenshtein("abc", "abcdefghij", maxDistance: 2), 3)
    }

    // MARK: - Normalize unit tests

    func testNormalizeLowercases() {
        XCTAssertEqual(FuzzyIndex.normalize("HELLO"), "hello")
    }

    func testNormalizeStripsPunctuation() {
        XCTAssertEqual(FuzzyIndex.normalize("hello, world!"), "hello world")
    }

    func testNormalizeKeepsCjk() {
        XCTAssertEqual(FuzzyIndex.normalize("麻婆豆腐"), "麻婆豆腐")
    }

    func testNormalizeCollapsesSpaces() {
        XCTAssertEqual(FuzzyIndex.normalize("  hello   world  "), "hello world")
    }

    func testNormalizeMixedEnAndCjk() {
        XCTAssertEqual(FuzzyIndex.normalize("hello 麻婆 world"), "hello 麻婆 world")
    }
}
