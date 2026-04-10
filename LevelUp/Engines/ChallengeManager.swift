//
//  ChallengeManager.swift
//  LEVEL UP — Phase 4.5
//
//  Generates weekly and monthly challenges with dynamic difficulty
//  based on baseline stats. Tracks progress and awards XP on completion.
//

import Foundation
import SwiftData

enum ChallengeManager {

    // MARK: - Generate Weekly Challenge

    @MainActor
    static func generateWeeklyIfNeeded(user: User, in context: ModelContext) {
        let weekStart = currentISOWeekStart()

        // Check if challenge already exists for this week
        let desc = FetchDescriptor<WeeklyChallenge>()
        let all = (try? context.fetch(desc)) ?? []
        let cal = Calendar.current
        if all.contains(where: {
            !$0.isMegaChallenge && cal.isDate($0.weekStartDate, inSameDayAs: weekStart)
        }) {
            return
        }

        // Fail any uncompleted challenges from last week
        let lastWeek = cal.date(byAdding: .day, value: -7, to: weekStart)!
        for c in all where !c.isCompleted && !c.isFailed
            && cal.isDate(c.weekStartDate, inSameDayAs: lastWeek) {
            c.isFailed = true
        }

        let baseline = BaselineCalculator.latestBaseline(in: context)
        let challenge = pickWeeklyChallenge(baseline: baseline, weekStart: weekStart)
        context.insert(challenge)
        try? context.save()
    }

