//
//  SeasonManager.swift
//  LEVEL UP — Phase 4.5
//
//  Handles season carryover rewards. When a season ends, the player's
//  rank determines what bonus carries into the next season.
//

import Foundation
import SwiftData

enum SeasonManager {

    /// Process season end carryover. Call when season changes.
    @MainActor
    static func processSeasonEnd(
        endingSeason: Int,
        rank: String,
        user: User,
        in context: ModelContext
    ) {
        let nextSeason = endingSeason + 1

        // Check if already processed
        let desc = FetchDescriptor<SeasonCarryover>()
        let existing = (try? context.fetch(desc)) ?? []
        if existing.contains(where: { $0.fromSeason == endingSeason }) {
            return
        }

        switch rank {
        case "Legendary":
            let expiry = Calendar.current.date(byAdding: .day, value: 14, to: .now)
            let carry = SeasonCarryover(
                fromSeason: endingSeason, toSeason: nextSeason,
                rewardType: "legendary",
                xpMultiplier: 2.0, xpBonus: 0, expiryDate: expiry
            )
            context.insert(carry)
            BonusEngine.earnAchievement(key: "legendary_season", in: context)
            GameEventCenter.shared.fireBanner(
                title: "LEGENDARY REWARD",
                subtitle: "2x XP for first 2 weeks of Season \(nextSeason)",
                color: .gold
            )

        case "Diamond":
            let carry = SeasonCarryover(
                fromSeason: endingSeason, toSeason: nextSeason,
                rewardType: "diamond", xpBonus: 500
            )
            context.insert(carry)
            user.award(167, to: .fitness)
            user.award(167, to: .work)
            user.award(166, to: .learning)
            GameEventCenter.shared.fireBanner(
                title: "DIAMOND REWARD",
                subtitle: "+500 XP head start for Season \(nextSeason)",
                color: .green
            )

        case "Platinum":
            let carry = SeasonCarryover(
                fromSeason: endingSeason, toSeason: nextSeason,
                rewardType: "platinum", xpBonus: 200
            )
            context.insert(carry)
            user.award(67, to: .fitness)
            user.award(67, to: .work)
            user.award(66, to: .learning)

        case "Gold":
            let carry = SeasonCarryover(
                fromSeason: endingSeason, toSeason: nextSeason,
                rewardType: "gold", xpBonus: 100
            )
            context.insert(carry)
            user.award(34, to: .fitness)
            user.award(33, to: .work)
            user.award(33, to: .learning)

        default:
            break // Silver/Bronze — no carryover
        }

        try? context.save()
    }

    /// Returns the active season carryover, if any.
    static func activeCarryover(in context: ModelContext) -> SeasonCarryover? {
        let desc = FetchDescriptor<SeasonCarryover>()
        let all = (try? context.fetch(desc)) ?? []
        return all.first(where: { $0.isActive })
    }
}
