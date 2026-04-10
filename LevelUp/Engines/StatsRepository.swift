//
//  StatsRepository.swift
//  LEVEL UP — Phase 4
//
//  Centralised SwiftData query layer for the Stats screen. All raw
//  queries live here — views and view-models never build their own
//  FetchDescriptors.
//

import Foundation
import SwiftData

struct StatsRepository {
    let context: ModelContext

    // MARK: - Fitness

    func allGymSessions() -> [GymSession] {
        let d = FetchDescriptor<GymSession>(sortBy: [SortDescriptor(\.date)])
        return (try? context.fetch(d)) ?? []
    }

    func allCardioSessions() -> [CardioSession] {
        let d = FetchDescriptor<CardioSession>(sortBy: [SortDescriptor(\.date)])
        return (try? context.fetch(d)) ?? []
    }

    func allFoodEntries() -> [FoodEntry] {
        let d = FetchDescriptor<FoodEntry>(sortBy: [SortDescriptor(\.date)])
        return (try? context.fetch(d)) ?? []
    }

    func allWeightEntries() -> [WeightEntry] {
        let d = FetchDescriptor<WeightEntry>(sortBy: [SortDescriptor(\.date)])
        return (try? context.fetch(d)) ?? []
    }

    func allHabitLogs() -> [HabitLog] {
        let d = FetchDescriptor<HabitLog>(sortBy: [SortDescriptor(\.date)])
        return (try? context.fetch(d)) ?? []
    }

    // MARK: - Work

    func allDeals() -> [Deal] {
        let d = FetchDescriptor<Deal>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        return (try? context.fetch(d)) ?? []
    }

    func allParaLAIEntries() -> [ParaLAIEntry] {
        let d = FetchDescriptor<ParaLAIEntry>(sortBy: [SortDescriptor(\.date)])
        return (try? context.fetch(d)) ?? []
    }

    func allMilestones() -> [ParaLAIMilestone] {
        let d = FetchDescriptor<ParaLAIMilestone>(sortBy: [SortDescriptor(\.orderIndex)])
        return (try? context.fetch(d)) ?? []
    }

    func allOtherWorkLogs() -> [OtherWorkLog] {
        let d = FetchDescriptor<OtherWorkLog>(sortBy: [SortDescriptor(\.date)])
        return (try? context.fetch(d)) ?? []
    }

    // MARK: - Learning

    func allCourses() -> [Course] {
        let d = FetchDescriptor<Course>(sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(d)) ?? []
    }

    func allBooks() -> [Book] {
        let d = FetchDescriptor<Book>(sortBy: [SortDescriptor(\.title)])
        return (try? context.fetch(d)) ?? []
    }

    func allCertifications() -> [Certification] {
        let d = FetchDescriptor<Certification>(sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(d)) ?? []
    }

    // MARK: - Phase 3

    func allPersonalRecords() -> [PersonalRecord] {
        let d = FetchDescriptor<PersonalRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return (try? context.fetch(d)) ?? []
    }

    func allUnlocks() -> [Unlock] {
        let d = FetchDescriptor<Unlock>()
        return (try? context.fetch(d)) ?? []
    }

    func allWeeklyReports() -> [WeeklyReport] {
        let d = FetchDescriptor<WeeklyReport>(sortBy: [SortDescriptor(\.weekStartDate, order: .reverse)])
        return (try? context.fetch(d)) ?? []
    }

    func loginStreak() -> LoginStreak? {
        let d = FetchDescriptor<LoginStreak>()
        return (try? context.fetch(d))?.first
    }

    func gymSplitState() -> GymSplitState? {
        let d = FetchDescriptor<GymSplitState>()
        return (try? context.fetch(d))?.first
    }

    // MARK: - Filtered by date range

    func gymSessions(from start: Date, to end: Date) -> [GymSession] {
        allGymSessions().filter { $0.date >= start && $0.date < end && !$0.isRestDay }
    }

    func cardioSessions(from start: Date, to end: Date) -> [CardioSession] {
        allCardioSessions().filter { $0.date >= start && $0.date < end }
    }

    func foodEntries(from start: Date, to end: Date) -> [FoodEntry] {
        allFoodEntries().filter { $0.date >= start && $0.date < end }
    }

    func weightEntries(from start: Date, to end: Date) -> [WeightEntry] {
        allWeightEntries().filter { $0.date >= start && $0.date < end }
    }

    func habitLogs(from start: Date, to end: Date) -> [HabitLog] {
        allHabitLogs().filter { $0.date >= start && $0.date < end }
    }

    func otherWorkLogs(from start: Date, to end: Date) -> [OtherWorkLog] {
        allOtherWorkLogs().filter { $0.date >= start && $0.date < end }
    }

    func paralaiEntries(from start: Date, to end: Date) -> [ParaLAIEntry] {
        allParaLAIEntries().filter { $0.date >= start && $0.date < end }
    }
}
