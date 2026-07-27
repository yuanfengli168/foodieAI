// FoodieAIApp.swift
// App entry point.
//
// In DEBUG builds, a SmokeTestView is shown that lets you type dish names and
// see FuzzyIndex results live. The real ContentView (with search box, camera
// button, plus button) ships on Day 6 and will be the production view.
//
// See doc/mvp0-plan.md §9 (Day 6 = real UI, Day 2 = smoke test harness).

import SwiftUI

@main
struct FoodieAIApp: App {
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            SmokeTestView()
            #else
            ProductionPlaceholder()
            #endif
        }
    }
}

#if DEBUG
/// Day 2 + Day 3 + Day 4 smoke-test view.
///   - Day 2 (R7 D-049): type a dish name → FuzzyIndex results live.
///   - Day 3 (R9 D-062): tap a result → CardGenerator runs against the dish
///     via Apple FM (or surfaces a typed error).
///   - Day 4 (R10 D-081): Camera + Library picker → MenuProcessor stub.
/// Removed on Day 6 when the real ContentView ships.
struct SmokeTestView: View {
    @State private var repository: DishRepository?
    @State private var loadError: String?
    @State private var query: String = ""
    @State private var results: [FuzzyMatch] = []
    @State private var selectedDish: Dish?
    @State private var cardDraft: CardDraft?
    @State private var cardError: String?
    @State private var isGenerating: Bool = false
    @StateObject private var capturedImageStore = CapturedImageStore()
    @FocusState private var searchFocused: Bool

