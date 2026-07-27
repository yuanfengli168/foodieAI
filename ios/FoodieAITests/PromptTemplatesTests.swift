// PromptTemplatesTests.swift
// Day 3 — Unit tests for the prompt-template strings used by CardGenerator.
//
// We pin the user-prompt shape so a future refactor that accidentally
// drops the dish name or the user's query catches immediately.

import XCTest
@testable import FoodieAI

final class PromptTemplatesTests: XCTestCase {

    func test_user_prompt_contains_dish_name() throws {
        let dish = try sampleDish(nameEn: "Mapo Tofu")
        let prompt = PromptTemplates.userPrompt(for: dish, query: "mapo")
        XCTAssertTrue(prompt.contains("Mapo Tofu"),
                      "User prompt must echo the dish's English name verbatim")
    }

    func test_user_prompt_contains_user_query_verbatim() throws {
        let dish = try sampleDish(nameEn: "Mapo Tofu")
        let prompt = PromptTemplates.userPrompt(for: dish, query: "spicy tofu please")
        XCTAssertTrue(prompt.contains("spicy tofu please"),
                      "User prompt must echo the user's query exactly")
    }

    func test_user_prompt_includes_zh_when_present() throws {
        let dish = try sampleDish(nameEn: "Mapo Tofu", nameZh: "麻婆豆腐", pinyin: "ma po dou fu")
        let prompt = PromptTemplates.userPrompt(for: dish, query: "tofu")
        XCTAssertTrue(prompt.contains("麻婆豆腐"))
        XCTAssertTrue(prompt.contains("ma po dou fu"))
    }

    func test_user_prompt_omits_zh_when_absent() throws {
        let dish = try sampleDish(nameEn: "Some English Only Dish")
        let prompt = PromptTemplates.userPrompt(for: dish, query: "thing")
        XCTAssertFalse(prompt.contains("Chinese name:"))
        XCTAssertFalse(prompt.contains("Pinyin:"))
    }

    func test_user_prompt_trims_query_whitespace() throws {
        let dish = try sampleDish(nameEn: "Mapo Tofu")
        let prompt = PromptTemplates.userPrompt(for: dish, query: "   mapo   \n")
        XCTAssertTrue(prompt.contains("mapo"), "Should trim around 'mapo'")
        XCTAssertFalse(prompt.contains("   mapo   "), "Should not preserve padding")
    }

    func test_system_first_specifies_snake_case_keys() {
        XCTAssertTrue(PromptTemplates.systemFirst.contains("name_zh"))
        XCTAssertTrue(PromptTemplates.systemFirst.contains("name_en"))
        XCTAssertTrue(PromptTemplates.systemFirst.contains("intro_en"))
        XCTAssertTrue(PromptTemplates.systemFirst.contains("intro_zh"))
        XCTAssertTrue(PromptTemplates.systemFirst.contains("pair_with_en"))
        XCTAssertTrue(PromptTemplates.systemFirst.contains("region"))
    }

    func test_system_retry_mentions_previous_failure() {
        // The retry prompt must explicitly acknowledge the previous failure
        // so models with chat memory reduce the same mistake.
        XCTAssertTrue(PromptTemplates.systemRetry.lowercased().contains("previous"))
    }

    func test_looks_like_json_returns_true_for_object() {
        XCTAssertTrue(PromptTemplates.looksLikeJSON(#"  {"intro_en":"x"}  "#))
        XCTAssertTrue(PromptTemplates.looksLikeJSON("{}"))
    }

    func test_looks_like_json_returns_false_for_array_or_other() {
        XCTAssertFalse(PromptTemplates.looksLikeJSON(#"["item"]"#))
        XCTAssertFalse(PromptTemplates.looksLikeJSON("Sure, here is the JSON: {}"))
        XCTAssertFalse(PromptTemplates.looksLikeJSON(""))
        XCTAssertFalse(PromptTemplates.looksLikeJSON("{} trailing junk"))
    }

    // MARK: - Helpers

    private func sampleDish(
        nameEn: String,
        nameZh: String = "",
        pinyin: String = "",
        aliasesEn: [String] = [],
        aliasesZh: [String] = [],
        region: String = "Test"
    ) throws -> Dish {
        try Dish(
            id: "test_\(nameEn.lowercased().replacingOccurrences(of: " ", with: "_"))",
            nameZh: nameZh,
            nameEn: nameEn,
            pinyin: pinyin,
            aliasesEn: aliasesEn,
            aliasesZh: aliasesZh,
            photoPath: "",
            emojiFallback: "🥘",
            source: .menuVerified,
            sourceUrl: "",
            isMenuVerified: true,
            intro: "",
            flavor: FlavorProfile(spicy: 0, sour: 0, salty: 0, sweet: 0, numbing: 0),
            pairWith: [],
            region: region,
            category: "main",
            tags: []
        )
    }
}
