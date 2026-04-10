//
//  FitnessViewModel.swift
//  LEVEL UP — Phase 2
//
//  Struct view-model rebuilt per render from @Query data in FitnessView.
//  Keeps the tab views free of aggregation logic.
//

import Foundation

struct FitnessViewModel {

    // Raw data
    let gymSessions: [GymSession]
    let cardioSessions: [CardioSession]
    let foodEntries: [FoodEntry]
    let weightEntries: [WeightEntry]
    let habitLogs: [HabitLog]

    // MARK: - Workout tab

    /// 4 most recent gym sessions (weights) for the history list.
    var recentGymSessions: [GymSession] {
        gymSessions.sorted { $0.date > $1.date }.prefix(6).map { $0 }
    }

    /// 4 most recent cardio sessions.
    var recentCardioSessions: [CardioSession] {
        cardioSessions.sorted { $0.date > $1.date }.prefix(4).map { $0 }
    }

    /// Total gym sessions logged this ISO week.
    var sessionsThisWeek: Int {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        guard let interval = cal.dateInterval(of: .weekOfYear, for: .now) else { return 0 }
        return gymSessions.filter {
            !$0.isRestDay && $0.date >= interval.start && $0.date < interval.end
        }.count
    }

    // MARK: - Food tab

    /// Today's meals grouped.
    var todaysFood: [FoodEntry] {
        let today = Calendar.current.startOfDay(for: .now)
        return foodEntries.filter {
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }
        .sorted { $0.date < $1.date }
    }

    var todaysCalories: Int { todaysFood.reduce(0) { $0 + $1.calories } }
    var todaysProtein: Double { todaysFood.reduce(0) { $0 + $1.protein } }
    var todaysCarbs: Double { todaysFood.reduce(0) { $0 + $1.carbs } }
    var todaysFats: Double { todaysFood.reduce(0) { $0 + $1.fats } }

    // MARK: - Weight tab

    /// Weight entries sorted oldest → newest for the chart.
    var weightSeries: [WeightEntry] {
        weightEntries.sorted { $0.date < $1.date }
    }

    /// Most recent weight entry.
    var latestWeight: WeightEntry? { weightSeries.last }

    /// First ever weight entry, used for delta display.
    var firstWeight: WeightEntry? { weightSeries.first }

    var weightDelta: Double? {
        guard let first = firstWeight, let last = latestWeight, first.id != last.id else { return nil }
        return last.weightKg - first.weightKg
    }

    // MARK: - Habits tab

    /// Today's habit log row if one exists.
    func todayHabitLog() -> HabitLog? {
        let today = Calendar.current.startOfDay(for: .now)
        return habitLogs.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    /// Recent 7 day habit logs (newest first) for the streak strip.
    var recentHabitLogs: [HabitLog] {
        habitLogs.sorted { $0.date > $1.date }.prefix(7).map { $0 }
    }
}
