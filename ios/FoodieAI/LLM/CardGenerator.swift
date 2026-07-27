// CardGenerator.swift
// Orchestrator that turns a `Dish` + the user's `query` into a `CardDraft`.
//
// Pipeline (locked at R8 D-058):
//   1. Try once with the lax system prompt.
//   2. If the response doesn't look like JSON or fails to parse, retry
//      exactly once with the strict system prompt + a "previous response
//      failed to parse" hint.
//   3. After 2 attempts, throw `.malformedResponse` with the second
//      attempt's detail line, so the UI can surface why.
//
// We deliberately keep retries at 1 — LLMs that fail twice in a row almost
// never recover on attempt 3, and a long retry chain looks like a hang to
// the user. Day 7 may add a "regenerate" button that the user can manually
// re-trigger.

import Foundation

public struct CardGenerator: Sendable {
    private let service: any LLMService

    public init(service: any LLMService) {
        self.service = service
    }

    /// Generate a card draft for `dish` triggered by the user's `query`.
    /// `query` is what the user typed into the search box; it's preserved
    /// in the prompt verbatim because models occasionally use it as a hint
    /// for which script the user wants the response in.
    public func generate(for dish: Dish, query: String) async throws -> CardDraft {
        // First try — lax prompt.
        do {
            let draft = try await attempt(
                dish: dish,
                query: query,
                system: PromptTemplates.systemFirst,
                attempt: 1
            )
            return draft
        } catch let error as LLMError {
            // Surface backend availability / refusal / cancellation as-is.
            switch error {
            case .backendUnavailable, .cancelled, .refused:
                throw error
            case .malformedResponse, .underlying:
                break // fall through to retry
            }
            // Retry once with stricter prompt.
            do {
                let draft = try await attempt(
                    dish: dish,
                    query: query,
                    system: PromptTemplates.systemRetry,
                    attempt: 2
                )
                return draft
            } catch let retryError as LLMError {
                // Second failure → rethrow as malformedResponse so the UI
                // sees one consistent error type.
                throw LLMError.malformedResponse(
                    reason: "after 2 attempts; first=\(error.tag), second=\(retryError.tag)"
                )
            }
        }
    }

    // MARK: - Private

    private func attempt(
        dish: Dish,
        query: String,
        system: String,
        attempt: Int
    ) async throws -> CardDraft {
        guard await service.isAvailable else {
            throw LLMError.backendUnavailable(reason: "\(service.displayLabel) reports unavailable")
        }
        let combinedPrompt = combinedPrompt(system: system, user: PromptTemplates.userPrompt(for: dish, query: query))
        let raw = try await service.generate(prompt: combinedPrompt)
        return try parseOrThrow(raw, attempt: attempt)
    }

    /// Build the final prompt. We pre-pend the system prompt so a backend
    /// that doesn't grok system-only messages (some quantized MLX models
    /// flatten "system:" into "user:") still has the instructions.
    private func combinedPrompt(system: String, user: String) -> String {
        "System: \(system)\n\nUser: \(user)"
    }

    private func parseOrThrow(_ raw: String, attempt: Int) throws -> CardDraft {
        if !PromptTemplates.looksLikeJSON(raw) {
            throw LLMError.malformedResponse(reason: "attempt \(attempt): response did not start with {")
        }
        do {
            return try CardJSONDecoder.decode(raw)
        } catch let decodeError as CardJSONDecoder.DecodingError {
            throw LLMError.malformedResponse(reason: "attempt \(attempt): \(decodeError.detail)")
        }
    }
}
