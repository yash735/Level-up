//
//  FitnessLog.swift
//  LEVEL UP
//
//  Defined now so Phase 2 logging screens have a stable target. Stores a
//  single fitness entry: workout / food / weight / habit.
//

import Foundation
import SwiftData

@Model
final class FitnessLog {
    var id: UUID
    var date: Date
    /// One of: "workout", "food", "weight", "habit".
    var type: String
    var xpEarned: Int
    var notes: String

    init(type: String, xpEarned: Int, notes: String = "", date: Date = .now) {
        self.id = UUID()
        self.date = date
        self.type = type
        self.xpEarned = xpEarned
        self.notes = notes
    }
}
