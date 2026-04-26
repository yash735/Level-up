//
//  WorkViewModel.swift
//  LEVEL UP
//
//  Struct view-model rebuilt per render. Aggregates project-based
//  work entries and milestones across all projects.
//

import Foundation

struct WorkViewModel {

    let projects: [Project]
    let entries: [WorkEntry]
    let milestones: [ProjectMilestone]

    // MARK: - Projects

    /// Active (non-archived) projects sorted by orderIndex.
    var activeProjects: [Project] {
        projects
            .filter { !$0.isArchived }
            .sorted { $0.orderIndex < $1.orderIndex }
    }

    // MARK: - Entries

    /// All entries for a given project, sorted by date descending.
    func entries(for project: Project) -> [WorkEntry] {
        entries
            .filter { $0.project?.id == project.id }
            .sorted { $0.date > $1.date }
    }

    /// Most recent entries for a project, capped at `limit`.
    func recentEntries(for project: Project, limit: Int = 6) -> [WorkEntry] {
        Array(entries(for: project).prefix(limit))
    }

    // MARK: - Milestones

    /// Milestones for a given project, sorted by orderIndex.
    func milestones(for project: Project) -> [ProjectMilestone] {
        milestones
            .filter { $0.project?.id == project.id }
            .sorted { $0.orderIndex < $1.orderIndex }
    }

    // MARK: - Hours

    /// Total hours logged against a single project.
    func totalHours(for project: Project) -> Double {
        entries
            .filter { $0.project?.id == project.id }
            .reduce(0) { $0 + $1.hoursSpent }
    }

    /// Total hours across all entries in the last 7 days.
    var hoursThisWeek: Double {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .distantPast
        return entries
            .filter { $0.date >= cutoff }
            .reduce(0) { $0 + $1.hoursSpent }
    }

    /// Number of entries logged in the last 7 days.
    var entriesThisWeek: Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .distantPast
        return entries.filter { $0.date >= cutoff }.count
    }

    /// Deep Work sessions in the last 7 days.
    var deepWorkSessionsThisWeek: Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .distantPast
        return entries.filter { $0.date >= cutoff && $0.actionType == "Deep Work" }.count
    }
}
