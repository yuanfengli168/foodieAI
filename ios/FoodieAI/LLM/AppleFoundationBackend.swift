// AppleFoundationBackend.swift
// Wraps iOS 26's `LanguageModelSession` for foodieAI's card generation (Day 3).
//
// We expose this through the existing `LLMService` protocol so the rest of the
// app never sees Apple Foundation Models directly. Day 7 may add the Qwen
// fallback alongside; for Day 3 this is the only real backend and the tests
// use `MockLLMService`.
//
// API surface used (R8 D-060):
//   - `LanguageModelSession.GenerationError` is the public error enum in
//     Xcode 26.1 / iOS 26.
//   - Generation is mediated through `LanguageModelSession.respond(to:)`.
//   - The error-mapping is factored out to the public free function
//     `mapAppleFMError` so it's directly unit-testable (without needing a
//     real FM session). See `mapAppleFMErrorTests.swift`.
//
// Availability matrix (R8 D-061):
//   - iOS 26+ device with Apple Intelligence enabled and the LLM model
//     downloaded (Settings → Apple Intelligence → Foundation Model).
//   - iOS 26 Simulator on the simulator we test on reports `.available` for
//     the model but `respond(to:)` currently throws in simulator builds —
//     this is a known platform limitation. We surface that as
//     `.backendUnavailable` so the UI can show "Apple FM is not available
//     in the simulator; run on a device".

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

public final class AppleFoundationBackend: LLMService, @unchecked Sendable {
    public let displayLabel: String = "Apple Foundation Models"

    public init() {}

    public var isAvailable: Bool {
        get async {
            #if canImport(FoundationModels)
            let model = SystemLanguageModel.default
            switch model.availability {
            case .available:
                return true
            case .unavailable:
                return false
            @unknown default:
                return false
            }
            #else
            return false
            #endif
        }
    }

    public func generate(prompt: String) async throws -> String {
        #if canImport(FoundationModels)
        do {
            let session = LanguageModelSession()
            let response = try await session.respond(to: prompt)
            return response.content
        } catch let error as LanguageModelSession.GenerationError {
            throw mapAppleFMError(error)
        } catch {
            throw LLMError.underlying(reason: String(describing: error))
        }
        #else
        throw LLMError.backendUnavailable(
            reason: "Apple Foundation Models are only available on iOS 26+"
        )
        #endif
    }
}

// MARK: - Free-function error mapper (unit-testable)

/// Translate iOS 26 Foundation Models errors into our typed `LLMError`.
///
/// Lives as a free function (not a private method) so we can cover each
/// case explicitly in `mapAppleFMErrorTests.swift`.
///
/// On platforms without FoundationModels (iOS 25 / older simulators) we
/// fall through to a `.backendUnavailable` — those code paths are
/// exercised by tests that simply verify the function is callable.
public func mapAppleFMError(
    _ error: Any
) -> LLMError {
    #if canImport(FoundationModels)
    if let e = error as? LanguageModelSession.GenerationError {
        return mapAppleFMGenerationError(e)
    }
    #endif
    return LLMError.underlying(reason: String(describing: error))
}

#if canImport(FoundationModels)
private func mapAppleFMGenerationError(
    _ error: LanguageModelSession.GenerationError
) -> LLMError {
    switch error {
    case .refusal(_, let context):
        return .refused(reason: context.debugDescription)
    case .guardrailViolation(let context):
        return .refused(reason: "guardrail violation: \(context.debugDescription)")
    case .assetsUnavailable:
        return .backendUnavailable(reason: "Apple FM assets not downloaded (Settings → Apple Intelligence)")
    case .decodingFailure(let context):
        return .malformedResponse(reason: "Apple FM decoding failure: \(context.debugDescription)")
    case .exceededContextWindowSize:
        return .malformedResponse(reason: "Apple FM context window exceeded")
    case .rateLimited:
        return .underlying(reason: "Apple FM rate-limited; retry later")
    case .unsupportedLanguageOrLocale:
        return .backendUnavailable(reason: "Apple FM doesn't support this language/locale")
    case .unsupportedGuide:
        return .underlying(reason: "Unsupported Apple FM generation guide")
    case .concurrentRequests:
        return .underlying(reason: "Apple FM session was used concurrently")
    @unknown default:
        return .underlying(reason: String(describing: error))
    }
}
#endif
