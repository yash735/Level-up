//
//  UnlockCelebrationView.swift
//  LEVEL UP — Phase 2
//
//  Full-screen overlay that fires when UnlockCenter has a `current`
//  unlock to celebrate. Queues are handled by UnlockCenter; this view
//  just renders whatever is current and calls `dismissCurrent()` when
//  the player hits Continue.
//

import SwiftUI

struct UnlockCelebrationView: View {

    @Environment(UnlockCenter.self) private var center

    var body: some View {
        ZStack {
            if let unlock = center.current {
                ZStack {
                    // Darken the world behind it.
                    Color.black.opacity(0.75)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    ConfettiView()
                        .ignoresSafeArea()

                    card(for: unlock)
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                }
                .zIndex(100)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: center.current?.id)
    }

    // MARK: - Card

    private func card(for unlock: Unlock) -> some View {
        VStack(spacing: 24) {
            Text("UNLOCKED")
                .font(.caption).fontWeight(.heavy).tracking(6)
                .foregroundStyle(Theme.xpGreen)

            Image(systemName: unlock.iconName)
                .font(.system(size: 72, weight: .bold))
                .foregroundStyle(Theme.heroGradient)
                .frame(width: 148, height: 148)
                .background(Theme.cardBackground)
                .clipShape(Circle())
                .overlay(Circle().stroke(Theme.heroGradient, lineWidth: 3))
                .shadow(color: Theme.primaryAccent.opacity(0.7), radius: 30)

            VStack(spacing: 8) {
                Text(unlock.title)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.textPrimary)

                Text(unlock.detail)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 24)

            Button {
                center.dismissCurrent()
            } label: {
                Text("CONTINUE")
                    .font(.headline).tracking(3)
                    .frame(maxWidth: 260)
                    .padding(.vertical, 16)
                    .background(Theme.heroGradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                    .shadow(color: Theme.primaryAccent.opacity(0.55), radius: 16, y: 6)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)
        }
        .padding(40)
        .frame(maxWidth: 520)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Theme.heroGradient, lineWidth: 2)
        )
        .shadow(color: Theme.primaryAccent.opacity(0.55), radius: 30)
    }
}
