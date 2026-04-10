//
//  XPGainOverlay.swift
//  LEVEL UP — Phase 3
//
//  Full-window overlay that renders every floating "+XP" number queued
//  by GameEventCenter. Numbers drift up, shimmer in the track color,
//  and fade out over ~1.2s. Non-interactive — purely cosmetic.
//
//  Placed inside the root ZStack so it can render over any tab.
//

import SwiftUI

struct XPGainOverlay: View {

    @Environment(GameEventCenter.self) private var events

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Color.clear
                ForEach(events.xpGains) { event in
                    XPGainPill(event: event)
                        .offset(x: xOffset(for: event, width: geo.size.width),
                                y: -40)
                }
            }
        }
        .allowsHitTesting(false)
    }

    /// Deterministic horizontal spread based on the event id so
    /// simultaneous gains don't stack on top of each other.
    private func xOffset(for event: XPGainEvent, width: CGFloat) -> CGFloat {
        let hash = abs(event.id.hashValue)
        let slot = Double(hash % 5) - 2 // -2, -1, 0, 1, 2
        return CGFloat(slot * 70)
    }
}

// MARK: - Pill

private struct XPGainPill: View {
    let event: XPGainEvent
    @State private var rise: CGFloat = 0
    @State private var opacity: Double = 0

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: event.track.icon)
                .font(.caption).bold()
            Text("+\(event.amount) XP")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .monospacedDigit()
        }
        .foregroundStyle(event.track.color)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Theme.cardBackground.opacity(0.92))
                .overlay(
                    Capsule().stroke(event.track.color.opacity(0.7), lineWidth: 1.5)
                )
                .shadow(color: event.track.color.opacity(0.6), radius: 14)
        )
        .offset(y: rise)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                opacity = 1
            }
            withAnimation(.easeOut(duration: AnimConst.xpGainLifetime)) {
                rise = -140
            }
            withAnimation(.easeIn(duration: 0.5).delay(AnimConst.xpGainLifetime - 0.5)) {
                opacity = 0
            }
        }
    }
}
