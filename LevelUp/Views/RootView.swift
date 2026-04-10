//
//  RootView.swift
//  LEVEL UP
//
//  Decides between the onboarding welcome flow and the main sidebar UI
//  based on whether a User record exists.
//

import SwiftUI
import SwiftData

struct RootView: View {

    @Environment(\.modelContext) private var context
    @Query private var users: [User]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding, let user = users.first {
                MainNavigationView(user: user)
            } else {
                WelcomeView {
                    hasCompletedOnboarding = true
                }
            }
        }
        .frame(minWidth: 1000, minHeight: 720)
        .background(Theme.background)
    }
}
