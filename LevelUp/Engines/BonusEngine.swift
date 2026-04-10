//
//  BonusEngine.swift
//  LEVEL UP — Phase 4.5
//
//  Centralised bonus logic: balanced day checks, rank streak
//  processing, founder week detection, and XP multiplier management.
//

import Foundation
import SwiftData

enum BonusEngine {

    // MARK: - XP Multiplier

    /// Returns the active XP multiplier (1.0 if none).
    /// Also auto-deactivates expired multipliers.
    @MainActor
    static func activeMultiplier(in context: ModelContext) -> Double {
        let state = getOrCreateRankStreakState(in: context)

        // Check rank streak multiplier
        if state.xpMultiplierActive {
            if let expiry = state.xpMultiplierExpiryDate, expiry < .now {
                state.xpMultiplierActive = false
                state.xpMultiplierValue = 1.0
                state.xpMultiplierExpiryDate = nil
                try? context.save()
                return 1.0
            }
            return state.xpMultiplierValue
        }

        // Check season carryover multiplier
        let carryDesc = FetchDescriptor<SeasonCarryover>()
        let carryovers = (try? context.fetch(carryDesc)) ?? []
        for carry in carryovers where carry.isActive && carry.xpMultiplier > 1.0 {
            if let expiry = carry.expiryDate, expiry < .now {
                carry.isActive = false
                try? context.save()
                continue
            }
            return carry.xpMultiplier
        }

        return 1.0
    }

    /// Days remaining on active multiplier, or 0.
    @MainActor
    static func multiplierDaysRemaining(in context: ModelContext) -> Int {
        let state = getOrCreateRankStreakState(in: context)
        if state.xpMultiplierActive, let expiry = state.xpMultiplierExpiryDate {
            return max(0, Calendar.current.dateComponents([.day], from: .now, to: expiry).day ?? 0)
        }
        let carryDesc = FetchDescriptor<SeasonCarryover>()
        let carryovers = (try? context.fetch(carryDesc)) ?? []
        for carry in carryovers where carry.isActive && carry.xpMultiplier > 1.0 {
            if let expiry = carry.expiryDate {
                return max(0, Calendar.current.dateComponents([.day], from: .now, to: expiry).day ?? 0)
            }
        }
        return 0
    }

    // MARK: - Rank Streak Processing

    /// Called after weekly report generates. Processes rank streak bonuses.
    @MainActor
    static func processWeeklyRank(
        grade: String,
        user: User,
        in context: ModelContext
    ) {
        let state = getOrCreateRankStreakState(in: context)
        state.lastWeekRank = grade

        switch grade {
        case "S":
            state.currentSRankStreak += 1
            state.currentARankStreak = 0

            // First ever S rank
            if !state.hasEarnedFirstSRank {
                state.hasEarnedFirstSRank = true
                user.award(500, to: .work)
                earnAchievement(key: "first_s_rank", in: context)
                GameEventCenter.shared.fireBanner(
                    title: "FIRST S RANK",
                    subtitle: "+500 XP — You're built different.",
                    color: .gold
                )
            }

            // 2+ week S streak → double XP
            if state.currentSRankStreak >= 2 {
                state.xpMultiplierActive = true
                state.xpMultiplierValue = 2.0
                state.xpMultiplierExpiryDate = Calendar.current.date(
                    byAdding: .day, value: 7, to: .now
                )
                state.doubleXPWeeksRemaining = 1
                GameEventCenter.shared.fireBanner(
                    title: "\(state.currentSRankStreak) WEEK S RANK STREAK",
                    subtitle: "DOUBLE XP ACTIVE FOR 7 DAYS",
                    color: .gold
                )
            }

            // 3+ S streak → Unstoppable
            if state.currentSRankStreak >= 3 {
                user.award(500, to: .work)
                earnAchievement(key: "unstoppable", in: context)
            }

        case "A":
            state.currentARankStreak += 1
            state.currentSRankStreak = 0

            if state.currentARankStreak >= 2 {
                user.award(200, to: .work)
                GameEventCenter.shared.fireBanner(
                    title: "\(state.currentARankStreak) WEEK A RANK STREAK",
                    subtitle: "+200 XP BONUS",
                    color: .green
                )
            }

        default:
            // Below A — reset streaks
            let hadStreak = state.currentSRankStreak > 0 || state.currentARankStreak > 0
            state.currentSRankStreak = 0
            state.currentARankStreak = 0

            if state.xpMultiplierActive {
                state.xpMultiplierActive = false
                state.xpMultiplierValue = 1.0
                state.xpMultiplierExpiryDate = nil
            }

            if hadStreak {
                GameEventCenter.shared.fireBanner(
                    title: "RANK STREAK BROKEN",
                    subtitle: "Get back to A rank Yashodev.",
                    color: .red
                )
            }
        }

        try? context.save()
    }

