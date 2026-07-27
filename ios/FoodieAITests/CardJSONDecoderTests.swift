// CardJSONDecoderTests.swift
// Day 3 — Unit tests for parsing LLM responses into a CardDraft.
//
// We test the policy the orchestrator relies on:
//   - JSON must parse as an object.
//   - `intro_en` is required.
//   - Other fields are optional.
//   - Pretty-printed JSON, malformed JSON, and non-object JSON all fail
//     with a human-readable `detail`.

import XCTest
@testable import FoodieAI

final class CardJSONDecoderTests: XCTestCase {

    func test_minimal_valid_json_with_just_intro() {
        let raw = #"{"intro_en":"A dumpling of pork and ginger, steamed in bamboo."}"#
        let draft = try! CardJSONDecoder.decode(raw)
        XCTAssertEqual(draft.introEn, "A dumpling of pork and ginger, steamed in bamboo.")
        XCTAssertNil(draft.nameZh)
        XCTAssertNil(draft.nameEn)
        XCTAssertNil(draft.introZh)
        XCTAssertTrue(draft.pairWithEn.isEmpty)
        XCTAssertNil(draft.region)
    }

    func test_full_payload_decodes_all_fields() {
        let raw = """
        {
          "name_zh": "小笼包",
          "name_en": "Xiaolongbao",
          "intro_en": "Paper-thin dumplings filled with pork and broth.",
          "intro_zh": "皮薄如纸的灌汤包",
          "pair_with_en": ["ginger tea", "red vinegar"],
          "region": "Shanghai"
        }
        """
        let draft = try! CardJSONDecoder.decode(raw)
        XCTAssertEqual(draft.nameZh, "小笼包")
        XCTAssertEqual(draft.nameEn, "Xiaolongbao")
        XCTAssertEqual(draft.introEn, "Paper-thin dumplings filled with pork and broth.")
        XCTAssertEqual(draft.introZh, "皮薄如纸的灌汤包")
        XCTAssertEqual(draft.pairWithEn, ["ginger tea", "red vinegar"])
        XCTAssertEqual(draft.region, "Shanghai")
    }

    func test_pretty_printed_json_is_accepted() {
        let raw = """
        {
            "intro_en": "Hand-pulled noodles in a clear broth.",
            "intro_zh": "清汤手擀面"
        }
        """
        let draft = try! CardJSONDecoder.decode(raw)
        XCTAssertEqual(draft.introEn, "Hand-pulled noodles in a clear broth.")
        XCTAssertEqual(draft.introZh, "清汤手擀面")
    }

    func test_missing_intro_en_throws() {
        let raw = #"{"name_en":"Peking duck"}"#
        XCTAssertThrowsError(try CardJSONDecoder.decode(raw)) { error in
            guard let e = error as? CardJSONDecoder.DecodingError else {
                return XCTFail("Expected CardJSONDecoder.DecodingError, got \(error)")
            }
            XCTAssertTrue(e.detail.contains("intro_en"))
        }
    }

    func test_empty_intro_en_throws() {
        let raw = #"{"intro_en":""}"#
        XCTAssertThrowsError(try CardJSONDecoder.decode(raw)) { error in
            guard let e = error as? CardJSONDecoder.DecodingError else {
                return XCTFail("Expected CardJSONDecoder.DecodingError, got \(error)")
            }
            XCTAssertTrue(e.detail.contains("intro_en"))
        }
    }

    func test_non_object_json_throws() {
        let raw = #"["not","an","object"]"#
        XCTAssertThrowsError(try CardJSONDecoder.decode(raw))
    }

    func test_malformed_json_throws() {
        let raw = #"{ "intro_en": "no quotes }"#
        XCTAssertThrowsError(try CardJSONDecoder.decode(raw))
    }

    func test_pair_with_en_drops_non_string_entries() {
        // We saw an LLM emit ["rice", 42, true] once; the int and bool
        // should be silently dropped, not crash decoding.
        let raw = #"{"intro_en":"x","pair_with_en":["rice",42,true]}"#
        let draft = try! CardJSONDecoder.decode(raw)
        XCTAssertEqual(draft.pairWithEn, ["rice"])
    }

    func test_round_trip_via_encode() {
        let original = CardDraft(
            nameZh: "宫保鸡丁",
            nameEn: "Kung Pao Chicken",
            introEn: "Wok-fried chicken with peanuts and dried chilies.",
            introZh: "宫保鸡丁",
            pairWithEn: ["rice", "tea"],
            region: "Sichuan"
        )
        let json = try! CardJSONDecoder.encode(original)
        let decoded = try! CardJSONDecoder.decode(json)
        XCTAssertEqual(decoded, original)
    }

    func test_decoding_error_has_description() {
        let e = CardJSONDecoder.DecodingError(detail: "missing intro_zh")
        XCTAssertEqual(e.errorDescription, "Card JSON could not be parsed: missing intro_zh")
    }

    func test_encode_round_trip_with_only_required_intro() {
        let original = CardDraft(introEn: "Plain")
        let json = try! CardJSONDecoder.encode(original)
        let decoded = try! CardJSONDecoder.decode(json)
        XCTAssertEqual(decoded.introEn, "Plain")
        XCTAssertNil(decoded.nameZh)
    }
}
