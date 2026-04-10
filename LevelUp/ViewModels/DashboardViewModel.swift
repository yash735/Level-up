//
//  DashboardViewModel.swift
//  LEVEL UP
//
//  Lightweight value-type view-model. The dashboard view builds one of
//  these on every render from the live @Query data, so it stays in sync
//  with SwiftData automatically without observation ceremony.
//

import Foundation

struct DashboardViewModel {

    let user: User
    let unlocks: [Unlock]

    // MARK: - Recent & next unlocks

    /// Last 3 unlocks by unlockedAt, newest first.
    var recentUnlocks: [Unlock] {
        unlocks
            .filter { $0.isUnlocked }
            .sorted { ($0.unlockedAt ?? .distantPast) > ($1.unlockedAt ?? .distantPast) }
            .prefix(3)
            .map { $0 }
    }

    /// Next locked unlock in a given track ("fitness", "work", "learning").
    func nextUnlock(forTrack track: String) -> Unlock? {
        unlocks
            .filter { $0.track == track && !$0.isUnlocked }
            .sorted { $0.levelRequired < $1.levelRequired }
            .first
    }

    /// Next locked combined-track title.
    var nextCombinedUnlock: Unlock? { nextUnlock(forTrack: "combined") }

    // MARK: - Today
    //
    // Phase 1 has no logs — return 0 until Phase 2 wires up sum-by-day.
    var xpEarnedToday: Int { 0 }

    // MARK: - Per-track helpers

    func currentXP(forTrack track: String) -> Int {
        switch track {
        case "fitness":  return user.fitnessXP
        case "work":     return user.workXP
        case "learning": return user.learningXP
        default:         return 0
        }
    }

    func currentLevel(forTrack track: String) -> Int {
        switch track {
        case "fitness":  return user.fitnessLevel
        case "work":     return user.workLevel
        case "learning": return user.learningLevel
        default:         return 0
        }
    }
}