    // MARK: - Balanced Day Check

    /// Check if yesterday was a balanced day (all 3 tracks logged).
    /// Call on app launch.
    @MainActor
    static func checkBalancedDay(user: User, in context: ModelContext) {
        let cal = Calendar.current
        let yesterday = cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: .now))!
        let today = cal.startOfDay(for: .now)

        // Check if already awarded for yesterday
        let balancedDesc = FetchDescriptor<BalancedDayLog>()
        let allBalanced = (try? context.fetch(balancedDesc)) ?? []
        if allBalanced.contains(where: { cal.isDate($0.date, inSameDayAs: yesterday) }) {
            return
        }

        // Check fitness track: any workout, food, weight, or habit log
        let hasFitness: Bool = {
            let gymDesc = FetchDescriptor<GymSession>()
            let gyms = (try? context.fetch(gymDesc)) ?? []
            if gyms.contains(where: { cal.isDate($0.date, inSameDayAs: yesterday) && !$0.isRestDay }) { return true }

            let foodDesc = FetchDescriptor<FoodEntry>()
            let foods = (try? context.fetch(foodDesc)) ?? []
            if foods.contains(where: { cal.isDate($0.date, inSameDayAs: yesterday) }) { return true }

            let weightDesc = FetchDescriptor<WeightEntry>()
            let weights = (try? context.fetch(weightDesc)) ?? []
            if weights.contains(where: { cal.isDate($0.date, inSameDayAs: yesterday) }) { return true }

            let habitDesc = FetchDescriptor<HabitLog>()
            let habits = (try? context.fetch(habitDesc)) ?? []
            if habits.contains(where: { cal.isDate($0.date, inSameDayAs: yesterday) }) { return true }

            return false
        }()

        // Check work track: ParaLAI, BVA deal update, or Projects log
        let hasWork: Bool = {
            let paralaiDesc = FetchDescriptor<ParaLAIEntry>()
            let paralai = (try? context.fetch(paralaiDesc)) ?? []
            if paralai.contains(where: { cal.isDate($0.date, inSameDayAs: yesterday) }) { return true }

            let dealDesc = FetchDescriptor<Deal>()
            let deals = (try? context.fetch(dealDesc)) ?? []
            if deals.contains(where: { cal.isDate($0.updatedAt, inSameDayAs: yesterday) }) { return true }

            let otherDesc = FetchDescriptor<OtherWorkLog>()
            let others = (try? context.fetch(otherDesc)) ?? []
            if others.contains(where: { cal.isDate($0.date, inSameDayAs: yesterday) }) { return true }

            return false
        }()

        // Check learning track: course, book, or certification log
        let hasLearning: Bool = {
            let courseDesc = FetchDescriptor<Course>()
            let courses = (try? context.fetch(courseDesc)) ?? []
            // Check if any course was updated yesterday (completedLessons changed)
            if courses.contains(where: { $0.totalHours > 0 && cal.isDate($0.startedAt, inSameDayAs: yesterday) }) { return true }

            let bookDesc = FetchDescriptor<Book>()
            let books = (try? context.fetch(bookDesc)) ?? []
            if books.contains(where: { $0.pagesRead > 0 && cal.isDate($0.startedAt, inSameDayAs: yesterday) }) { return true }

            let certDesc = FetchDescriptor<Certification>()
            let certs = (try? context.fetch(certDesc)) ?? []
            if certs.contains(where: { $0.studiedHours > 0 && cal.isDate($0.targetDate ?? .distantPast, inSameDayAs: yesterday) }) { return true }

            return false
        }()

        guard hasFitness && hasWork && hasLearning else { return }

        // Calculate streak
        let recentBalanced = allBalanced
            .sorted { $0.date > $1.date }
        var streak = 1
        var checkDate = cal.date(byAdding: .day, value: -2, to: today)!
        for log in recentBalanced {
            if cal.isDate(log.date, inSameDayAs: checkDate) {
                streak += 1
                checkDate = cal.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }

        // Award bonus
        user.award(50, to: .fitness)
        user.award(50, to: .work)
        user.award(50, to: .learning)

        let log = BalancedDayLog(date: yesterday, streakAtAward: streak)
        context.insert(log)

        GameEventCenter.shared.fireBanner(
            title: "BALANCED DAY",
            subtitle: "+150 XP across all tracks",
            color: .green
        )

        // Streak milestones
        if streak == 7 {
            user.award(167, to: .fitness)
            user.award(167, to: .work)
            user.award(166, to: .learning)
            GameEventCenter.shared.fireBanner(
                title: "7 DAY BALANCED STREAK",
                subtitle: "+500 XP BONUS",
                color: .gold
            )
        }

        if streak == 30 {
            earnAchievement(key: "renaissance_man", in: context)
        }

        try? context.save()
    }

    // MARK: - Founder Week Check

    /// Check if this week had both a BVA deal closed and a ParaLAI milestone shipped.
    @MainActor
    static func checkFounderWeek(user: User, in context: ModelContext) {
        let cal = Calendar.current
        let weekStart = WeeklyReportEngine.lastISOWeekStart()
        let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStart)!

        // Already awarded?
        let fwDesc = FetchDescriptor<FounderWeekLog>()
        let allFW = (try? context.fetch(fwDesc)) ?? []
        if allFW.contains(where: { cal.isDate($0.weekStartDate, inSameDayAs: weekStart) }) {
            return
        }

        // Check BVA deal closed this week
        let dealDesc = FetchDescriptor<Deal>()
        let deals = (try? context.fetch(dealDesc)) ?? []
        let closedDeal = deals.contains {
            $0.isClosedWon && $0.updatedAt >= weekStart && $0.updatedAt < weekEnd
        }

        // Check ParaLAI milestone shipped this week
        let msDesc = FetchDescriptor<ParaLAIMilestone>()
        let milestones = (try? context.fetch(msDesc)) ?? []
        let shippedMilestone = milestones.contains {
            $0.isCompleted && ($0.completedAt ?? .distantPast) >= weekStart
                && ($0.completedAt ?? .distantPast) < weekEnd
        }

        guard closedDeal && shippedMilestone else { return }

        // Award
        user.award(1000, to: .work)

        let log = FounderWeekLog(weekStartDate: weekStart)
        context.insert(log)

        earnAchievement(key: "founder_week", in: context)

        GameEventCenter.shared.fireBanner(
            title: "FOUNDER WEEK ACHIEVED",
            subtitle: "BVA Deal Closed + ParaLAI Milestone Shipped — +1000 XP",
            color: .gold
        )

        try? context.save()
    }

    // MARK: - Achievement Helpers

    /// Seed the full achievement catalog. Idempotent.
    @MainActor
    static func seedAchievements(into context: ModelContext) {
        let desc = FetchDescriptor<Achievement>()
        let existing = (try? context.fetch(desc)) ?? []
        let existingKeys = Set(existing.map(\.key))

        let catalog: [(key: String, title: String, desc: String, track: String, icon: String)] = [
            ("first_s_rank", "First S Rank", "Earn your first S rank weekly grade", "combined", "star.fill"),
            ("unstoppable", "Unstoppable", "3 consecutive S rank weeks", "combined", "flame.fill"),
            ("founder_week", "Founder Week", "Close a BVA deal and ship a ParaLAI milestone in the same week", "work", "crown.fill"),
            ("renaissance_man", "Renaissance Man", "30 day balanced streak across all tracks", "combined", "figure.mind.and.body"),
            ("on_a_roll", "On A Roll", "Complete 4 consecutive weekly challenges", "combined", "bolt.fill"),
            ("legendary_season", "Legendary", "Achieve Legendary season rank", "combined", "trophy.fill"),
            ("overachiever", "Overachiever", "Earn your first stretch bonus on a challenge", "combined", "arrow.up.forward"),
            ("tier4_unlocked", "Tier 4 Unlocked", "Complete your first Legendary tier challenge", "combined", "shield.fill"),
            ("monthly_warrior", "Monthly Warrior", "Complete your first monthly mega challenge", "combined", "sparkles"),
            ("unstoppable_challenger", "Unstoppable Challenger", "Complete 12 challenges in a row", "combined", "bolt.shield.fill"),
            ("first_deal_closed", "First Deal Closed", "Close your first BVA deal", "work", "building.columns.fill"),
            ("paralai_shipped", "ParaLAI Shipped", "Complete your first ParaLAI milestone", "work", "shippingbox.fill"),
            ("100_workouts", "100 Workouts", "Log 100 total gym sessions", "fitness", "figure.run"),
            ("1000_hours", "1000 Hours", "Log 1000 total study hours", "learning", "clock.fill"),
            ("balanced_week", "Balanced Week", "Log all 3 tracks every day for 7 days", "combined", "scale.3d"),
        ]

        for item in catalog where !existingKeys.contains(item.key) {
            let achievement = Achievement(
                key: item.key, title: item.title,
                description: item.desc, track: item.track,
                iconName: item.icon
            )
            context.insert(achievement)
        }

        try? context.save()
    }

    /// Mark an achievement as earned. Idempotent.
    @MainActor
    static func earnAchievement(key: String, in context: ModelContext) {
        let desc = FetchDescriptor<Achievement>()
        let all = (try? context.fetch(desc)) ?? []
        guard let achievement = all.first(where: { $0.key == key && !$0.isEarned }) else { return }
        achievement.isEarned = true
        achievement.earnedAt = .now
        try? context.save()

        GameEventCenter.shared.fireBanner(
            title: "ACHIEVEMENT UNLOCKED",
            subtitle: achievement.title,
            color: .gold
        )
    }

    // MARK: - Helpers

    @MainActor
    static func getOrCreateRankStreakState(in context: ModelContext) -> RankStreakState {
        let desc = FetchDescriptor<RankStreakState>()
        if let existing = (try? context.fetch(desc))?.first {
            return existing
        }
        let state = RankStreakState()
        context.insert(state)
        try? context.save()
        return state
    }

    /// Returns the current balanced day streak length.
    static func balancedDayStreak(in context: ModelContext) -> Int {
        let desc = FetchDescriptor<BalancedDayLog>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let logs = (try? context.fetch(desc)) ?? []
        guard let latest = logs.first else { return 0 }

        let cal = Calendar.current
        let yesterday = cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: .now))!

        // Latest must be yesterday or today
        guard cal.isDate(latest.date, inSameDayAs: yesterday)
           || cal.isDate(latest.date, inSameDayAs: cal.startOfDay(for: .now)) else {
            return 0
        }

        var streak = 1
        var checkDate = cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: latest.date))!
        for log in logs.dropFirst() {
            if cal.isDate(log.date, inSameDayAs: checkDate) {
                streak += 1
                checkDate = cal.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        return streak
    }

    /// Returns the total number of founder weeks achieved.
    static func founderWeekCount(in context: ModelContext) -> Int {
        let desc = FetchDescriptor<FounderWeekLog>()
        return (try? context.fetch(desc))?.count ?? 0
    }
}
