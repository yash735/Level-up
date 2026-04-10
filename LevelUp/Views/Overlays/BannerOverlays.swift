//
//  BannerOverlays.swift
//  LEVEL UP — Phase 3
//
//  Small slide-in-from-top banners for non-blocking celebrations:
//   • DailyBonusBanner — login streak reward
//   • RecordBanner — personal record broken
//
//  Both read from GameEventCenter and auto-dismiss after a timeout
//  set in AnimConst.bannerVisible. They stack vertically if both are
//  live simultaneously.
//

import SwiftUI

// MARK: - Host

struct BannerOverlay: View {

    @Environment(GameEventCenter.self) private var events

    var body: some View {
        VStack(spacing: 10) {
            if let bonus = events.currentDailyBonus {
                DailyBonusBanner(event: bonus)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            if let record = events.currentRecord {
                RecordBanner(event: record)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .padding(.top, 24)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .top)
        .animation(.spring(response: 0.45, dampingFraction: 0.78),
                   value: events.currentDailyBonus?.id)
        .animation(.spring(response: 0.45, dampingFraction: 0.78),
                   value: events.currentRecord?.id)
        .allowsHitTesting(false)
    }
}

// MARK: - Daily bonus

private struct DailyBonusBanner: View {
    let event: DailyBonusEvent

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "sunrise.fill")
                .font(.title2)
                .foregroundStyle(Theme.xpGold)
                .frame(width: 44, height: 44)
                .background(Theme.xpGold.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("DAILY BONUS · Day \(event.streakDays)")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.xpGold)
                Text("+\(event.xp) XP for showing up")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(Theme.textPrimary)
            }

            Spacer()
        }
        .padding(14)
        .frame(maxWidth: 460)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.xpGold.opacity(0.5), lineWidth: 1.5)
        )
        .shadow(color: Theme.xpGold.opacity(0.4), radius: 18, y: 6)
    }
}

// MARK: - Personal record

private struct RecordBanner: View {
    let event: RecordEvent

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "trophy.fill")
                .font(.title2)
                .foregroundStyle(event.track.color)
                .frame(width: 44, height: 44)
                .background(event.track.color.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("NEW PERSONAL RECORD")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(event.track.color)
                Text(event.title)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(Theme.textPrimary)
                Text(event.value)
                    .font(.caption).monospacedDigit()
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()
        }
        .padding(14)
        .frame(maxWidth: 460)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(event.track.color.opacity(0.5), lineWidth: 1.5)
        )
        .shadow(color: event.track.color.opacity(0.4), radius: 18, y: 6)
    }
}
