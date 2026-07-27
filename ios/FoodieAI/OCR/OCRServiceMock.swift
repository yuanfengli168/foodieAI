// OCRServiceMock.swift
// Day 5 — Test double for OCRService (R12 D-094).
//
// Three inits cover all the patterns the orchestrator needs to assert:
//   - scripted lines (happy path)
//   - throws with a given OCRError (error path)
//   - returns no lines (noTextFound path, but we model that as an empty
//     array, not a throw — see OCRService.recognize doc comment)
//
// All inits track `callCount` so tests can assert the orchestrator retries
// at most once.

import Foundation
#if canImport(UIKit)
import UIKit
#endif

public final class OCRServiceMock: OCRService, @unchecked Sendable {
    public let displayLabel: String
    private let scripted: Deque<[OCRLine]>
    private let injectedError: OCRError?
    public private(set) var callCount: Int = 0

    public init(displayLabel: String = "MockOCR", scripted lines: [OCRLine]) {
        self.displayLabel = displayLabel
        // Wrap to [[OCRLine]] so the Deque element type matches the field.
        self.scripted = Deque(initial: [lines])
        self.injectedError = nil
    }

    public init(displayLabel: String = "MockOCR", alwaysThrows error: OCRError) {
        self.displayLabel = displayLabel
        self.scripted = Deque(initial: [])
        self.injectedError = error
    }

    public init(
        displayLabel: String = "MockOCR",
        failFirstWith error: OCRError,
        thenReturn: [OCRLine]
    ) {
        self.displayLabel = displayLabel
        self.scripted = Deque(initial: [thenReturn])
        self.injectedError = error
    }

    public func recognize(image: UIImage) async throws -> [OCRLine] {
        callCount += 1
        if callCount == 1, let injectedError {
            throw injectedError
        }
        guard let next = scripted.popFront() else {
            throw OCRError.underlying(reason: "OCRServiceMock ran out of scripted responses")
        }
        return next
    }
}
