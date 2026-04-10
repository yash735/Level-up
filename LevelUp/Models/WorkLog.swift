//
//  WorkLog.swift
//  LEVEL UP
//
//  Captures a single piece of work-track activity. `type` is either
//  "paralai" or "bva"; `action` is the specific action (feature, bug,
//  milestone, deal added, deal closed, meeting, etc.).
//

import Foundation
import SwiftData

@Model
final class WorkLog {
    var id: UUID
    var date: Date
    /// "paralai" or "bva".
    var type: String
    /// Free-form action tag, e.g. "feature", "bug", "deal_closed".
    var action: String
    var xpEarned: Int
    var notes: String

    init(type: String, action: String, xpEarned: Int, notes: String = "", date: Date = .now) {
        self.id = UUID()
        self.date = date
        self.type = type
        self.action = action
        self.xpEarned = xpEarned
        self.notes = notes
    }
}
