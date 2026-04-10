//
//  WeeklyReport.swift
//  LEVEL UP — Phase 4
//
//  Stores a generated weekly report. One row per ISO week.
//  Generated automatically on Monday app-open by WeeklyReportEngine.
//

import Foundation
import SwiftData

@Model
final class WeeklyReport {
    var id: UUID
    var weekStartDate: Date
    var weekEndDate: Date
    var totalXP: Int
    var fitnessXP: Int
    var workXP: Int
    var learningXP: Int
    var workoutsCompleted: Int
    var gymSessionsCompleted: Int
    var bvaActionsCount: Int
    var paralaiLogsCount: Int
    var otherWorkHours: Double
    var studyHours: Double
    var habitsCompletionRate: Double
    /// Percentage change vs prior week. Positive = improved.
    var xpChangeVsLastWeek: Double
    /// S / A / B / C / D
    var grade: String
    var summaryText: String
    var createdAt: Date

    init(weekStartDate: Date,
         weekEndDate: Date,
         totalXP: Int = 0,
         fitnessXP: Int = 0,
         workXP: Int = 0,
         learningXP: Int = 0,
         workoutsCompleted: Int = 0,
         gymSessionsCompleted: Int = 0,
         bvaActionsCount: Int = 0,
         paralaiLogsCount: Int = 0,
         otherWorkHours: Double = 0,
         studyHours: Double = 0,
         habitsCompletionRate: Double = 0,
         xpChangeVsLastWeek: Double = 0,
         grade: String = "C",
         summaryText: String = "") {
        self.id = UUID()
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.totalXP = totalXP
        self.fitnessXP = fitnessXP
        self.workXP = workXP
        self.learningXP = learningXP
        self.workoutsCompleted = workoutsCompleted
        self.gymSessionsCompleted = gymSessionsCompleted
        self.bvaActionsCount = bvaActionsCount
        self.paralaiLogsCount = paralaiLogsCount
        self.otherWorkHours = otherWorkHours
        self.studyHours = studyHours
        self.habitsCompletionRate = habitsCompletionRate
        self.xpChangeVsLastWeek = xpChangeVsLastWeek
        self.grade = grade
        self.summaryText = summaryText
        self.createdAt = .now
    }
}
