// OCRPanel.swift
// Day 5 — Renders the OCR result inside the smoke view (R12 D-098).
//
// Shows whichever case the most recent `MenuProcessingResult` had:
//   - .parsed(ocrLines, matchedDishes, unmatchedLines, label)
//       → "X matched dishes" + a list of dish names + "Y unmatched lines"
//   - .received/errored from the Day-4 stub path → re-styled strings
//
// Day 6's ContentView replaces this with the production OCR result card
// (matching the Apple's Photos app aesthetic), but the surface area is
// the same: lines + matches.

import SwiftUI

public struct OCRPanel: View {
    let result: MenuProcessingResult?

    public init(result: MenuProcessingResult?) {
        self.result = result
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("OCR (Day 5)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(red: 0x2A/255, green: 0x25/255, blue: 0x22/255))
            switch result {
            case .none:
                Text("Tap Process menu after capturing a photo to see OCR lines + dish matches.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .parsed(let lines, let matched, let unmatched, let label):
                ocrBody(lines: lines, matched: matched, unmatched: unmatched, label: label)
            case .received(let bytes, let path, let label):
                Text("Stub processor returned: \(label) • \(bytes) bytes")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
                Text("path=\(path ?? "<none>")")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
            case .errored(let reason):
                Text("[errored] \(reason)")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0xC7/255, green: 0x68/255, blue: 0x3D/255).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    @ViewBuilder
    private func ocrBody(lines: [OCRLine], matched: [Dish], unmatched: [String], label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("By \(label): \(matched.count) matched, \(unmatched.count) unmatched, \(lines.count) OCR lines")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
            if !matched.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Matched dishes:")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(red: 0x7A/255, green: 0x9A/255, blue: 0x6E/255))
                    ForEach(matched, id: \.id) { dish in
                        Text("• \(dish.nameZh.isEmpty ? dish.nameEn : dish.nameZh) (\(dish.nameEn))")
                            .font(.system(size: 11))
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 0x7A/255, green: 0x9A/255, blue: 0x6E/255).opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            if !unmatched.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Unmatched lines (candidate for LLM card):")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(red: 0xC7/255, green: 0x68/255, blue: 0x3D/255))
                    ForEach(Array(unmatched.prefix(8).enumerated()), id: \.offset) { _, line in
                        Text("• \(line)")
                            .font(.system(size: 11))
                    }
                    if unmatched.count > 8 {
                        Text("… and \(unmatched.count - 8) more")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 0xC7/255, green: 0x68/255, blue: 0x3D/255).opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            if matched.isEmpty && unmatched.isEmpty {
                Text("No recognisable lines in the image.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
