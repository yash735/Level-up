//
//  XPEngine.swift
//  LEVEL UP
//
//  The single source of truth for every XP and leveling calculation in the
//  app. Views and view-models MUST route XP maths through here so that any
//  future tuning happens in exactly one place.
//

import Foundation

enum XPEngine {

    // MARK: - Level Curve
    //
    // Hand-authored curve up to level 10, then procedurally extended:
    //   L11–20: previous + 15,000
    //   L21–35: previous + 25,000
    //   L36–50: previous + 40,000
    //
    // `levelThresholds[level]` = XP required to be at that level.
    // Index 0 is unused (there's no level 0) so we keep it at 0.
    static let levelThresholds: [Int] = {
        var thresholds: [Int] = [
            0,        // index 0 — unused
            0,        // Level 1
            500,      // Level 2
            1_200,    // Level 3
            2_500,    // Level 4
            4_500,    // Level 5
            7_500,    // Level 6
            12_000,   // Level 7
            18_000,   // Level 8
            26_000,   // Level 9
            36_000    // Level 10
        ]
        // Levels 11–20: previous + 15k
        for _ in 11...20 {
            thresholds.append(thresholds.last! + 15_000)
        }
        // Levels 21–35: previous + 25k
        for _ in 21...35 {
            thresholds.append(thresholds.last! + 25_000)
        }
        // Levels 36–50: previous + 40k
        for _ in 36...50 {
            thresholds.append(thresholds.last! + 40_000)
        }
        return thresholds
    }()

    /// Highest level the curve exposes.
    static let maxLevel = 50

    /// Resolve a level from a raw XP number.
    static func level(forXP xp: Int) -> Int {
        var level = 1
        for lvl in 1...maxLevel {
            if xp >= levelThresholds[lvl] {
                level = lvl
            } else {
                break
            }
        }
        return level
    }

    /// XP threshold required to reach a given level.
    static func xpForLevel(_ level: Int) -> Int {
        guard level >= 1 else { return 0 }
        guard level <= maxLevel else { return levelThresholds[maxLevel] }
        return levelThresholds[level]
    }

    /// XP threshold for the NEXT level above the current XP. Returns the
    /// max-level threshold when the user is already at cap.
    static func xpForNextLevel(currentXP: Int) -> Int {
        let current = level(forXP: currentXP)
        if current >= maxLevel { return xpForLevel(maxLevel) }
        return xpForLevel(current + 1)
    }

    /// 0...1 progress across the current level towards the next.
    static func progressToNextLevel(currentXP: Int) -> Double {
        let current = level(forXP: currentXP)
        if current >= maxLevel { return 1.0 }
        let floorXP = xpForLevel(current)
        let ceilXP = xpForLevel(current + 1)
        let range = ceilXP - floorXP
        guard range > 0 else { return 1.0 }
        return Double(currentXP - floorXP) / Double(range)
    }

    /// Raw XP left to hit the next level.
    static func xpRemainingToNextLevel(currentXP: Int) -> Int {
        max(0, xpForNextLevel(currentXP: currentXP) - currentXP)
    }

    // MARK: - Fitness XP Rules

    enum FitnessIntensity: String, CaseIterable {
        case easy, medium, hard
        var multiplier: Double {
            switch self {
            case .easy:   return 1.0
            case .medium: return 1.5
            case .hard:   return 2.0
            }
        }
    }

    /// 50 XP base × intensity multiplier.
    static func xpForWorkout(intensity: FitnessIntensity) -> Int {
        Int((Double(50) * intensity.multiplier).rounded())
    }

    static let xpForNutritionLog = 20
    static let xpForWeightLog = 10
    static let xpForAllDailyHabits = 30

    /// Streak bonus added daily: current streak × 5 XP.
    static func streakBonus(days: Int) -> Int { max(0, days) * 5 }

    // MARK: - Work XP Rules

    static let xpForParaLAIFeature      = 100
    static let xpForParaLAIBug          = 40
    static let xpForParaLAIMilestone    = 300

    static let xpForBVADealAdded        = 50
    static let xpForBVADealStageUpdate  = 75
    static let xpForBVADealClosed       = 500
    static let xpForBVAMeeting          = 60

    // MARK: - Learning XP Rules

    static let xpForStudy30Min      = 40
    static let xpForStudy1Hour      = 100
    static let xpForCourseComplete  = 400
    static let xpForBookFinished    = 200
    static let xpForCertification   = 600
}