    /// Generate monthly mega challenge on first Monday of the month.
    @MainActor
    static func generateMonthlyIfNeeded(user: User, in context: ModelContext) {
        let cal = Calendar.current
        let weekStart = currentISOWeekStart()

        // Only on first Monday of month
        let dayOfMonth = cal.component(.day, from: weekStart)
        guard dayOfMonth <= 7 else { return }

        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: weekStart))!

        let desc = FetchDescriptor<WeeklyChallenge>()
        let all = (try? context.fetch(desc)) ?? []
        if all.contains(where: {
            $0.isMegaChallenge
            && cal.component(.month, from: $0.weekStartDate) == cal.component(.month, from: monthStart)
            && cal.component(.year, from: $0.weekStartDate) == cal.component(.year, from: monthStart)
        }) {
            return
        }

        let baseline = BaselineCalculator.latestBaseline(in: context)
        let mega = buildMegaChallenge(baseline: baseline, weekStart: weekStart)
        context.insert(mega)
        try? context.save()
    }

    // MARK: - Progress Update

    /// Update all active challenge progress. Call after any XP-awarding action.
    @MainActor
    static func updateProgress(user: User, in context: ModelContext) {
        let desc = FetchDescriptor<WeeklyChallenge>()
        let challenges = (try? context.fetch(desc)) ?? []
        let cal = Calendar.current
        let weekStart = currentISOWeekStart()

        for challenge in challenges where !challenge.isCompleted && !challenge.isFailed {
            let cWeekStart = challenge.weekStartDate
            let cWeekEnd = cal.date(byAdding: .day, value: 7, to: cWeekStart)!

            let newValue: Double
            switch challenge.challengeType {
            case "work_hours":
                newValue = workHoursThisWeek(from: cWeekStart, to: cWeekEnd, in: context)
            case "gym_sessions":
                newValue = Double(gymSessionsThisWeek(from: cWeekStart, to: cWeekEnd, in: context))
            case "study_hours":
                newValue = studyHoursThisWeek(from: cWeekStart, to: cWeekEnd, in: context)
            case "bva":
                newValue = Double(bvaActionsThisWeek(from: cWeekStart, to: cWeekEnd, in: context))
            case "habits":
                newValue = Double(habitDaysCompleteThisWeek(from: cWeekStart, to: cWeekEnd, in: context))
            case "monthly_mega":
                newValue = megaChallengeProgress(from: cWeekStart, to: cWeekEnd, in: context)
            default:
                continue
            }

            challenge.currentValue = newValue

            if newValue >= challenge.targetValue && !challenge.isCompleted {
                completeChallenge(challenge, user: user, in: context)
            }
        }

        try? context.save()
    }

    // MARK: - Challenge Completion

    @MainActor
    private static func completeChallenge(
        _ challenge: WeeklyChallenge,
        user: User,
        in context: ModelContext
    ) {
        challenge.isCompleted = true
        challenge.completedAt = .now

        // Stretch bonus
        let overPerformance = challenge.currentValue / challenge.targetValue
        var bonus = 0
        if overPerformance >= 1.5 {
            bonus = Int(Double(challenge.xpReward) * 1.5)
            BonusEngine.earnAchievement(key: "overachiever", in: context)
        } else if overPerformance >= 1.2 {
            bonus = Int(Double(challenge.xpReward) * 0.75)
            BonusEngine.earnAchievement(key: "overachiever", in: context)
        }
        challenge.stretchBonus = bonus

        let totalXP = challenge.xpReward + bonus
        // Split XP across tracks
        user.award(totalXP / 3, to: .fitness)
        user.award(totalXP / 3, to: .work)
        user.award(totalXP - (totalXP / 3) * 2, to: .learning)

        if challenge.tier == 4 {
            BonusEngine.earnAchievement(key: "tier4_unlocked", in: context)
        }
        if challenge.isMegaChallenge {
            BonusEngine.earnAchievement(key: "monthly_warrior", in: context)
        }

        // Check consecutive challenge streak
        let consecutiveCount = consecutiveChallengesCompleted(in: context)
        if consecutiveCount >= 4 {
            BonusEngine.earnAchievement(key: "on_a_roll", in: context)
        }
        if consecutiveCount == 4 {
            user.award(500, to: .fitness)
            user.award(500, to: .work)
            user.award(500, to: .learning)
        } else if consecutiveCount == 8 {
            user.award(1000, to: .fitness)
            user.award(1000, to: .work)
            user.award(1000, to: .learning)
        } else if consecutiveCount == 12 {
            user.award(1667, to: .fitness)
            user.award(1667, to: .work)
            user.award(1666, to: .learning)
            BonusEngine.earnAchievement(key: "unstoppable_challenger", in: context)
        }

        let tierLabel = challenge.tierLabel
        var subtitle = "+\(totalXP) XP — \(tierLabel) difficulty"
        if bonus > 0 {
            subtitle = "OVERACHIEVER +\(bonus) BONUS — " + subtitle
        }

        GameEventCenter.shared.fireBanner(
            title: challenge.isMegaChallenge ? "MEGA CHALLENGE COMPLETE" : "CHALLENGE COMPLETE",
            subtitle: subtitle,
            color: challenge.tier >= 3 ? .gold : .green
        )
    }

    // MARK: - Challenge Picker

    private static func pickWeeklyChallenge(
        baseline: BaselineStats?,
        weekStart: Date
    ) -> WeeklyChallenge {
        // Rotate through challenge types based on week number
        let weekNum = Calendar.current.component(.weekOfYear, from: weekStart)
        let types = ["work_hours", "gym_sessions", "study_hours", "bva", "habits"]
        let chosen = types[weekNum % types.count]

        switch chosen {
        case "work_hours":
            return workHoursChallenge(baseline: baseline, weekStart: weekStart)
        case "gym_sessions":
            return gymSessionsChallenge(baseline: baseline, weekStart: weekStart)
        case "study_hours":
            return studyHoursChallenge(baseline: baseline, weekStart: weekStart)
        case "bva":
            return bvaChallenge(baseline: baseline, weekStart: weekStart)
        case "habits":
            return habitsChallenge(baseline: baseline, weekStart: weekStart)
        default:
            return workHoursChallenge(baseline: baseline, weekStart: weekStart)
        }
    }

    private static func workHoursChallenge(baseline: BaselineStats?, weekStart: Date) -> WeeklyChallenge {
        let avg = baseline?.avgWorkHours ?? 0
        let (target, xp, tier): (Double, Int, Int)
        switch avg {
        case ..<15:   (target, xp, tier) = (20, 500, 1)
        case 15..<25: (target, xp, tier) = (30, 800, 2)
        case 25..<35: (target, xp, tier) = (40, 1200, 3)
        default:      (target, xp, tier) = (45, 2000, 4)
        }
        return WeeklyChallenge(
            weekStartDate: weekStart, challengeType: "work_hours",
            title: "Log \(Int(target)) hours of work",
            description: "Total work hours from ParaLAI, BVA, and Projects this week.",
            targetValue: target, xpReward: xp, tier: tier
        )
    }

    private static func gymSessionsChallenge(baseline: BaselineStats?, weekStart: Date) -> WeeklyChallenge {
        let avg = baseline?.avgGymSessions ?? 0
        let (target, xp, tier): (Double, Int, Int)
        switch avg {
        case ..<2: (target, xp, tier) = (3, 400, 1)
        case 2..<3: (target, xp, tier) = (4, 700, 2)
        case 3..<4: (target, xp, tier) = (5, 1000, 3)
        default:    (target, xp, tier) = (5, 1500, 4)
        }
        let desc = tier == 4
            ? "Perfect week — 5 sessions in correct Upper/Lower/Push/Pull/Legs order"
            : "Hit \(Int(target)) gym sessions this week"
        return WeeklyChallenge(
            weekStartDate: weekStart, challengeType: "gym_sessions",
            title: tier == 4 ? "Perfect gym week" : "Hit \(Int(target)) gym sessions",
            description: desc, targetValue: target, xpReward: xp, tier: tier
        )
    }

    private static func studyHoursChallenge(baseline: BaselineStats?, weekStart: Date) -> WeeklyChallenge {
        let avg = baseline?.avgStudyHours ?? 0
        let (target, xp, tier): (Double, Int, Int)
        switch avg {
        case ..<5:   (target, xp, tier) = (6, 400, 1)
        case 5..<10: (target, xp, tier) = (12, 700, 2)
        case 10..<20:(target, xp, tier) = (20, 1000, 3)
        default:     (target, xp, tier) = (25, 1800, 4)
        }
        return WeeklyChallenge(
            weekStartDate: weekStart, challengeType: "study_hours",
            title: "Study \(Int(target)) hours",
            description: "Total study hours from courses and certifications this week.",
            targetValue: target, xpReward: xp, tier: tier
        )
    }

    private static func bvaChallenge(baseline: BaselineStats?, weekStart: Date) -> WeeklyChallenge {
        let avg = baseline?.avgBVAActions ?? 0
        let (target, xp, tier): (Double, Int, Int)
        switch avg {
        case ..<2: (target, xp, tier) = (3, 400, 1)
        case 2..<4: (target, xp, tier) = (5, 700, 2)
        case 4..<6: (target, xp, tier) = (8, 1000, 3)
        default:    (target, xp, tier) = (10, 1500, 4)
        }
        let desc = tier == 4
            ? "Close or advance every active deal this week"
            : "Log \(Int(target)) BVA actions this week"
        return WeeklyChallenge(
            weekStartDate: weekStart, challengeType: "bva",
            title: tier == 4 ? "Advance every deal" : "Log \(Int(target)) BVA actions",
            description: desc, targetValue: target, xpReward: xp, tier: tier
        )
    }

    private static func habitsChallenge(baseline: BaselineStats?, weekStart: Date) -> WeeklyChallenge {
        let avg = baseline?.avgHabitsRate ?? 0
        let (target, xp, tier): (Double, Int, Int)
        switch avg {
        case ..<0.5:  (target, xp, tier) = (3, 300, 1)
        case 0.5..<0.7: (target, xp, tier) = (5, 600, 2)
        case 0.7..<0.9: (target, xp, tier) = (7, 1000, 3)
        default:        (target, xp, tier) = (7, 1500, 4)
        }
        let desc = tier == 4
            ? "Perfect habits + log all 3 tracks every single day"
            : "Complete all habits \(Int(target)) days this week"
        return WeeklyChallenge(
            weekStartDate: weekStart, challengeType: "habits",
            title: tier == 4 ? "Perfect habits + all tracks" : "All habits \(Int(target)) days",
            description: desc, targetValue: target, xpReward: xp, tier: tier
        )
    }

    private static func buildMegaChallenge(baseline: BaselineStats?, weekStart: Date) -> WeeklyChallenge {
        let workTarget = Int(max(30, (baseline?.avgWorkHours ?? 20) * 1.3))
        let gymTarget = 5
        let studyTarget = Int(max(15, (baseline?.avgStudyHours ?? 10) * 1.3))
        let desc = "This month: \(workTarget)+ work hours, \(gymTarget) gym sessions, " +
                   "\(studyTarget) study hours, close or advance every active BVA deal, " +
                   "ship 1 ParaLAI milestone — all in the same week"
        return WeeklyChallenge(
            weekStartDate: weekStart, challengeType: "monthly_mega",
            title: "MONTHLY MEGA CHALLENGE",
            description: desc,
            targetValue: 5, // 5 sub-goals to hit
            xpReward: 5000, tier: 4, isMegaChallenge: true
        )
    }

    // MARK: - Progress Queries

    private static func workHoursThisWeek(from start: Date, to end: Date, in context: ModelContext) -> Double {
        let paralaiDesc = FetchDescriptor<ParaLAIEntry>()
        let paralai = (try? context.fetch(paralaiDesc)) ?? []
        let paralaiHours = paralai.filter { $0.date >= start && $0.date < end }
            .reduce(0.0) { $0 + $1.hoursSpent }

        let otherDesc = FetchDescriptor<OtherWorkLog>()
        let other = (try? context.fetch(otherDesc)) ?? []
        let otherHours = other.filter { $0.date >= start && $0.date < end }
            .reduce(0.0) { $0 + $1.hoursSpent }

        return paralaiHours + otherHours
    }

    private static func gymSessionsThisWeek(from start: Date, to end: Date, in context: ModelContext) -> Int {
        let desc = FetchDescriptor<GymSession>()
        let all = (try? context.fetch(desc)) ?? []
        return all.filter { $0.date >= start && $0.date < end && !$0.isRestDay }.count
    }

    private static func studyHoursThisWeek(from start: Date, to end: Date, in context: ModelContext) -> Double {
        // Approximate from course total hours (no per-session dates)
        let desc = FetchDescriptor<Course>()
        let all = (try? context.fetch(desc)) ?? []
        return all.reduce(0.0) { $0 + $1.totalHours }
    }

    private static func bvaActionsThisWeek(from start: Date, to end: Date, in context: ModelContext) -> Int {
        let desc = FetchDescriptor<Deal>()
        let all = (try? context.fetch(desc)) ?? []
        return all.filter { $0.updatedAt >= start && $0.updatedAt < end }.count
    }

    private static func habitDaysCompleteThisWeek(from start: Date, to end: Date, in context: ModelContext) -> Int {
        let desc = FetchDescriptor<HabitLog>()
        let all = (try? context.fetch(desc)) ?? []
        return all.filter { $0.date >= start && $0.date < end && $0.allCompleted }.count
    }

    private static func megaChallengeProgress(from start: Date, to end: Date, in context: ModelContext) -> Double {
        var completed = 0.0
        if workHoursThisWeek(from: start, to: end, in: context) >= 30 { completed += 1 }
        if gymSessionsThisWeek(from: start, to: end, in: context) >= 5 { completed += 1 }
        if studyHoursThisWeek(from: start, to: end, in: context) >= 15 { completed += 1 }
        if bvaActionsThisWeek(from: start, to: end, in: context) >= 3 { completed += 1 }

        // ParaLAI milestone check
        let msDesc = FetchDescriptor<ParaLAIMilestone>()
        let milestones = (try? context.fetch(msDesc)) ?? []
        if milestones.contains(where: {
            $0.isCompleted && ($0.completedAt ?? .distantPast) >= start
                && ($0.completedAt ?? .distantPast) < end
        }) {
            completed += 1
        }
        return completed
    }

    // MARK: - Streak

    /// Count of consecutive completed weekly challenges (not mega).
    static func consecutiveChallengesCompleted(in context: ModelContext) -> Int {
        let desc = FetchDescriptor<WeeklyChallenge>(
            sortBy: [SortDescriptor(\.weekStartDate, order: .reverse)]
        )
        let all = (try? context.fetch(desc)) ?? []
        let weekly = all.filter { !$0.isMegaChallenge }
        var count = 0
        for c in weekly {
            if c.isCompleted { count += 1 }
            else { break }
        }
        return count
    }

    // MARK: - Current Challenges

    static func activeChallenges(in context: ModelContext) -> [WeeklyChallenge] {
        let desc = FetchDescriptor<WeeklyChallenge>(
            sortBy: [SortDescriptor(\.weekStartDate, order: .reverse)]
        )
        let all = (try? context.fetch(desc)) ?? []
        return all.filter { !$0.isCompleted && !$0.isFailed }
    }

    // MARK: - Helpers

    static func currentISOWeekStart() -> Date {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        let today = cal.startOfDay(for: .now)
        let weekday = cal.component(.weekday, from: today)
        let daysSinceMonday = (weekday + 5) % 7
        return cal.date(byAdding: .day, value: -daysSinceMonday, to: today)!
    }
}
