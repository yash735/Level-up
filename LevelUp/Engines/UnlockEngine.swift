//
//  UnlockEngine.swift
//  LEVEL UP
//
//  Owns two jobs:
//    1. Seeding the full unlock catalog into SwiftData on first launch.
//    2. Evaluating the current User against all locked unlocks and
//       flipping any that have now been earned.
//
//  All unlock metadata lives in `seedCatalog` below — the single place to
//  add or tweak rewards.
//

import Foundation
import SwiftData

enum UnlockEngine {

    // MARK: - Seeding

    /// The full hand-authored unlock list. Order is cosmetic only.
    static var seedCatalog: [Unlock] {
        [
            // ────────── Fitness ──────────
            Unlock(track: "fitness", title: "Attempt a 5K Run",
                   detail: "Level 3 Fitness reward",
                   levelRequired: 3,  iconName: "figure.run"),
            Unlock(track: "fitness", title: "Attempt a 10K Run",
                   detail: "Level 5 Fitness reward",
                   levelRequired: 5,  iconName: "figure.run"),
            Unlock(track: "fitness", title: "100kg Bench Press Challenge",
                   detail: "Level 6 Fitness reward",
                   levelRequired: 6,  iconName: "dumbbell.fill"),
            Unlock(track: "fitness", title: "Attempt a Half Marathon",
                   detail: "Level 8 Fitness reward",
                   levelRequired: 8,  iconName: "figure.run.circle"),
            Unlock(track: "fitness", title: "First Visible Physique Transformation",
                   detail: "Level 10 Fitness reward",
                   levelRequired: 10, iconName: "figure.strengthtraining.traditional"),
            Unlock(track: "fitness", title: "Attempt a Full Marathon",
                   detail: "Level 12 Fitness reward",
                   levelRequired: 12, iconName: "figure.run.circle.fill"),
            Unlock(track: "fitness", title: "Attempt a Sprint Triathlon",
                   detail: "Level 18 Fitness reward",
                   levelRequired: 18, iconName: "figure.pool.swim"),
            Unlock(track: "fitness", title: "Attempt an Olympic Triathlon",
                   detail: "Level 25 Fitness reward",
                   levelRequired: 25, iconName: "figure.pool.swim.circle.fill"),
            Unlock(track: "fitness", title: "Attempt a Half Ironman",
                   detail: "Level 35 Fitness reward",
                   levelRequired: 35, iconName: "bolt.heart.fill"),
            Unlock(track: "fitness", title: "Attempt a Full Ironman Triathlon",
                   detail: "Level 50 Fitness — apex",
                   levelRequired: 50, iconName: "trophy.fill"),

            // ────────── Work ──────────
            Unlock(track: "work", title: "First BVA Deal Closed",
                   detail: "Level 3 Work badge",
                   levelRequired: 3,  iconName: "checkmark.seal.fill"),
            Unlock(track: "work", title: "ParaLAI v1 Shipped",
                   detail: "Level 5 Work badge",
                   levelRequired: 5,  iconName: "shippingbox.fill"),
            Unlock(track: "work", title: "$1M Deal Advised",
                   detail: "Level 8 Work milestone",
                   levelRequired: 8,  iconName: "dollarsign.circle.fill"),
            Unlock(track: "work", title: "$10M Deal Advised",
                   detail: "Level 12 Work milestone",
                   levelRequired: 12, iconName: "dollarsign.arrow.circlepath"),
            Unlock(track: "work", title: "First Investor Meeting",
                   detail: "Level 15 Work badge",
                   levelRequired: 15, iconName: "person.2.fill"),
            Unlock(track: "work", title: "Venture Creation",
                   detail: "Level 20 Work badge",
                   levelRequired: 20, iconName: "building.2.crop.circle.fill"),
            Unlock(track: "work", title: "Press Feature",
                   detail: "Level 25 Work badge",
                   levelRequired: 25, iconName: "newspaper.fill"),
            Unlock(track: "work", title: "$100M Deal Advised",
                   detail: "Level 35 Work milestone",
                   levelRequired: 35, iconName: "crown.fill"),

            // ────────── Learning ──────────
            Unlock(track: "learning", title: "100 Hours Studied",
                   detail: "Level 3 Learning badge",
                   levelRequired: 3,  iconName: "book.fill"),
            Unlock(track: "learning", title: "First Course Completed",
                   detail: "Level 5 Learning badge",
                   levelRequired: 5,  iconName: "graduationcap.fill"),
            Unlock(track: "learning", title: "Finance Foundations",
                   detail: "Level 8 Learning title",
                   levelRequired: 8,  iconName: "chart.line.uptrend.xyaxis"),
            Unlock(track: "learning", title: "Deal Architect",
                   detail: "Level 12 Learning title",
                   levelRequired: 12, iconName: "doc.text.magnifyingglass"),
            Unlock(track: "learning", title: "500 Hours Studied",
                   detail: "Level 15 Learning badge",
                   levelRequired: 15, iconName: "books.vertical.fill"),
            Unlock(track: "learning", title: "CFA Ready",
                   detail: "Level 20 Learning badge",
                   levelRequired: 20, iconName: "medal.fill"),
            Unlock(track: "learning", title: "Venture Scholar",
                   detail: "Level 25 Learning title",
                   levelRequired: 25, iconName: "brain.head.profile"),
            Unlock(track: "learning", title: "1000 Hours Studied",
                   detail: "Level 35 Learning badge",
                   levelRequired: 35, iconName: "books.vertical.circle.fill"),

            // ────────── Combined ──────────
            Unlock(track: "combined", title: "Hustler",
                   detail: "Total Level 10 title",
                   levelRequired: 10, iconName: "bolt.fill"),
            Unlock(track: "combined", title: "Founder Athlete",
                   detail: "Total Level 20 title",
                   levelRequired: 20, iconName: "figure.run.circle.fill"),
            Unlock(track: "combined", title: "The Machine",
                   detail: "Total Level 30 title",
                   levelRequired: 30, iconName: "gearshape.2.fill"),
            Unlock(track: "combined", title: "Founder Athlete Scholar",
                   detail: "Total Level 40 title",
                   levelRequired: 40, iconName: "star.circle.fill"),
            Unlock(track: "combined", title: "LEVEL UP Complete — Season 1 Done",
                   detail: "Total Level 50 — apex",
                   levelRequired: 50, iconName: "crown.fill")
        ]
    }

