//
//  BaselineCalculator.swift
//  LEVEL UP — Phase 4.5
//
//  Computes trailing 4-week averages for each metric to drive
//  dynamic challenge difficulty. Stores one BaselineStats row
//  per week.
//

import Foundation
import SwiftData

enum BaselineCalculator {

    /// Calculate and store baseline stats for the current week.
    /// Returns the baseline (or nil if < 4 weeks of data).
    @MainActor
    static func calculateIfNeeded(in context: ModelContext) -> BaselineStats? {
        let cal = Calendar.current
        let thisMonday = WeeklyReportEngine.lastISOWeekStart()
        // Advance to this week's Monday
        let weekStart = cal.date(byAdding: .day, value: 7, to: thisMonday)!

        // Check if baseline already exists for this week
        let existing = FetchDescriptor<BaselineStats>()
        let allBaselines = (try? context.fetch(existing)) ?? []
        let startOfWeekDay = cal.startOfDay(for: weekStart)
        if allBaselines.contains(where: { cal.isDate($0.weekOf, inSameDayAs: startOfWeekDay) }) {
            return allBaselines.first { cal.isDate($0.weekOf, inSameDayAs: startOfWeekDay) }
        }

        // Need at least 4 weeks of data
        let fourWeeksAgo = cal.date(byAdding: .day, value: -28, to: weekStart)!

        // Gym sessions
        let gymDesc = FetchDescriptor<GymSession>()
        let allGym = (try? context.fetch(gymDesc)) ?? []
        let recentGym = allGym.filter { $0.date >= fourWeeksAgo && $0.date < weekStart && !$0.isRestDay }
        let avgGymSessions = Double(recentGym.count) / 4.0

        // Work hours (ParaLAI + OtherWorkLog)
        let paralaiDesc = FetchDescriptor<ParaLAIEntry>()
        let allParalai = (try? context.fetch(paralaiDesc)) ?? []
        let recentParalai = allParalai.filter { $0.date >= fourWeeksAgo && $0.date < weekStart }
        let paralaiHours = recentParalai.reduce(0.0) { $0 + $1.hoursSpent }

        let otherDesc = FetchDescriptor<OtherWorkLog>()
        let allOther = (try? context.fetch(otherDesc)) ?? []
        let recentOther = allOther.filter { $0.date >= fourWeeksAgo && $0.date < weekStart }
        let otherHours = recentOther.reduce(0.0) { $0 + $1.hoursSpent }
        let avgWorkHours = (paralaiHours + otherHours) / 4.0

        // Study hours
        let courseDesc = FetchDescriptor<Course>()
        let allCourses = (try? context.fetch(courseDesc)) ?? []
        let avgStudyHours = allCourses.reduce(0.0) { $0 + $1.totalHours } / max(1, Double(allBaselines.count + 1))

        // Habits completion rate
        let habitDesc = FetchDescriptor<HabitLog>()
        let allHabits = (try? context.fetch(habitDesc)) ?? []
        let recentHabits = allHabits.filter { $0.date >= fourWeeksAgo && $0.date < weekStart }
        let avgHabitsRate: Double
        if recentHabits.isEmpty {
            avgHabitsRate = 0
        } else {
            let completed = recentHabits.filter { $0.allCompleted }.count
            avgHabitsRate = Double(completed) / Double(recentHabits.count)
        }

        // BVA actions
        let dealDesc = FetchDescriptor<Deal>()
        let allDeals = (try? context.fetch(dealDesc)) ?? []
        let recentDeals = allDeals.filter { $0.updatedAt >= fourWeeksAgo && $0.updatedAt < weekStart }
        let avgBVAActions = Double(recentDeals.count) / 4.0

        let baseline = BaselineStats(
            weekOf: startOfWeekDay,
            avgWorkHours: avgWorkHours,
            avgGymSessions: avgGymSessions,
            avgStudyHours: avgStudyHours,
            avgHabitsRate: avgHabitsRate,
            avgBVAActions: avgBVAActions
        )
        context.insert(baseline)
        try? context.save()
        return baseline
    }

    /// Returns the most recent baseline, or nil.
    static func latestBaseline(in context: ModelContext) -> BaselineStats? {
        let desc = FetchDescriptor<BaselineStats>(
            sortBy: [SortDescriptor(\.weekOf, order: .reverse)]
        )
        return (try? context.fetch(desc))?.first
    }
}
