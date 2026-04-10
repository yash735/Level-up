//
//  WorkModels.swift
//  LEVEL UP — Phase 2
//
//  ParaLAI + BVA models.
//

import Foundation
import SwiftData

// MARK: - Deal (BVA)

@Model
final class Deal {
    var id: UUID
    var dealName: String
    var companyName: String
    /// Size in millions of USD. Decimal so you can enter e.g. 2.5.
    var dealSizeMillion: Double
    /// Prospecting / Initial Contact / Due Diligence / Term Sheet / Closing / Closed Won / Closed Lost
    var stage: String
    /// Growth Capital / Debt Structuring / M&A Advisory / Private Credit / Deal Structuring
    var dealType: String
    var nextAction: String
    var nextActionDue: Date?
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    /// Total XP earned from actions on this deal (add, stage updates, close).
    var xpEarned: Int
    var isClosedWon: Bool
    var isClosedLost: Bool

    init(dealName: String,
         companyName: String,
         dealSizeMillion: Double,
         stage: String,
         dealType: String,
         nextAction: String = "",
         nextActionDue: Date? = nil,
         notes: String = "") {
        self.id = UUID()
        self.dealName = dealName
        self.companyName = companyName
        self.dealSizeMillion = dealSizeMillion
        self.stage = stage
        self.dealType = dealType
        self.nextAction = nextAction
        self.nextActionDue = nextActionDue
        self.notes = notes
        self.createdAt = .now
        self.updatedAt = .now
        self.xpEarned = 0
        self.isClosedWon = false
        self.isClosedLost = false
    }

    /// Red badge when the next action date has passed.
    var isOverdue: Bool {
        guard let due = nextActionDue, !isClosedWon, !isClosedLost else { return false }
        return due < Calendar.current.startOfDay(for: .now)
    }

    var isClosed: Bool { isClosedWon || isClosedLost }
}

// MARK: - ParaLAI milestone

@Model
final class ParaLAIMilestone {
    var id: UUID
    var name: String
    /// Display order (0...9).
    var orderIndex: Int
    var isCompleted: Bool
    var completedAt: Date?
    /// True once the +300 XP bonus has been granted.
    var xpAwarded: Bool

    init(name: String, orderIndex: Int) {
        self.id = UUID()
        self.name = name
        self.orderIndex = orderIndex
        self.isCompleted = false
        self.completedAt = nil
        self.xpAwarded = false
    }
}

// MARK: - ParaLAI work entry

@Model
final class ParaLAIEntry {
    var id: UUID
    var date: Date
    /// Feature Built / Bug Fixed / Milestone Shipped / Meeting / Research / Other
    var actionType: String
    var title: String
    var detail: String
    var hoursSpent: Double
    var xpEarned: Int

    init(date: Date = .now,
         actionType: String,
         title: String,
         detail: String = "",
         hoursSpent: Double = 0,
         xpEarned: Int = 0) {
        self.id = UUID()
        self.date = date
        self.actionType = actionType
        self.title = title
        self.detail = detail
        self.hoursSpent = hoursSpent
        self.xpEarned = xpEarned
    }
}
