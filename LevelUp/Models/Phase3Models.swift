//
//  Phase3Models.swift
//  LEVEL UP — Phase 3
//
//  SwiftData models that power the Phase 3 gamification layer:
//  daily login streaks and personal records. Kept in one file because
//  they're small and all belong to the same feature slice.
//

import Foundation
import SwiftData

// MARK: - LoginStreak

/// Singleton row tracking the player's daily app-open streak. Distinct
/// from `GymSplitState.currentStreak` (which only advances on gym
/// sessions) — this one advances on any calendar day the user opens the
/// app. Used for the daily-bonus XP drop on the dashboard.
@Model
final class LoginStreak {
    var id: UUID
    /// Last calendar day the bonus was awarded. Used to gate same-day
    /// re-entry from double-counting.
    var lastBonusDate: Date?
    var currentStreak: Int
    var longestStreak: Int
    /// Total days the player has ever opened the app (unique days).
    var totalLoginDays: Int

    init() {
        self.id = UUID()
        self.lastBonusDate = nil
        self.currentStreak = 0
        self.longestStreak = 0
        self.totalLoginDays = 0
    }
}

// MARK: - PersonalRecord

/// One row per broken record. Engines fire these on the spot — a new row
/// appearing means a fresh PR that deserves a banner.
@Model
final class PersonalRecord {
    var id: UUID
    var date: Date
    /// Stable string key, e.g. "bench-press", "deal-size", "study-hours".
    var key: String
    /// Human-readable category label, e.g. "Fitness", "Work", "Learning".
    var track: String
    /// What the record is, e.g. "Bench Press" or "Biggest Deal".
    var title: String
    /// Display-ready value, e.g. "120 kg × 5" or "$4.2M".
    var value: String
    /// True until the banner has been shown once (lets us catch up after a
    /// crash without double-celebrating).
    var pendingCelebration: Bool

    init(key: String,
         track: String,
         title: String,
         value: String,
         date: Date = .now) {
        self.id = UUID()
        self.date = date
        self.key = key
        self.track = track
        self.title = title
        self.value = value
        self.pendingCelebration = true
    }
}
