//
//  WelcomeView.swift
//  LEVEL UP
//
//  First-launch onboarding. Greets the player, explains the 3 tracks,
//  captures the name, then seeds the User record and the unlock catalog.
//

import SwiftUI
import SwiftData

struct WelcomeView: View {

    /// Called once the User + unlock catalog have been seeded.
    let onComplete: () -> Void

    @Environment(\.modelContext) private var context
    @State private var name: String = "Yashodev"

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 36) {
                    Spacer(minLength: 40)

                    // Logo
                    Text("LEVEL UP")
                        .font(.system(size: 96, weight: .black, design: .rounded))
                        .tracking(6)
                        .foregroundStyle(Theme.heroGradient)
                        .shadow(color: Theme.primaryAccent.opacity(0.4), radius: 24, y: 4)

                    Text("Turn your life into an RPG.")
                        .font(.title2)
                        .foregroundStyle(Theme.textSecondary)

                    // 3-track explainer
                    HStack(spacing: 22) {
                        trackCard(title: "FITNESS",
                                  icon: "figure.run",
                                  tint: Theme.xpGreen,
                                  caption: "Move. Lift. Run.")
                        trackCard(title: "WORK",
                                  icon: "briefcase.fill",
                                  tint: Theme.secondaryAccent,
                                  caption: "Ship. Close. Build.")
                        trackCard(title: "LEARNING",
                                  icon: "book.fill",
                                  tint: Theme.primaryAccent,
                                  caption: "Study. Grow. Master.")
                    }
                    .padding(.top, 12)

                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("YOUR NAME")
                            .font(.caption).fontWeight(.heavy).tracking(2)
                            .foregroundStyle(Theme.textSecondary)
                        TextField("Name", text: $name)
                            .textFieldStyle(.plain)
                            .font(.title3)
                            .foregroundStyle(Theme.textPrimary)
                            .padding(16)
                            .background(Theme.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                                    .stroke(Theme.cardBorder, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    }
                    .frame(maxWidth: 420)

                    // CTA
                    Button(action: startJourney) {
                        Text("START YOUR JOURNEY")
                            .font(.headline)
                            .tracking(2)
                            .frame(maxWidth: 420)
                            .padding(.vertical, 18)
                            .background(Theme.heroGradient)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                            .shadow(color: Theme.primaryAccent.opacity(0.5), radius: 16, y: 6)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.defaultAction)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 48)
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Subviews

    private func trackCard(title: String, icon: String, tint: Color, caption: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 42))
                .foregroundStyle(tint)
                .frame(width: 96, height: 96)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(tint.opacity(0.35), lineWidth: 1)
                )
            Text(title)
                .font(.subheadline).fontWeight(.heavy).tracking(2)
                .foregroundStyle(Theme.textPrimary)
            Text(caption)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(width: 180)
    }

    // MARK: - Actions

    private func startJourney() {
        // Defensive: if a previous session ever leaves a stale User record
        // behind (e.g. a partial reset), wipe it so we don't end up with two.
        if let existingUsers = try? context.fetch(FetchDescriptor<User>()) {
            for u in existingUsers { context.delete(u) }
        }

        // Seed the single User record.
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let user = User(name: trimmed.isEmpty ? "Yashodev" : trimmed)
        context.insert(user)

        // Seed the unlock catalog only if the store is empty (defensive).
        let existingUnlocks = (try? context.fetch(FetchDescriptor<Unlock>())) ?? []
        if existingUnlocks.isEmpty {
            UnlockEngine.seedUnlocks(into: context)
        }

        try? context.save()
        onComplete()
    }
}
