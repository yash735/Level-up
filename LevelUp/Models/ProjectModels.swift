//
//  ProjectModels.swift
//  LEVEL UP
//
//  Unified project-based work tracking. Replaces the hardcoded
//  BVA / ParaLAI / OtherWork split with a single flexible system.
//

import Foundation
import SwiftData

// MARK: - Project

@Model
final class Project {
    var id: UUID
    var name: String
    var projectDescription: String
    var createdAt: Date
    var isArchived: Bool
    var colorHex: String
    var iconName: String
    var orderIndex: Int

    @Relationship(deleteRule: .cascade, inverse: \ProjectMilestone.project)
    var milestones: [ProjectMilestone] = []

    @Relationship(deleteRule: .cascade, inverse: \WorkEntry.project)
    var entries: [WorkEntry] = []

    init(name: String,
         projectDescription: String = "",
         colorHex: String = "#FF9500",
         iconName: String = "folder.fill",
         orderIndex: Int = 0) {
        self.id = UUID()
        self.name = name
        self.projectDescription = projectDescription
        self.createdAt = .now
        self.isArchived = false
        self.colorHex = colorHex
        self.iconName = iconName
        self.orderIndex = orderIndex
    }
}

// MARK: - Project Milestone

@Model
final class ProjectMilestone {
    var id: UUID
    var project: Project?
    var title: String
    var isCompleted: Bool
    var completedAt: Date?
    var xpAwarded: Bool
    var isAISuggested: Bool
    var orderIndex: Int

    init(project: Project,
         title: String,
         isAISuggested: Bool = false,
         orderIndex: Int = 0) {
        self.id = UUID()
        self.project = project
        self.title = title
        self.isCompleted = false
        self.completedAt = nil
        self.xpAwarded = false
        self.isAISuggested = isAISuggested
        self.orderIndex = orderIndex
    }
}

// MARK: - Work Entry

@Model
final class WorkEntry {
    var id: UUID
    var project: Project?
    var date: Date
    var actionType: String
    var title: String
    var detail: String
    var hoursSpent: Double
    var xpEarned: Int
    var createdAt: Date

    init(project: Project,
         date: Date = .now,
         actionType: String,
         title: String,
         detail: String = "",
         hoursSpent: Double,
         xpEarned: Int) {
        self.id = UUID()
        self.project = project
        self.date = date
        self.actionType = actionType
        self.title = title
        self.detail = detail
        self.hoursSpent = hoursSpent
        self.xpEarned = xpEarned
        self.createdAt = .now
    }

    // MARK: - Action Types & XP

    static let actionTypes = [
        "Deep Work", "Meeting", "Research",
        "Admin", "Call", "Content", "Other"
    ]

    static func xpRate(for actionType: String) -> Int {
        switch actionType {
        case "Deep Work": return 80
        case "Research":  return 70
        case "Meeting":   return 60
        case "Call":      return 50
        case "Content":   return 50
        case "Admin":     return 40
        default:          return 60
        }
    }

    static func calculateXP(hours: Double, actionType: String) -> Int {
        let rate = xpRate(for: actionType)
        let base = max(30, Int((hours * Double(rate)).rounded()))
        let multiplied = actionType == "Deep Work"
            ? Int(Double(base) * 1.5)
            : base
        let bonus = hours >= 3.0 ? 50 : 0
        return multiplied + bonus
    }
}
