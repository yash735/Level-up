//
//  Phase45Models.swift
//  LEVEL UP — Phase 4.5
//
//  SwiftData models for rank streaks, balanced days, founder weeks,
//  weekly challenges, baseline stats, season carryover, and achievements.
//

import Foundation
import SwiftData

// MARK: - RankStreakState (singleton)

@Model
final class RankStreakState {
    var id: UUID
    var currentSRankStreak: Int
    var currentARankStreak: Int
    var lastWeekRank: String
    var xpMultiplierActive: Bool
    var xpMultiplierValue: Double
    var xpMultiplierExpiryDate: Date?
    var doubleXPWeeksRemaining: Int
    /// Tracks whether the first-ever S rank bonus has been awarded.
    var hasEarnedFirstSRank: Bool

    init() {
        self.id = UUID()
        self.currentSRankStreak = 0
        self.currentARankStreak = 0
        self.lastWeekRank = ""
        self.xpMultiplierActive = false
        self.xpMultiplierValue = 1.0
        self.xpMultiplierExpiryDate = nil
        self.doubleXPWeeksRemaining = 0
        self.hasEarnedFirstSRank = false
    }
}

// MARK: - BalancedDayLog

@Model
final class BalancedDayLog {
    var id: UUID
    var date: Date
    var fitnessXP: Int
    var workXP: Int
    var learningXP: Int
    var totalBonus: Int
    /// Running streak of consecutive balanced days at time of award.
    var streakAtAward: Int

    init(date: Date, fitnessXP: Int = 50, workXP: Int = 50,
         learningXP: Int = 50, totalBonus: Int = 150, streakAtAward: Int = 1) {
        self.id = UUID()
        self.date = date
        self.fitnessXP = fitnessXP
        self.workXP = workXP
        self.learningXP = learningXP
        self.totalBonus = totalBonus
        self.streakAtAward = streakAtAward
    }
}

// MARK: - FounderWeekLog

@Model
final class FounderWeekLog {
    var id: UUID
    var weekStartDate: Date
    var bvaDealClosed: Bool
    var paralaiMilestone: Bool
    var xpAwarded: Int
    var achievedAt: Date

    init(weekStartDate: Date, bvaDealClosed: Bool = true,
         paralaiMilestone: Bool = true, xpAwarded: Int = 1000) {
        self.id = UUID()
        self.weekStartDate = weekStartDate
        self.bvaDealClosed = bvaDealClosed
        self.paralaiMilestone = paralaiMilestone
        self.xpAwarded = xpAwarded
        self.achievedAt = .now
    }
}

// MARK: - WeeklyChallenge

@Model
final class WeeklyChallenge {
    var id: UUID
    var weekStartDate: Date
    /// "work_hours", "gym_sessions", "study_hours", "bva", "habits",
    /// "combined", "monthly_mega"
    var challengeType: String
    var title: String
    var challengeDescription: String
    var targetValue: Double
    var currentValue: Double
    var xpReward: Int
    /// 1–4
    var tier: Int
    var isCompleted: Bool
    var completedAt: Date?
    var isFailed: Bool
    /// Extra XP earned from beating target by 20%+ or 50%+.
    var stretchBonus: Int
    /// True for monthly mega challenges.
    var isMegaChallenge: Bool

    init(weekStartDate: Date, challengeType: String, title: String,
         description: String, targetValue: Double, xpReward: Int,
         tier: Int, isMegaChallenge: Bool = false) {
        self.id = UUID()
        self.weekStartDate = weekStartDate
        self.challengeType = challengeType
        self.title = title
        self.challengeDescription = description
        self.targetValue = targetValue
        self.currentValue = 0
        self.xpReward = xpReward
        self.tier = tier
        self.isCompleted = false
        self.completedAt = nil
        self.isFailed = false
        self.stretchBonus = 0
        self.isMegaChallenge = isMegaChallenge
    }

    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(1, currentValue / targetValue)
    }

    var tierLabel: String {
        switch tier {
        case 1: return "STANDARD"
        case 2: return "HARD"
        case 3: return "ELITE"
        case 4: return "LEGENDARY"
        default: return "STANDARD"
        }
    }
}

// MARK: - BaselineStats

@Model
final class BaselineStats {
    var id: UUID
    var weekOf: Date
    var avgWorkHours: Double
    var avgGymSessions: Double
    var avgStudyHours: Double
    var avgHabitsRate: Double
    var avgBVAActions: Double

    init(weekOf: Date, avgWorkHours: Double = 0, avgGymSessions: Double = 0,
         avgStudyHours: Double = 0, avgHabitsRate: Double = 0,
         avgBVAActions: Double = 0) {
        self.id = UUID()
        self.weekOf = weekOf
        self.avgWorkHours = avgWorkHours
        self.avgGymSessions = avgGymSessions
        self.avgStudyHours = avgStudyHours
        self.avgHabitsRate = avgHabitsRate
        self.avgBVAActions = avgBVAActions
    }
}

// MARK: - SeasonCarryover

@Model
final class SeasonCarryover {
    var id: UUID
    var fromSeason: Int
    var toSeason: Int
    var rewardType: String
    var xpMultiplier: Double
    var xpBonus: Int
    var expiryDate: Date?
    var isActive: Bool

    init(fromSeason: Int, toSeason: Int, rewardType: String,
         xpMultiplier: Double = 1.0, xpBonus: Int = 0,
         expiryDate: Date? = nil) {
        self.id = UUID()
        self.fromSeason = fromSeason
        self.toSeason = toSeason
        self.rewardType = rewardType
        self.xpMultiplier = xpMultiplier
        self.xpBonus = xpBonus
        self.expiryDate = expiryDate
        self.isActive = true
    }
}

// MARK: - Achievement

@Model
final class Achievement {
    var id: UUID
    var title: String
    var achievementDescription: String
    var earnedAt: Date?
    var track: String
    var iconName: String
    var isEarned: Bool
    /// Unique key for dedup.
    var key: String

    init(key: String, title: String, description: String,
         track: String = "combined", iconName: String = "star.fill") {
        self.id = UUID()
        self.key = key
        self.title = title
        self.achievementDescription = description
        self.track = track
        self.iconName = iconName
        self.earnedAt = nil
        self.isEarned = false
    }
}
