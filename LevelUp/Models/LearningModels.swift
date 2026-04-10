//
//  LearningModels.swift
//  LEVEL UP — Phase 2
//
//  Course / Book / Certification models for the Learning track. Each one
//  carries its own progress fields so per-card progress bars can render
//  without joining against a separate log table.
//

import Foundation
import SwiftData

// MARK: - Course

@Model
final class Course {
    var id: UUID
    var name: String
    /// Udemy / Coursera / YouTube / CFA Institute / Other
    var platform: String
    /// Finance / Tech / Business / Marketing / Other
    var category: String
    var totalLessons: Int
    var completedLessons: Int
    var totalHours: Double
    var xpEarned: Int
    var isCompleted: Bool
    var startedAt: Date
    var completedAt: Date?

    init(name: String,
         platform: String,
         category: String,
         totalLessons: Int) {
        self.id = UUID()
        self.name = name
        self.platform = platform
        self.category = category
        self.totalLessons = totalLessons
        self.completedLessons = 0
        self.totalHours = 0
        self.xpEarned = 0
        self.isCompleted = false
        self.startedAt = .now
        self.completedAt = nil
    }

    var progress: Double {
        guard totalLessons > 0 else { return 0 }
        return min(1, Double(completedLessons) / Double(totalLessons))
    }
}

// MARK: - Book

@Model
final class Book {
    var id: UUID
    var title: String
    var author: String
    /// Finance / Business / Biography / Self Development / Other
    var category: String
    var totalPages: Int
    var pagesRead: Int
    var totalHours: Double
    var xpEarned: Int
    var isFinished: Bool
    var startedAt: Date
    var finishedAt: Date?

    init(title: String, author: String, category: String, totalPages: Int) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.category = category
        self.totalPages = totalPages
        self.pagesRead = 0
        self.totalHours = 0
        self.xpEarned = 0
        self.isFinished = false
        self.startedAt = .now
        self.finishedAt = nil
    }

    var progress: Double {
        guard totalPages > 0 else { return 0 }
        return min(1, Double(pagesRead) / Double(totalPages))
    }
}

// MARK: - Certification

@Model
final class Certification {
    var id: UUID
    var name: String
    var issuingBody: String
    var targetDate: Date?
    var estimatedHours: Double
    var studiedHours: Double
    var xpEarned: Int
    var isEarned: Bool
    var earnedAt: Date?

    init(name: String,
         issuingBody: String,
         targetDate: Date? = nil,
         estimatedHours: Double = 0) {
        self.id = UUID()
        self.name = name
        self.issuingBody = issuingBody
        self.targetDate = targetDate
        self.estimatedHours = estimatedHours
        self.studiedHours = 0
        self.xpEarned = 0
        self.isEarned = false
        self.earnedAt = nil
    }

    var progress: Double {
        guard estimatedHours > 0 else { return 0 }
        return min(1, studiedHours / estimatedHours)
    }
}
