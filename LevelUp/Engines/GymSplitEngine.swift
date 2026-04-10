//
//  GymSplitEngine.swift
//  LEVEL UP — Phase 2
//
//  Owns the Upper → Lower → Push → Pull → Legs cycle, the gym streak,
//  and the three bonus awards (Monday first-session, Perfect Week,
//  30-day streak milestone). All gym logging should go through
//  `logGymSession` so the cycle + streak + bonuses stay consistent.
//
//  The engine is stateless itself; persistent state lives on the
//  singleton `GymSplitState` row in SwiftData.
//

import Foundation
import SwiftData

enum GymSplitEngine {

    // MARK: - Cycle definition

    /// The 5 training day types. Order is the historical cycle but the
    /// app now plans based on day-of-week rather than index advancement.
    static let splitDays: [String] = ["Upper", "Lower", "Push", "Pull", "Legs"]

    /// Day-of-week → planned split. Monday anchors the week; weekends
    /// are rest. Users can override (e.g. do Upper on Tuesday) by
    /// picking a different split day at log time — the picker defaults
    /// to the planned split for the current weekday.
    static func plannedSplit(for date: Date) -> String {
        // Calendar.weekday: Sunday = 1, Monday = 2, ..., Saturday = 7.
        let weekday = Calendar.current.component(.weekday, from: date)
        switch weekday {
        case 2: return "Upper"
        case 3: return "Lower"
        case 4: return "Push"
        case 5: return "Pull"
        case 6: return "Legs"
        default: return "Rest"
        }
    }

    /// Human-readable description of what a split day involves.
    static func description(for dayName: String) -> String {
        switch dayName {
        case "Upper": return "Chest, back, shoulders, arms"
        case "Lower": return "Quads, hamstrings, glutes, calves"
        case "Push":  return "Chest, shoulders, triceps"
        case "Pull":  return "Back, biceps, rear delts"
        case "Legs":  return "Full lower body, heavy"
        case "Rest":  return "Recovery — walk, stretch, sleep"
        default:      return ""
        }
    }

    // MARK: - State fetch / create

    /// Fetches the singleton state row, creating it on first access.
    static func state(in context: ModelContext) -> GymSplitState {
        let descriptor = FetchDescriptor<GymSplitState>()
        if let existing = (try? context.fetch(descriptor))?.first {
            return existing
        }
        let fresh = GymSplitState()
        context.insert(fresh)
        try? context.save()
        return fresh
    }

    // MARK: - Queries

    /// What the user should be training today. Now driven by weekday,
    /// not a rolling index — the `_ state` arg is kept for call-site
    /// compatibility but ignored.
    static func todaysPlan(_ state: GymSplitState) -> String {
        plannedSplit(for: .now)
    }

    /// The next N planned split days starting tomorrow. Weekday-driven.
    static func nextSessions(_ state: GymSplitState, count: Int = 4) -> [String] {
        let cal = Calendar.current
        return (1...count).compactMap { offset -> String? in
            guard let day = cal.date(byAdding: .day, value: offset, to: .now) else { return nil }
            return plannedSplit(for: day)
        }
    }

    /// Days since the last gym session (0 if trained today, nil if never).
    static func missedDays(_ state: GymSplitState) -> Int? {
        guard let last = state.lastGymDate else { return nil }
        let cal = Calendar.current
        let lastDay = cal.startOfDay(for: last)
        let today = cal.startOfDay(for: .now)
        return cal.dateComponents([.day], from: lastDay, to: today).day
    }

    /// Red alert shown at the top of the Workout tab when the user has
    /// missed 2+ days.
    static func shouldShowMissedAlert(_ state: GymSplitState) -> Bool {
        (missedDays(state) ?? 0) >= 2
    }

    // MARK: - Logging

    /// Result bundle returned by `logGymSession` so callers can display
    /// toasts for each bonus that fired.
    struct LogResult {
        var session: GymSession
        var baseXP: Int
        var mondayBonus: Int
        var perfectWeekBonus: Int
        var streakMilestoneBonus: Int
        var totalXP: Int { baseXP + mondayBonus + perfectWeekBonus + streakMilestoneBonus }
    }

