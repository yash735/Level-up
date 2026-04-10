//
//  LearningViewModel.swift
//  LEVEL UP — Phase 2
//
//  Struct view-model. Aggregates the three Learning entities so the
//  tab views can stay thin.
//

import Foundation

struct LearningViewModel {

    let courses: [Course]
    let books: [Book]
    let certifications: [Certification]

    // MARK: - Courses

    var coursesInProgress: [Course] {
        courses.filter { !$0.isCompleted }
            .sorted { $0.startedAt > $1.startedAt }
    }

    var completedCourses: [Course] {
        courses.filter { $0.isCompleted }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    var totalCourseHours: Double { courses.reduce(0) { $0 + $1.totalHours } }

    // MARK: - Books

    var booksInProgress: [Book] {
        books.filter { !$0.isFinished }
            .sorted { $0.startedAt > $1.startedAt }
    }

    var finishedBooks: [Book] {
        books.filter { $0.isFinished }
            .sorted { ($0.finishedAt ?? .distantPast) > ($1.finishedAt ?? .distantPast) }
    }

    // MARK: - Certifications

    var activeCertifications: [Certification] {
        certifications.filter { !$0.isEarned }
            .sorted { ($0.targetDate ?? .distantFuture) < ($1.targetDate ?? .distantFuture) }
    }

    var earnedCertifications: [Certification] {
        certifications.filter { $0.isEarned }
            .sorted { ($0.earnedAt ?? .distantPast) > ($1.earnedAt ?? .distantPast) }
    }

    // MARK: - Totals

    var totalStudyHours: Double {
        totalCourseHours
            + books.reduce(0) { $0 + $1.totalHours }
            + certifications.reduce(0) { $0 + $1.studiedHours }
    }
}
