//
//  PerfectWeekOverlay.swift
//  LEVEL UP — Phase 3
//
//  Full-screen celebration that fires when GameEventCenter's
//  `currentPerfectWeek` is populated. Triggered by GymSplitEngine
//  awarding the Perfect Week bonus (5 gym days in one ISO week).
//

import SwiftUI

struct PerfectWeekOverlay: View {

    @Environment(GameEventCenter.self) private var events

    var body: some View {
        ZStack {
            if let event = events.currentPerfectWeek {
                content(for: event).transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: events.currentPerfectWeek?.id)
    }

    @ViewBuilder
    private func content(for event: PerfectWeekEvent) -> some View {
        ZStack {
            Color.black.opacity(0.82).ignoresSafeArea()
            ConfettiView().ignoresSafeArea()

            PerfectWeekCard(event: event)
        }
        .zIndex(190)
    }
}

private struct PerfectWeekCard: View {
    let event: PerfectWeekEvent

    @Environment(GameEventCenter.self) private var events
    @State private var show = false

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 86))
                .foregroundStyle(Theme.xpGreen)
                .shadow(color: Theme.xpGreen.opacity(0.6), radius: 28)
                .scaleEffect(show ? 1 : 0.3)

            Text("PERFECT WEEK")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .tracking(6)
                .foregroundStyle(Theme.xpGreen)

            Text("5 gym sessions this week.\nYou're a machine.")
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)

            Text("+\(event.xp) XP")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(Theme.xpGold)
                .monospacedDigit()

            Button {
                events.dismissPerfectWeek()
            } label: {
                Text("LET'S GO")
                    .font(.headline).tracking(3)
                    .frame(maxWidth: 260)
                    .padding(.vertical, 16)
                    .background(Theme.xpGreen.opacity(0.2))
                    .foregroundStyle(Theme.xpGreen)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Theme.xpGreen, lineWidth: 2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)
        }
        .padding(40)
        .frame(maxWidth: 520)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Theme.xpGreen, lineWidth: 2)
        )
        .shadow(color: Theme.xpGreen.opacity(0.5), radius: 34)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { show = true }
        }
    }
}
