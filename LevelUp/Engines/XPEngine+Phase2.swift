//
//  XPEngine+Phase2.swift
//  LEVEL UP — Phase 2
//
//  Extension with the Phase 2 bonus constants. Kept in its own file so
//  the original XPEngine.swift (Phase 1) stays untouched.
//

import Foundation

extension XPEngine {

    // MARK: - Fitness bonuses

    /// 200 XP awarded once per ISO week when all 5 split days were hit.
    static let xpForPerfectWeek = 200

    /// 500 XP awarded when the gym streak hits a 30-day milestone.
    static let xpFor30DayGymStreak = 500

    /// 50 XP awarded on the first gym session of a new ISO week (the
    /// "Monday bonus" — fires the first time you train in a new week).
    static let xpForMondayGym = 50

    /// 75 XP for logging a cardio session (base; intensity multiplier
    /// applied by the caller via `xpForCardio(intensity:)`).
    static let xpForCardioBase = 40

    /// Cardio XP uses the same intensity multiplier as weights.
    static func xpForCardio(intensity: FitnessIntensity) -> Int {
        Int((Double(xpForCardioBase) * intensity.multiplier).rounded())
    }
}
