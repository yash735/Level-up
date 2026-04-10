//
//  LoginStreakEngine.swift
//  LEVEL UP — Phase 3
//
//  Awards a daily "show up" bonus the first time the app is opened each
//  calendar day. The bonus scales with the login streak so hitting a
//  week straight feels like it's worth something.
//
//  Separate from gym / fitness streaks. This one tracks app engagement,
//  not training adherence.
//

import Foundation
import SwiftData

enum LoginStreakEngine {

    // MARK: - Tuning

    /// Base XP per daily login.
    static let baseXP = 10
    /// Additional XP per streak day, capped.
    static let perStreakDayXP = 5
    static let maxStreakBonus = 150

    // MARK: - State fetch / create

    /// Fetches the singleton state row, creating it on first access.
    static func state(in context: ModelContext) -> LoginStreak {
        let descriptor = FetchDescriptor<LoginStreak>()
        if let existing = (try? context.fetch(descriptor))?.first {
            return existing
        }
        let fresh = LoginStreak()
        context.insert(fresh)
        try? context.save()
        return fresh
    }

    // MARK: - Award

    /// Call this on app open / dashboard appear. Idempotent — only
    /// awards once per calendar day.
    @MainActor
    @discardableResult
    static func awardIfNeeded(user: User,
                              in context: ModelContext) -> Int {
        let state = state(in: context)
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        if let last = state.lastBonusDate, cal.isDate(last, inSameDayAs: today) {
            return 0 // already awarded today
        }

        // Determine streak delta.
        if let last = state.lastBonusDate {
            let gap = cal.dateComponents([.day],
                                         from: cal.startOfDay(for: last),
                                         to: today).day ?? 0
            switch gap {
            case 0:  break // shouldn't reach here due to guard above
            case 1:  state.currentStreak += 1
            default: state.currentStreak = 1
            }
        } else {
            state.currentStreak = 1
        }

        state.longestStreak = max(state.longestStreak, state.currentStreak)
        state.lastBonusDate = today
        state.totalLoginDays += 1

        // Compute bonus: base + scaling cap.
        let streakBonus = min(maxStreakBonus,
                              (state.currentStreak - 1) * perStreakDayXP)
        let total = baseXP + streakBonus

        // Grant XP to learning as the "daily discipline" track so it
        // doesn't skew fitness or work inflation. Pick any track —
        // learning feels thematically right for "showed up".
        user.award(total, to: .learning)

        try? context.save()

        GameEventCenter.shared.fireDailyBonus(xp: total,
                                              streakDays: state.currentStreak)
        return total
    }
}