    /// Insert the full catalog into the given context. Safe to call once
    /// on very-first launch — DashboardView checks first that the table
    /// is empty before invoking.
    static func seedUnlocks(into context: ModelContext) {
        for unlock in seedCatalog {
            context.insert(unlock)
        }
    }

    // MARK: - Evaluation

    /// Walk every locked Unlock and flip any the user now qualifies for.
    /// Returns the list of newly-unlocked items so the caller can trigger
    /// UI / notifications.
    @discardableResult
    static func evaluateUnlocks(user: User, context: ModelContext) -> [Unlock] {
        let descriptor = FetchDescriptor<Unlock>(
            predicate: #Predicate<Unlock> { !$0.isUnlocked }
        )
        guard let locked = try? context.fetch(descriptor) else { return [] }

        var newlyUnlocked: [Unlock] = []
        let now = Date()

        for unlock in locked {
            let qualifies: Bool
            switch unlock.track {
            case "fitness":  qualifies = user.fitnessLevel  >= unlock.levelRequired
            case "work":     qualifies = user.workLevel     >= unlock.levelRequired
            case "learning": qualifies = user.learningLevel >= unlock.levelRequired
            case "combined": qualifies = user.totalLevel    >= unlock.levelRequired
            default:         qualifies = false
            }
            if qualifies {
                unlock.isUnlocked = true
                unlock.unlockedAt = now
                newlyUnlocked.append(unlock)
            }
        }
        try? context.save()
        return newlyUnlocked
    }
}
