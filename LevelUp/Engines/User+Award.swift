//
//  User+Award.swift
//  LEVEL UP — Phase 3
//
//  Single choke-point for every XP mutation. Every log-XP call site
//  should funnel through `user.award(_:to:)` so we can:
//    1. Snapshot the level before mutation,
//    2. Apply the XP,
//    3. Detect a level increase,
//    4. Fire GameEventCenter events (floating gain + level-up overlay).
//
//  This replaces the old pattern of `user.fitnessXP += amount` scattered
//  across 18 view files.
//

import Foundation

extension User {

    /// Award XP to a specific track and fire the gain + level-up events.
    /// Returns the level delta (>0 means level-up happened) in case the
    /// caller wants to react.
    @MainActor
    @discardableResult
    func award(_ amount: Int, to track: XPTrack) -> Int {
        guard amount != 0 else { return 0 }

        let oldLevel = levelFor(track)
        switch track {
        case .fitness:  fitnessXP  += amount
        case .work:     workXP     += amount
        case .learning: learningXP += amount
        }
        let newLevel = levelFor(track)

        GameEventCenter.shared.fireXPGain(amount: amount, track: track)
        if newLevel > oldLevel {
            GameEventCenter.shared.fireLevelUp(track: track,
                                               oldLevel: oldLevel,
                                               newLevel: newLevel)
        }
        return newLevel - oldLevel
    }

    private func levelFor(_ track: XPTrack) -> Int {
        switch track {
        case .fitness:  return fitnessLevel
        case .work:     return workLevel
        case .learning: return learningLevel
        }
    }
}