    var body: some View {
        ZStack {
            Color(red: 0xFA/255, green: 0xF7/255, blue: 0xF2/255)
                .ignoresSafeArea()
            VStack(spacing: 12) {
                Text("foodieAI smoke test (DEBUG)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(red: 0x2A/255, green: 0x25/255, blue: 0x22/255))
                    .padding(.top, 16)

                Text("Type a dish name (EN, ZH, or pinyin)")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(red: 0x6B/255, green: 0x5E/255, blue: 0x54/255))

                if let loadError {
                    Text("Load error: \(loadError)")
                        .foregroundStyle(.red)
                        .font(.caption)
                } else if let repository {
                    Text("Loaded \(repository.dishes.count) dishes")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(red: 0x7A/255, green: 0x9A/255, blue: 0x6E/255))
                }

                searchField
                    .padding(.horizontal, 16)

                ScrollView {
                    resultsList
                        .padding(.horizontal, 16)
                    cardPanel
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    cameraPanelSection
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                }

                Spacer()
            }
        }
        .task {
            do {
                repository = try DishRepository.loadFromBundle()
            } catch {
                loadError = error.localizedDescription
            }
        }
    }

    @ViewBuilder
    private var cameraPanelSection: some View {
        CameraPanel(
            store: capturedImageStore,
            cameraService: AVCameraService(),
            libraryPicker: PHPPickerLibraryPicker(),
            processor: StubMenuProcessor()
        )
    }

    private var searchField: some View {
        SearchField(text: $query, isFocused: $searchFocused)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(red: 0xC7/255, green: 0x68/255, blue: 0x3D/255), lineWidth: 1.5)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white))
            )
            .overlay(
                HStack {
                    if query.isEmpty {
                        Text("e.g. sesame chicken, 麻婆豆腐, lan zhou mian")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 14))
                            .padding(.leading, 12)
                    }
                    Spacer()
                }
            )
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    searchFocused = true
                }
            }
            .onChange(of: query) { _, newValue in
                runSearch(newValue)
            }
    }

    @ViewBuilder
    private var resultsList: some View {
        if query.isEmpty {
            Text("Start typing to see results")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 20)
        } else if results.isEmpty {
            Text("No matches")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 20)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(results, id: \.dish.id) { match in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(match.dish.nameZh.isEmpty ? match.dish.nameEn : match.dish.nameZh)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color(red: 0x2A/255, green: 0x25/255, blue: 0x22/255))
                            if !match.dish.nameZh.isEmpty {
                                Text("(\(match.dish.nameEn))")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(String(format: "%.2f", match.score))
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundStyle(scoreColor(match.score))
                        }
                        HStack {
                            Text(match.reason.rawValue)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.secondary)
                            if match.dish.isMenuVerified {
                                Text("📷 menu-verified")
                                    .font(.system(size: 10))
                            }
                            Spacer()
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color.white.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onTapGesture {
                        selectedDish = match.dish
                        cardDraft = nil
                        cardError = nil
                    }
                }
            }
            .padding(.top, 12)
        }
    }

    private func runSearch(_ q: String) {
        guard let repository else { return }
        results = searchDishes(q, in: repository.dishes)
    }

    // MARK: - Day 3: Card generation panel

    @ViewBuilder
    private var cardPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Card (Day 3 — Apple FM)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(red: 0x2A/255, green: 0x25/255, blue: 0x22/255))

            if let selectedDish {
                Text("Selected: \(selectedDish.nameZh.isEmpty ? selectedDish.nameEn : selectedDish.nameZh)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Button(action: { Task { await generateCard() } }) {
                    HStack {
                        if isGenerating {
                            ProgressView()
                        } else {
                            Text("Generate card via Apple FM")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(red: 0xC7/255, green: 0x68/255, blue: 0x3D/255))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(isGenerating)

                if let cardError {
                    Text(cardError)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 0xC7/255, green: 0x68/255, blue: 0x3D/255).opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                if let draft = cardDraft {
                    VStack(alignment: .leading, spacing: 4) {
                        if let zh = draft.nameZh { Text(zh).font(.system(size: 16, weight: .medium)) }
                        if let en = draft.nameEn { Text(en).font(.system(size: 14)).foregroundStyle(.secondary) }
                        Text(draft.introEn).font(.system(size: 13))
                        if let zh = draft.introZh {
                            Text(zh).font(.system(size: 13)).foregroundStyle(.secondary)
                        }
                        if !draft.pairWithEn.isEmpty {
                            Text("Pairs: \(draft.pairWithEn.joined(separator: ", "))")
                                .font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                        if let region = draft.region {
                            Text("Region: \(region)").font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            } else {
                Text("Tap a search result above to select a dish.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @MainActor
    private func generateCard() async {
        guard let selectedDish else { return }
        isGenerating = true
        cardError = nil
        cardDraft = nil
        defer { isGenerating = false }
        let backend = AppleFoundationBackend()
        let generator = CardGenerator(service: backend)
        do {
            cardDraft = try await generator.generate(for: selectedDish, query: query)
        } catch let error as LLMError {
            cardError = "[tag=\(error.tag)] \(error.errorDescription ?? "<no description>")"
        } catch {
            cardError = "Unexpected non-LLMError: \(String(describing: error))"
        }
    }

}

/// UIKit-bridged UITextField for reliable keyboard input on iOS 26 simulator.
struct SearchField: UIViewRepresentable {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.borderStyle = .none
        tf.font = .systemFont(ofSize: 16)
        tf.placeholder = ""
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.smartDashesType = .no
        tf.smartQuotesType = .no
        tf.spellCheckingType = .no
        tf.smartInsertDeleteType = .no
        tf.delegate = context.coordinator
        tf.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged), for: .editingChanged)
        tf.returnKeyType = .search
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text { uiView.text = text }
        let shouldFocus = isFocused.wrappedValue
        if shouldFocus && !uiView.isFirstResponder {
            DispatchQueue.main.async { uiView.becomeFirstResponder() }
        } else if !shouldFocus && uiView.isFirstResponder {
            DispatchQueue.main.async { uiView.resignFirstResponder() }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextFieldDelegate {
        let parent: SearchField
        init(_ parent: SearchField) { self.parent = parent }

        @objc func editingChanged(_ tf: UITextField) {
            parent.text = tf.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }
}
#endif

/// Production placeholder shown in non-DEBUG builds until Day 6 ships the real ContentView.
/// This guarantees release builds always have a view tree, never a debug-only stub.
struct ProductionPlaceholder: View {
    @State private var repository: DishRepository?
    @State private var loadError: String?

    var body: some View {
        ZStack {
            (Color(red: 0xFA/255, green: 0xF7/255, blue: 0xF2/255))
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Text("foodieAI")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(Color(red: 0x2A/255, green: 0x25/255, blue: 0x22/255))
                Text("MVP0 in progress")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(red: 0x6B/255, green: 0x5E/255, blue: 0x54/255))
                if let loadError {
                    Text("Load error: \(loadError)")
                        .foregroundStyle(.red)
                        .font(.caption)
                } else if let repository {
                    Text("Loaded \(repository.dishes.count) dishes")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(red: 0x7A/255, green: 0x9A/255, blue: 0x6E/255))
                }
            }
        }
        .task {
            do {
                repository = try DishRepository.loadFromBundle()
            } catch {
                loadError = error.localizedDescription
            }
        }
    }
}