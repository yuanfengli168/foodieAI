// CameraPanel.swift
// Day 4 — Camera + Library → MenuProcessor panel (R10 D-081).
//
// Mounted inside SmokeTestView under #if DEBUG. This is the Day-4
// milestone surface. Day 6's ContentView will host the same components
// (with a much cleaner layout) but keep this around for smoke testing.
//
// Layout:
//   ┌─ "Camera" section header (with subtitle) ─┐
//   │ [Take photo] [Choose from library]      │ ← action row
//   │ Preview of the captured UIImage         │ ← if `lastImage != nil`
//   │ Status text (camera unavailable, etc.)  │ ← if `errorMessage != nil`
//   │ [Process menu →]                        │ ← handoff stub
//   └──────────────────────────────────────────┘
//
// All logic goes through protocols (CameraService, LibraryPicker,
// MenuProcessor) so the smoke tests can replace any of them.
//
// We deliberately keep auto-capture (Q2) **disabled** here: Day 4 hands
// the user a visible "Take photo" button so we can verify the wiring
// without racing the timer. Day 6's ContentView will turn auto-capture
// back on (per the original R7-D-012 decision).

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct CameraPanel: View {
    @ObservedObject var store: CapturedImageStore
    let cameraService: CameraService
    let libraryPicker: any LibraryPicker
    let processor: any MenuProcessor

    @State private var authStatus: CameraAuthorizationStatus = .notDetermined
    @State private var isCapturing = false
    @State private var isPickingFromLibrary = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var processorResult: String?

    public init(
        store: CapturedImageStore,
        cameraService: CameraService,
        libraryPicker: any LibraryPicker,
        processor: any MenuProcessor
    ) {
        self.store = store
        self.cameraService = cameraService
        self.libraryPicker = libraryPicker
        self.processor = processor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Camera (Day 4)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(red: 0x2A/255, green: 0x25/255, blue: 0x22/255))
            Text("Backend: \(cameraService.displayLabel)")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Button(action: { Task { await captureFromCamera() } }) {
                    HStack {
                        if isCapturing {
                            ProgressView()
                        } else {
                            Text("Take photo")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(red: 0xC7/255, green: 0x68/255, blue: 0x3D/255))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(isCapturing)

                Button(action: { Task { await pickFromLibrary() } }) {
                    HStack {
                        if isPickingFromLibrary {
                            ProgressView()
                        } else {
                            Text("From library")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .foregroundStyle(Color(red: 0x2A/255, green: 0x25/255, blue: 0x22/255))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 0xC7/255, green: 0x68/255, blue: 0x3D/255), lineWidth: 1.5)
                    )
                }
                .disabled(isPickingFromLibrary)
            }

            if let image = store.current {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Captured at \(displayCapturedAt())")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 220)
                        .frame(maxWidth: .infinity)
                        .background(Color.black.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    HStack(spacing: 8) {
                        Button(action: { store.clear() }) {
                            Text("Retake")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .foregroundStyle(Color(red: 0x2A/255, green: 0x25/255, blue: 0x22/255))
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.4)))
                        }
                        Button(action: { Task { await processMenu() } }) {
                            HStack {
                                if isProcessing {
                                    ProgressView()
                                } else {
                                    Text("Process menu →")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color(red: 0x7A/255, green: 0x9A/255, blue: 0x6E/255))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .disabled(isProcessing)
                    }
                }
            } else {
                Text("Capture or pick a menu to continue.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0xC7/255, green: 0x68/255, blue: 0x3D/255).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            if let processorResult {
                Text(processorResult)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0x7A/255, green: 0x9A/255, blue: 0x6E/255).opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .task {
            authStatus = await cameraService.authorizationStatus
        }
    }

    private func displayCapturedAt() -> String {
        guard let when = store.capturedAt else { return "?" }
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .medium
        return f.string(from: when)
    }

    private func captureFromCamera() async {
        isCapturing = true
        errorMessage = nil
        processorResult = nil
        defer { isCapturing = false }
        do {
            // Promote authorization if needed.
            if authStatus == .notDetermined {
                authStatus = try await cameraService.requestAuthorization()
            }
            guard authStatus == .authorized else {
                errorMessage = "[\(authStatus.tagIfYouLike)] \(authStatus.userMessage)"
                return
            }
            try await cameraService.configureSession()
            try cameraService.startSession()
            let image = try await cameraService.capturePhoto()
            cameraService.stopSession()
            _ = try store.set(image)
        } catch let err as CameraError {
            errorMessage = "[tag=\(err.tag)] \(err.errorDescription ?? "<no desc>")"
        } catch {
            errorMessage = "Unexpected non-CameraError: \(String(describing: error))"
        }
    }

    private func pickFromLibrary() async {
        isPickingFromLibrary = true
        errorMessage = nil
        processorResult = nil
        defer { isPickingFromLibrary = false }
        do {
            if let image = try await libraryPicker.pickImage() {
                _ = try store.set(image)
            }
            // cancellation returns nil → silently exit
        } catch let err as LibraryPickerError {
            errorMessage = "[tag=\(err.tag)] \(err.errorDescription ?? "<no desc>")"
        } catch {
            errorMessage = "Unexpected non-LibraryPickerError: \(String(describing: error))"
        }
    }

    private func processMenu() async {
        guard let image = store.current else { return }
        isProcessing = true
        defer { isProcessing = false }
        let result = await processor.process(image: image, onDiskPath: store.onDiskPath)
        switch result {
        case .received(let bytes, let path, let label):
            processorResult = "Received: \(label) • \(bytes) bytes • path=\(path ?? "<none>")"
        case .errored(let reason):
            processorResult = "Errored: \(reason)"
        }
    }
}

private extension CameraAuthorizationStatus {
    var tagIfYouLike: String {
        switch self {
        case .notDetermined: return "not_determined"
        case .authorized:    return "authorized"
        case .denied:        return "denied"
        case .restricted:    return "restricted"
        case .unavailable:   return "unavailable"
        }
    }
}
