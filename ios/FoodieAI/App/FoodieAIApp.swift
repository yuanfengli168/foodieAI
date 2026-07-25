// FoodieAIApp.swift
// App entry point. Day 1 ships a minimal "Hello" view that confirms
// the data layer loads. Day 6 will replace this with the real ContentView.

import SwiftUI

@main
struct FoodieAIApp: App {
    @State private var repository: DishRepository?

    var body: some Scene {
        WindowGroup {
            ContentView(repository: repository)
                .task {
                    do {
                        repository = try DishRepository.loadFromBundle()
                    } catch {
                        // Day 1 just logs. Day 6 will surface this as an error banner.
                        print("DishRepository load failed: \(error.localizedDescription)")
                    }
                }
        }
    }
}

struct ContentView: View {
    let repository: DishRepository?

    var body: some View {
        ZStack {
            (Color(red: 0xFA/255, green: 0xF7/255, blue: 0xF2/255))
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Text("foodieAI")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(Color(red: 0x2A/255, green: 0x25/255, blue: 0x22/255))
                Text("MVP0 Day 1 — data layer ready")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(red: 0x6B/255, green: 0x5E/255, blue: 0x54/255))
                if let repository {
                    Text("Loaded \(repository.dishes.count) dishes")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(red: 0x7A/255, green: 0x9A/255, blue: 0x6E/255))
                } else {
                    Text("Loading…")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(red: 0x6B/255, green: 0x5E/255, blue: 0x54/255))
                }
            }
        }
    }
}