    /// Log a gym session. Creates the GymSession with the caller-chosen
    /// split day (defaulting to the weekday plan if nil), updates the
    /// streak, and awards any bonuses that qualify. The caller is
    /// responsible for inserting exercises and granting XP to the User
    /// record.
    static func logGymSession(user: User,
                              state: GymSplitState,
                              splitDay: String? = nil,
                              intensity: XPEngine.FitnessIntensity,
                              notes: String,
                              exercises: [Exercise],
                              in context: ModelContext) -> LogResult {
        let cal = Calendar.current
        let now = Date()

        // 1. Create the session. Use the caller-chosen split if given,
        //    otherwise fall back to today's weekday plan (with a sane
        //    default on weekends so a rest day doesn't get logged as
        //    the split day).
        let chosenDay: String = {
            if let s = splitDay, splitDays.contains(s) { return s }
            let planned = plannedSplit(for: now)
            return planned == "Rest" ? "Upper" : planned
        }()
        let session = GymSession(date: now,
                                 splitDay: chosenDay,
                                 intensity: intensity,
                                 isRestDay: false,
                                 notes: notes)
        session.exercises = exercises
        context.insert(session)

        // 2. Base XP for the workout.
        let baseXP = XPEngine.xpForWorkout(intensity: intensity)

        // 3. Streak bookkeeping.
        //    - Same calendar day as lastGymDate → no streak change.
        //    - Exactly 1 day gap → streak + 1.
        //    - >1 day gap or first ever → streak resets to 1.
        if let last = state.lastGymDate {
            let gapDays = cal.dateComponents([.day],
                                             from: cal.startOfDay(for: last),
                                             to: cal.startOfDay(for: now)).day ?? 0
            switch gapDays {
            case 0:  break
            case 1:  state.currentStreak += 1
            default: state.currentStreak = 1
            }
        } else {
            state.currentStreak = 1
        }
        state.longestStreak = max(state.longestStreak, state.currentStreak)
        state.lastGymDate = now

        // 4. (Cycle index is vestigial — the split is now weekday-driven.)

        // 5. Monday bonus: first gym session of a new ISO week.
        var mondayBonus = 0
        let thisWeekKey = weekKeyString(for: now)
        if state.lastMondayBonusKey != thisWeekKey {
            mondayBonus = XPEngine.xpForMondayGym
            state.lastMondayBonusKey = thisWeekKey
        }

        // 6. Perfect Week bonus: 5 sessions this ISO week, once per week.
        var perfectWeekBonus = 0
        if state.lastPerfectWeekKey != thisWeekKey {
            let count = sessionCountThisWeek(in: context, reference: now)
            if count >= 5 {
                perfectWeekBonus = XPEngine.xpForPerfectWeek
                state.lastPerfectWeekKey = thisWeekKey
            }
        }

        // 7. 30-day streak milestone (every 30 days after the first hit).
        var streakMilestoneBonus = 0
        if state.currentStreak > 0, state.currentStreak % 30 == 0 {
            streakMilestoneBonus = XPEngine.xpFor30DayGymStreak
        }

        // 8. Persist XP on the session, save. The caller is responsible
        //    for routing `totalXP` through `user.award(_:to:)` so the
        //    Phase 3 level-up + gain events fire through GameEventCenter.
        let total = baseXP + mondayBonus + perfectWeekBonus + streakMilestoneBonus
        session.xpEarned = total
        try? context.save()

        return LogResult(session: session,
                         baseXP: baseXP,
                         mondayBonus: mondayBonus,
                         perfectWeekBonus: perfectWeekBonus,
                         streakMilestoneBonus: streakMilestoneBonus)
    }

    /// Rest day — does not create a GymSession, does not advance the
    /// cycle, does not break or extend the streak. Just stamps the
    /// state so "missed days" calculations stay sane.
    static func logRestDay(state: GymSplitState, in context: ModelContext) {
        state.lastGymDate = .now
        try? context.save()
    }

    // MARK: - Private helpers

    /// ISO 8601 year + week string, e.g. "2026-W15". Used as the key
    /// for Monday and Perfect Week bonus bookkeeping so we can't
    /// double-award within the same week.
    private static func weekKeyString(for date: Date) -> String {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2 // Monday
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let year = comps.yearForWeekOfYear ?? 0
        let week = comps.weekOfYear ?? 0
        return String(format: "%04d-W%02d", year, week)
    }

    /// How many gym sessions exist in the ISO week containing `reference`.
    /// Includes the session we just inserted.
    private static func sessionCountThisWeek(in context: ModelContext, reference: Date) -> Int {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        guard let interval = cal.dateInterval(of: .weekOfYear, for: reference) else { return 0 }
        let start = interval.start
        let end = interval.end
        let descriptor = FetchDescriptor<GymSession>(
            predicate: #Predicate<GymSession> { session in
                session.date >= start && session.date < end && !session.isRestDay
            }
        )
        return (try? context.fetch(descriptor))?.count ?? 0
    }
}
