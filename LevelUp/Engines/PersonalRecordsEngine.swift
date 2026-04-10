//
//  PersonalRecordsEngine.swift
//  LEVEL UP — Phase 3
//
//  Scans the player's logs and detects when a new personal best is hit.
//  Fires RecordEvent through GameEventCenter and writes a PersonalRecord
//  row so the "all records" archive has a complete history.
//
//  Records tracked in v1:
//    Fitness — heaviest lift (weight × reps), longest cardio distance
//    Work — biggest closed deal value
//    Learning — longest study streak in minutes (per course / cert session)
//
//  Each record is identified by a stable `key` so we can look up the
//  previous best without a migration.
//

import Foundation
import SwiftData

enum PersonalRecordsEngine {

    // MARK: - Current record query

    /// Returns the most recent PersonalRecord row with this key, or nil
    /// if none yet. (We keep full history — every break is a new row.)
    static func previousBest(key: String,
                             in context: ModelContext) -> PersonalRecord? {
        var descriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate<PersonalRecord> { record in record.key == key },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    // MARK: - Fitness records

    /// Biggest single-set tonnage (weight kg × reps) across all Exercise
    /// rows in a gym session. Pass every exercise just logged.
    @MainActor
    static func evaluateLift(exercises: [Exercise],
                             in context: ModelContext) {
        guard !exercises.isEmpty else { return }

        // Find this session's strongest set.
        var bestTonnage: Double = 0
        var bestExercise: Exercise?
        for ex in exercises {
            let tonnage = ex.weightKg * Double(max(1, ex.reps))
            if tonnage > bestTonnage {
                bestTonnage = tonnage
                bestExercise = ex
            }
        }

        guard bestTonnage > 0, let ex = bestExercise else { return }

        let key = "lift-\(ex.name.lowercased().replacingOccurrences(of: " ", with: "-"))"
        let prev = previousBest(key: key, in: context)
        let prevTonnage: Double = {
            guard let prev, let existing = Double(prev.value.split(separator: " ").first ?? "0") else { return 0 }
            return existing
        }()

        if bestTonnage > prevTonnage {
            let valueStr = String(format: "%.0f kg-vol (%d×%.0f)",
                                  bestTonnage, ex.reps, ex.weightKg)
            let record = PersonalRecord(key: key,
                                        track: "Fitness",
                                        title: "Biggest \(ex.name)",
                                        value: valueStr)
            context.insert(record)
            try? context.save()
            GameEventCenter.shared.fireRecord(track: .fitness,
                                              title: record.title,
                                              value: record.value)
        }
    }

    @MainActor
    static func evaluateCardio(session: CardioSession,
                               in context: ModelContext) {
        guard session.distanceKm > 0 else { return }
        let key = "cardio-distance-\(session.type.lowercased())"
        let prev = previousBest(key: key, in: context)
        let prevDistance = Double(prev?.value.split(separator: " ").first ?? "0") ?? 0

        if session.distanceKm > prevDistance {
            let valueStr = String(format: "%.1f km", session.distanceKm)
            let record = PersonalRecord(key: key,
                                        track: "Fitness",
                                        title: "Longest \(session.type)",
                                        value: valueStr)
            context.insert(record)
            try? context.save()
            GameEventCenter.shared.fireRecord(track: .fitness,
                                              title: record.title,
                                              value: record.value)
        }
    }

    // MARK: - Work records

    /// Call when a deal closes. `valueUSD` is raw USD value.
    @MainActor
    static func evaluateDealClose(valueUSD: Double,
                                  dealName: String,
                                  in context: ModelContext) {
        let key = "biggest-deal"
        let prev = previousBest(key: key, in: context)
        // Stored value format: "4.20" (millions, 2dp) — parse back.
        let prevMillions = Double(prev?.value.replacingOccurrences(of: "$", with: "")
                                                .replacingOccurrences(of: "M", with: "") ?? "0") ?? 0
        let thisMillions = valueUSD / 1_000_000

        if thisMillions > prevMillions {
            let valueStr = String(format: "$%.2fM", thisMillions)
            let record = PersonalRecord(key: key,
                                        track: "Work",
                                        title: "Biggest Deal: \(dealName)",
                                        value: valueStr)
            context.insert(record)
            try? context.save()
            GameEventCenter.shared.fireRecord(track: .work,
                                              title: record.title,
                                              value: record.value)
        }
    }

    // MARK: - Learning records

    /// Call when a study session is logged. `minutes` is raw duration.
    @MainActor
    static func evaluateStudySession(minutes: Int,
                                     courseName: String,
                                     in context: ModelContext) {
        guard minutes > 0 else { return }
        let key = "longest-study-session"
        let prev = previousBest(key: key, in: context)
        let prevMinutes = Int(prev?.value.split(separator: " ").first ?? "0") ?? 0

        if minutes > prevMinutes {
            let valueStr = "\(minutes) min"
            let record = PersonalRecord(key: key,
                                        track: "Learning",
                                        title: "Longest Study Session",
                                        value: valueStr)
            context.insert(record)
            try? context.save()
            GameEventCenter.shared.fireRecord(track: .learning,
                                              title: record.title,
                                              value: record.value)
        }
    }
}
