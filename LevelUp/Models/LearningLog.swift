//
//  LearningLog.swift
//  LEVEL UP
//
//  Captures study sessions, finished books, completed courses, and any
//  certification earned. Phase 2 will attach entry screens to this.
//

import Foundation
import SwiftData

@Model
final class LearningLog {
    var id: UUID
    var date: Date
    /// "course", "book", "certification", or "study".
    var type: String
    /// Human-readable name — course title, book title, cert name, etc.
    var name: String
    /// Only relevant for "study" entries; other types pass 0.
    var hoursStudied: Double
    var xpEarned: Int
    var notes: String

    init(type: String,
         name: String,
         hoursStudied: Double = 0,
         xpEarned: Int,
         notes: String = "",
         date: Date = .now) {
        self.id = UUID()
        self.date = date
        self.type = type
        self.name = name
        self.hoursStudied = hoursStudied
        self.xpEarned = xpEarned
        self.notes = notes
    }
}
