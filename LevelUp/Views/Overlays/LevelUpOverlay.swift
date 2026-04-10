//
//  LevelUpOverlay.swift
//  LEVEL UP — Phase 3
//
//  Full-screen celebration that fires whenever GameEventCenter's
//  `currentLevelUp` is populated. Uses the same queue-then-drain
//  pattern as UnlockCelebrationView so back-to-back level-ups get
//  their own moment.
//
//  Sequence:
//    1. Fade + dim background
//    2. Track icon scales in from 0 with a bounce
//    3. "LEVEL UP" tracking label fades in
//    4. Giant level number pops in
//    5. Confetti burst
//    6. CONTINUE button appears after the hold-minimum
//

import SwiftUI

struct LevelUpOverlay: View {

    @Environment(GameEventCenter.self) private var events

    var body: some View {
        ZStack {
            if let event = events.currentLevelUp {
                content(for: event)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: events.currentLevelUp?.id)
    }

    // MARK: - Content

    @ViewBuilder
    private func content(for event: LevelUpEvent) -> some View {
        ZStack {
            Color.black.opacity(0.82).ignoresSafeArea()
            ConfettiView().ignoresSafeArea()

            VStack(spacing: 18) {
                LevelUpCard(event: event)
            }
        }
        .zIndex(200)
    }
}

// MARK: - Card

private struct LevelUpCard: View {
    let event: LevelUpEvent

    @Environment(GameEventCenter.self) private var events
    @State private var phase = 0     // 0 idle → 1 icon → 2 label → 3 number → 4 button

    var body: some View {
        VStack(spacing: 26) {

            // Track icon — dramatic badge.
            ZStack {
                Circle()
                    .fill(event.track.color.opacity(0.2))
                    .frame(width: 180, height: 180)
                Circle()
                    .stroke(Theme.levelUpGradient, lineWidth: 4)
                    .frame(width: 180, height: 180)
                    .shadow(color: Theme.xpGold.opacity(0.7), radius: 30)
                Image(systemName: event.track.icon)
                    .font(.system(size: 72, weight: .bold))
                    .foregroundStyle(Theme.xpGold)
            }
            .scaleEffect(phase >= 1 ? 1 : 0)
            .opacity(phase >= 1 ? 1 : 0)

            Text("LEVEL UP")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .tracking(10)
                .foregroundStyle(Theme.xpGold)
                .opacity(phase >= 2 ? 1 : 0)
                .offset(y: phase >= 2 ? 0 : 10)

            VStack(spacing: 4) {
                Text(event.track.displayName.uppercased())
                    .font(.caption).fontWeight(.heavy).tracking(4)
                    .foregroundStyle(event.track.color)

                Text("\(event.newLevel)")
                    .font(.system(size: 96, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.xpGold)
                    .shadow(color: Theme.xpGold.opacity(0.6), radius: 24)
                    .scaleEffect(phase >= 3 ? 1 : 0.4)
                    .opacity(phase >= 3 ? 1 : 0)
            }

            if phase >= 4 {
                Button {
                    events.dismissLevelUp()
                } label: {
                    Text("CONTINUE")
                        .font(.headline).tracking(3)
                        .frame(maxWidth: 280)
                        .padding(.vertical, 16)
                        .background(Theme.levelUpGradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Theme.xpGold.opacity(0.6), radius: 18, y: 6)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
                .transition(.opacity.combined(with: .scale(scale: 0.92)))
            }
        }
        .padding(44)
        .frame(maxWidth: 560)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Theme.levelUpGradient, lineWidth: 2.5)
        )
        .shadow(color: Theme.xpGold.opacity(0.55), radius: 40)
        .onAppear { runSequence() }
    }

    private func runSequence() {
        phase = 0
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.05)) {
            phase = 1
        }
        withAnimation(.easeOut(duration: 0.35).delay(0.45)) {
            phase = 2
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.55).delay(0.75)) {
            phase = 3
        }
        withAnimation(.easeOut(duration: 0.3).delay(AnimConst.levelUpHoldMin)) {
            phase = 4
        }
    }
}
