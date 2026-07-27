// LLMError.swift
// Typed errors for the LLM service layer (Day 3).
//
// We follow the project's testing-guidelines policy: every error has
// (1) a stable enum case, (2) an errorDescription the UI can show.
// Five cases covers MVP0 — bigger surface area added on Day 7.

import Foundation

public enum LLMError: Error, LocalizedError, Equatable, Sendable {
    /// The chosen backend is not currently available on this device. Example:
    /// Apple Intelligence turned off in iOS Settings, or MLX-Swift model not
    /// yet downloaded.
    case backendUnavailable(reason: String)

    /// The model was loaded, the prompt was sent, but the response did not
    /// parse as expected after the retry budget was exhausted.
    case malformedResponse(reason: String)

    /// Generation was cancelled mid-flight (user navigated away, app
    /// backgrounded, etc.).
    case cancelled

    /// The backend hit an OS-level guardrail (e.g. Apple Foundation Model's
    /// `refusal` trigger). We treat this as a real failure, not a parse
    /// failure, so the UI can suggest rephrasing the input.
    case refused(reason: String)

    /// Anything else: simulator out of memory, network-on-device glitch,
    /// MLX context overflow, etc.
    case underlying(reason: String)

    public var errorDescription: String? {
        switch self {
        case .backendUnavailable(let reason):
            return "This language model isn't available right now. (\(reason))"
        case .malformedResponse(let reason):
            return "The model returned a response we couldn't read. (\(reason))"
        case .cancelled:
            return "Generation was cancelled."
        case .refused(let reason):
            return "The model declined to answer. (\(reason))"
        case .underlying(let reason):
            return "Something went wrong while generating the card. (\(reason))"
        }
    }

    /// Short machine-readable tag for tests and logging. Avoid relying on
    /// `errorDescription` for equality.
    public var tag: String {
        switch self {
        case .backendUnavailable: return "backend_unavailable"
        case .malformedResponse:  return "malformed_response"
        case .cancelled:          return "cancelled"
        case .refused:            return "refused"
        case .underlying:         return "underlying"
        }
    }
}
