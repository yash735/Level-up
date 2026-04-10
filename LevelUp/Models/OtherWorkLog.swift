//
//  OtherWorkLog.swift
//  LEVEL UP — Phase 4.5
//
//  Structured project work logger with category-based XP rates,
//  target company tracking for acquisitions research, and
//  project-level analytics.
//

import Foundation
import SwiftData

@Model
final class OtherWorkLog {
    var id: UUID
    var date: Date
    /// Category: Acquisitions Research / Investor Relations / Market Research /
    /// Venture Building / Admin & Ops / Content & Brand / Other
    /// Optional for migration from pre-Phase-4.5 rows; resolves to "Other".
    var category: String?
    /// Optional target company for Acquisitions Research logs.
    var targetCompany: String?
    /// Free text project/area name.
    var projectName: String
    /// Deep Work / Meeting / Research / Admin / Call / Content / Other
    var actionType: String
    var title: String
    var detail: String
    var hoursSpent: Double
    var xpEarned: Int
    var createdAt: Date

    init(date: Date = .now,
         category: String = "Other",
         targetCompany: String? = nil,
         projectName: String,
         actionType: String,
         title: String,
         detail: String = "",
         hoursSpent: Double,
         xpEarned: Int) {
        self.id = UUID()
        self.date = date
        self.category = category
        self.targetCompany = targetCompany
        self.projectName = projectName
        self.actionType = actionType
        self.title = title
        self.detail = detail
        self.hoursSpent = hoursSpent
        self.xpEarned = xpEarned
        self.createdAt = .now
    }

    /// Resolved category — treats nil (pre-4.5 rows) as "Other".
    var resolvedCategory: String {
        get { category ?? "Other" }
        set { category = newValue }
    }

    // MARK: - Categories

    static let categories = [
        "Acquisitions Research",
        "Investor Relations",
        "Market Research",
        "Venture Building",
        "Admin & Ops",
        "Content & Brand",
        "Other"
    ]

    static let actionTypes = [
        "Deep Work", "Meeting", "Research",
        "Admin", "Call", "Content", "Other"
    ]

    // MARK: - XP Calculation

    static func xpRate(for category: String) -> Int {
        switch category {
        case "Acquisitions Research": return 80
        case "Investor Relations":   return 75
        case "Market Research":      return 70
        case "Venture Building":     return 80
        case "Admin & Ops":          return 40
        case "Content & Brand":      return 50
        default:                     return 60
        }
    }

    /// Category-based XP rates per hour. Deep Work gets 1.5x.
    /// 3+ hour sessions earn a 50 XP bonus. Minimum 30 XP.
    static func calculateXP(hours: Double, actionType: String, category: String = "Other") -> Int {
        let rate = xpRate(for: category)
        let base = max(30, Int((hours * Double(rate)).rounded()))
        let multiplied = actionType == "Deep Work"
            ? Int(Double(base) * 1.5)
            : base
        let bonus = hours >= 3.0 ? 50 : 0
        return multiplied + bonus
    }
}
