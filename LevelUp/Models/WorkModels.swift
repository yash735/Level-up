//
//  WorkModels.swift
//  LEVEL UP
//
//  DEPRECATED: Kept as empty shells for SwiftData schema compatibility.
//  New code uses Project/WorkEntry/ProjectMilestone from ProjectModels.swift.
//

import Foundation
import SwiftData

@Model
final class Deal {
    var id: UUID
    var dealName: String
    var companyName: String
    var dealSizeMillion: Double
    var stage: String
    var dealType: String
    var nextAction: String
    var nextActionDue: Date?
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    var xpEarned: Int
    var isClosedWon: Bool
    var isClosedLost: Bool

    init() {
        self.id = UUID()
        self.dealName = ""
        self.companyName = ""
        self.dealSizeMillion = 0
        self.stage = ""
        self.dealType = ""
        self.nextAction = ""
        self.notes = ""
        self.createdAt = .now
        self.updatedAt = .now
        self.xpEarned = 0
        self.isClosedWon = false
        self.isClosedLost = false
    }
}

@Model
final class ParaLAIMilestone {
    var id: UUID
    var name: String
    var orderIndex: Int
    var isCompleted: Bool
    var completedAt: Date?
    var xpAwarded: Bool

    init() {
        self.id = UUID()
        self.name = ""
        self.orderIndex = 0
        self.isCompleted = false
        self.xpAwarded = false
    }
}

@Model
final class ParaLAIEntry {
    var id: UUID
    var date: Date
    var actionType: String
    var title: String
    var detail: String
    var hoursSpent: Double
    var xpEarned: Int

    init() {
        self.id = UUID()
        self.date = .now
        self.actionType = ""
        self.title = ""
        self.detail = ""
        self.hoursSpent = 0
        self.xpEarned = 0
    }
}
