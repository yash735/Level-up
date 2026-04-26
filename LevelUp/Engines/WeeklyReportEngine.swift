//
//  WeeklyReportEngine.swift
//  LEVEL UP — Phase 4
//
//  Generates a weekly report every Monday on app open. Queries all
//  SwiftData models for the prior ISO week and produces a graded
//  summary. Stored as a WeeklyReport row so historical reports
//  persist.
//

import Foundation
import SwiftData

enum WeeklyReportEngine {

    // MARK: - Should generate?

    /// Returns true if today is Monday (or later in the week) and no
    /// report exists for last week yet.
    static func shouldGenerate(in context: ModelContext) -> Bool {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: .now)
        // Only generate Mon-Sun (weekday 2-7,1)
        guard weekday >= 2 || weekday == 1 else { return false }

        let lastWeekStart = lastISOWeekStart()
        let descriptor = FetchDescriptor<WeeklyReport>(
            predicate: #Predicate<WeeklyReport> { $0.weekStartDate == lastWeekStart }
        )
        return ((try? context.fetch(descriptor))?.isEmpty) ?? true
    }

    // MARK: - Generate

    @MainActor
    static func generateIfNeeded(user: User,
                                 in context: ModelContext) -> WeeklyReport? {
        guard shouldGenerate(in: context) else { return nil }

        let weekStart = lastISOWeekStart()
        let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: weekStart)!

        // Fitness queries
        let gymCount = countModels(GymSession.self, from: weekStart, to: weekEnd, in: context) { $0.date >= weekStart && $0.date < weekEnd && !$0.isRestDay }
        let cardioCount = countModels(CardioSession.self, from: weekStart, to: weekEnd, in: context) { $0.date >= weekStart && $0.date < weekEnd }
        let workoutsCompleted = gymCount + cardioCount

        let gymXP = sumXP(GymSession.self, from: weekStart, to: weekEnd, in: context)
        let cardioXP = sumXPCardio(from: weekStart, to: weekEnd, in: context)
        let foodXP = sumXPFood(from: weekStart, to: weekEnd, in: context)
        let weightXP = sumXPWeight(from: weekStart, to: weekEnd, in: context)
        let habitXP = sumXPHabit(from: weekStart, to: weekEnd, in: context)
        let fitnessXP = gymXP + cardioXP + foodXP + weightXP + habitXP

        // Work queries
        let workEntriesCount = countWorkEntries(from: weekStart, to: weekEnd, in: context)
        let otherHours = sumWorkEntryHours(from: weekStart, to: weekEnd, in: context)
        let workXP = sumWorkXP(from: weekStart, to: weekEnd, in: context)

        // Learning queries
        let studyHours = sumStudyHours(from: weekStart, to: weekEnd, in: context)
        let learningXP = sumLearningXP(from: weekStart, to: weekEnd, in: context)

        // Habits completion rate
        let habitsRate = habitCompletionRate(from: weekStart, to: weekEnd, in: context)

        let totalXP = fitnessXP + workXP + learningXP

        // Compare vs prior week
        let priorStart = Calendar.current.date(byAdding: .day, value: -7, to: weekStart)!
        let priorDesc = FetchDescriptor<WeeklyReport>(
            predicate: #Predicate<WeeklyReport> { $0.weekStartDate == priorStart }
        )
        let priorXP = (try? context.fetch(priorDesc))?.first?.totalXP ?? 0
        let xpChange: Double = priorXP > 0
            ? Double(totalXP - priorXP) / Double(priorXP) * 100
            : 0

        // Grade
        let grade = calculateGrade(workouts: workoutsCompleted,
                                   gymSessions: gymCount,
                                   totalXP: totalXP,
                                   studyHours: studyHours,
                                   workEntries: workEntriesCount)

        // Summary
        let summary = generateSummary(workouts: workoutsCompleted,
                                      gymSessions: gymCount,
                                      workEntries: workEntriesCount,
                                      studyHours: studyHours,
                                      workHours: otherHours)

        let report = WeeklyReport(
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            totalXP: totalXP,
            fitnessXP: fitnessXP,
            workXP: workXP,
            learningXP: learningXP,
            workoutsCompleted: workoutsCompleted,
            gymSessionsCompleted: gymCount,
            bvaActionsCount: 0,
            paralaiLogsCount: 0,
            otherWorkHours: otherHours,
            studyHours: studyHours,
            habitsCompletionRate: habitsRate,
            xpChangeVsLastWeek: xpChange,
            grade: grade,
            summaryText: summary,
            workEntriesCount: workEntriesCount
        )
        context.insert(report)
        try? context.save()

        // Phase 4.5: Process rank streak bonuses
        BonusEngine.processWeeklyRank(grade: grade, user: user, in: context)

        // Phase 4.5: Check builder week
        BonusEngine.checkBuilderWeek(user: user, in: context)

        // Phase 4.5: Calculate baseline + generate challenges
        _ = BaselineCalculator.calculateIfNeeded(in: context)
        ChallengeManager.generateWeeklyIfNeeded(user: user, in: context)
        ChallengeManager.generateMonthlyIfNeeded(user: user, in: context)

        return report
    }

    // MARK: - Grading

    private static func calculateGrade(workouts: Int,
                                       gymSessions: Int,
                                       totalXP: Int,
                                       studyHours: Double,
                                       workEntries: Int) -> String {
        var score = 0
        // Fitness (max 4)
        score += min(4, workouts)
        // Gym consistency (max 3)
        if gymSessions >= 5 { score += 3 }
        else if gymSessions >= 3 { score += 2 }
        else if gymSessions >= 1 { score += 1 }
        // Work activity (max 3)
        if workEntries >= 5 { score += 3 }
        else if workEntries >= 3 { score += 2 }
        else if workEntries >= 1 { score += 1 }
        // Learning (max 3)
        if studyHours >= 10 { score += 3 }
        else if studyHours >= 5 { score += 2 }
        else if studyHours >= 1 { score += 1 }
        // XP bonus (max 2)
        if totalXP >= 1000 { score += 2 }
        else if totalXP >= 500 { score += 1 }

        switch score {
        case 13...15: return "S"
        case 10...12: return "A"
        case 7...9:   return "B"
        case 4...6:   return "C"
        default:      return "D"
        }
    }

    // MARK: - Summary generation

    private static func generateSummary(workouts: Int,
                                        gymSessions: Int,
                                        workEntries: Int,
                                        studyHours: Double,
                                        workHours: Double) -> String {
        var parts: [String] = []

        if gymSessions >= 5 {
            parts.append("Perfect gym week — \(gymSessions) sessions")
        } else if gymSessions >= 3 {
            parts.append("\(gymSessions) gym sessions")
        } else if gymSessions == 0 {
            parts.append("No gym sessions — get moving")
        } else {
            parts.append("Only \(gymSessions) gym session\(gymSessions == 1 ? "" : "s")")
        }

        if workEntries > 0 {
            parts.append("\(workEntries) work entr\(workEntries == 1 ? "y" : "ies")")
        } else {
            parts.append("zero work logged")
        }

        if studyHours >= 10 {
            parts.append(String(format: "%.0fh studied — strong", studyHours))
        } else if studyHours > 0 {
            parts.append(String(format: "%.0fh studied", studyHours))
        }

        if workHours > 0 {
            parts.append(String(format: "%.0fh work logged", workHours))
        }

        return parts.joined(separator: ". ") + "."
    }

    // MARK: - Week helpers

    static func lastISOWeekStart() -> Date {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        let today = cal.startOfDay(for: .now)
        let weekday = cal.component(.weekday, from: today)
        // Monday = 2; days since last Monday
        let daysSinceMonday = (weekday + 5) % 7
        let thisMonday = cal.date(byAdding: .day, value: -daysSinceMonday, to: today)!
        return cal.date(byAdding: .day, value: -7, to: thisMonday)!
    }

    // MARK: - Query helpers

    private static func countModels<T: PersistentModel>(
        _ type: T.Type,
        from start: Date, to end: Date,
        in context: ModelContext,
        _ predicate: @escaping (T) -> Bool
    ) -> Int {
        let descriptor = FetchDescriptor<T>()
        let all = (try? context.fetch(descriptor)) ?? []
        return all.filter(predicate).count
    }

    private static func sumXP(_ type: GymSession.Type, from start: Date, to end: Date, in context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<GymSession>()
        let all = (try? context.fetch(descriptor)) ?? []
        return all.filter { $0.date >= start && $0.date < end && !$0.isRestDay }.reduce(0) { $0 + $1.xpEarned }
    }

    private static func sumXPCardio(from start: Date, to end: Date, in context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<CardioSession>()
        let all = (try? context.fetch(descriptor)) ?? []
        return all.filter { $0.date >= start && $0.date < end }.reduce(0) { $0 + $1.xpEarned }
    }

    private static func sumXPFood(from start: Date, to end: Date, in context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<FoodEntry>()
        let all = (try? context.fetch(descriptor)) ?? []
        return all.filter { $0.date >= start && $0.date < end }.reduce(0) { $0 + $1.xpEarned }
    }

    private static func sumXPWeight(from start: Date, to end: Date, in context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<WeightEntry>()
        let all = (try? context.fetch(descriptor)) ?? []
        return all.filter { $0.date >= start && $0.date < end }.reduce(0) { $0 + $1.xpEarned }
    }

    private static func sumXPHabit(from start: Date, to end: Date, in context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<HabitLog>()
        let all = (try? context.fetch(descriptor)) ?? []
        return all.filter { $0.date >= start && $0.date < end }.reduce(0) { $0 + $1.xpEarned }
    }

    private static func countWorkEntries(from start: Date, to end: Date, in context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<WorkEntry>()
        let all = (try? context.fetch(descriptor)) ?? []
        return all.filter { $0.date >= start && $0.date < end }.count
    }

    private static func sumWorkEntryHours(from start: Date, to end: Date, in context: ModelContext) -> Double {
        let descriptor = FetchDescriptor<WorkEntry>()
        let all = (try? context.fetch(descriptor)) ?? []
        return all.filter { $0.date >= start && $0.date < end }.reduce(0) { $0 + $1.hoursSpent }
    }

    private static func sumWorkXP(from start: Date, to end: Date, in context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<WorkEntry>()
        let all = (try? context.fetch(descriptor)) ?? []
        return all.filter { $0.date >= start && $0.date < end }.reduce(0) { $0 + $1.xpEarned }
    }

    private static func sumLearningXP(from start: Date, to end: Date, in context: ModelContext) -> Int {
        let courseXP: Int = {
            let descriptor = FetchDescriptor<Course>()
            let all = (try? context.fetch(descriptor)) ?? []
            return all.reduce(0) { $0 + $1.xpEarned } // rough — courses don't have per-session dates
        }()
        return courseXP
    }

    private static func sumStudyHours(from start: Date, to end: Date, in context: ModelContext) -> Double {
        let descriptor = FetchDescriptor<Course>()
        let all = (try? context.fetch(descriptor)) ?? []
        return all.reduce(0) { $0 + $1.totalHours }
    }

    private static func habitCompletionRate(from start: Date, to end: Date, in context: ModelContext) -> Double {
        let descriptor = FetchDescriptor<HabitLog>()
        let all = (try? context.fetch(descriptor)) ?? []
        let inRange = all.filter { $0.date >= start && $0.date < end }
        guard !inRange.isEmpty else { return 0 }
        let completed = inRange.filter { $0.allCompleted }.count
        return Double(completed) / Double(inRange.count)
    }
}
