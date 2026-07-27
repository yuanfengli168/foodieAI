// CapturedImageStore.swift
// Day 4 — In-memory store for the most recently captured/picked image (R10 D-075).
//
// We have exactly one "current menu" at a time (per Q5 — tmp dir + no
// persistence across launches for MVP0). Day 7 may add a thumbnail strip
// if we want history; for now, single slot.
//
// Threading: `@MainActor` because SwiftUI views observe `current()`
// and we want the read-side to be race-free.
//
// Persistence (R10 D-078): we write a JPEG to the `tmp/` directory when
// `set(_:)` is called and clear it on `clear()`. Tmp dir is wiped by iOS
// at unpredictable times (Apple doesn't promise retention), which is
// exactly the MVP0 contract: "we never need to keep the photo."

import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@MainActor
public final class CapturedImageStore: ObservableObject {
    @Published public private(set) var current: UIImage?
    @Published public private(set) var onDiskPath: String?
    @Published public private(set) var capturedAt: Date?

    public init() {}

    /// Adopt a new image (from camera or library picker). Writes a JPEG
    /// to tmp/ so Day 5's OCR pipeline has a filesystem path if it needs
    /// one (Apple Vision accepts both `CGImage` and `URL`).
    @discardableResult
    public func set(_ image: UIImage) throws -> URL {
        if image.size == .zero { throw CameraError.emptyImage }
        // Persist to tmp
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("foodieai", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        // Use microseconds + UUID suffix so two consecutive calls in the
        // same second don't accidentally reuse the previous filename
        // (which would make the delete-previous step nuke ourselves).
        let filename = "menu-\(UUID().uuidString).jpg"
        let url = dir.appendingPathComponent(filename)
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw CameraError.underlying(reason: "could not encode JPEG")
        }
        try data.write(to: url, options: .atomic)
        // Capture the previous path BEFORE we update onDiskPath, so the
        // delete happens on the prior captured JPEG (not the one we just
        // wrote).
        let prevPath = onDiskPath
        self.current = image
        self.onDiskPath = url.path
        self.capturedAt = Date()
        if let prevPath {
            try? FileManager.default.removeItem(atPath: prevPath)
        }
        return url
    }

    /// Drop the current image (e.g. user tapped Retake).
    public func clear() {
        current = nil
        if let prev = onDiskPath {
            try? FileManager.default.removeItem(atPath: prev)
        }
        onDiskPath = nil
        capturedAt = nil
    }
}
