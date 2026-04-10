//
//  User.swift
//  LEVEL UP
//
//  The single User record in the app — there is only one player. All XP
//  and streak state lives here. Levels are *derived* from XP via XPEngine
//  so we never store stale level numbers.
//

import Foundation
import SwiftData

@Model
final class User {

    // MARK: - Identity
    var id: UUID
    var name: String
    var createdAt: Date

    // MARK: - Raw XP (persisted)
    var fitnessXP: Int
    var workXP: Int
    var learningXP: Int

    // MARK: - Streak
    var currentStreak: Int
    var longestStreak: Int
    /// Last calendar day a log was recorded; used to advance the streak.
    var lastActiveDate: Date?

    init(name: String = "Yashodev") {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.fitnessXP = 0
        self.workXP = 0
        self.learningXP = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastActiveDate = nil
    }

    // MARK: - Derived values
    //
    // These are computed on the fly so there is exactly one source of truth
    // for XP. No risk of a displayed level drifting from its XP number.

    var totalXP: Int { fitnessXP + workXP + learningXP }

    var fitnessLevel: Int  { XPEngine.level(forXP: fitnessXP) }
    var workLevel: Int     { XPEngine.level(forXP: workXP) }
    var learningLevel: Int { XPEngine.level(forXP: learningXP) }
    var totalLevel: Int    { XPEngine.level(forXP: totalXP) }
}
