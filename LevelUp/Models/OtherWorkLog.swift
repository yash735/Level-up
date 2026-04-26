//
//  OtherWorkLog.swift
//  LEVEL UP
//
//  DEPRECATED: Kept as empty shell for SwiftData schema compatibility.
//  New code uses WorkEntry from ProjectModels.swift.
//

import Foundation
import SwiftData

@Model
final class OtherWorkLog {
    var id: UUID
    var date: Date
    var category: String?
    var targetCompany: String?
    var projectName: String
    var actionType: String
    var title: String
    var detail: String
    var hoursSpent: Double
    var xpEarned: Int
    var createdAt: Date

    init() {
        self.id = UUID()
        self.date = .now
        self.projectName = ""
        self.actionType = ""
        self.title = ""
        self.detail = ""
        self.hoursSpent = 0
        self.xpEarned = 0
        self.createdAt = .now
    }
}
