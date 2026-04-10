//
//  GameEventCenter.swift
//  LEVEL UP — Phase 3
//
//  Single @Observable event bus that every XP mutation, level up,
//  record, and daily login flows through. Views observe this singleton
//  and render the correct overlay / banner in response.
//
//  Why one bus:
//    - Ensures celebrations can never collide — everything serializes
//      through `pendingLevelUps` / `pendingRecords` FIFO queues.
//    - Lets any view fire an event without knowing which overlay will
//      handle it.
//    - Keeps the SwiftData writes and the UI reactions decoupled.
//

import Foundation
import SwiftUI

// MARK: - Track identifier

enum XPTrack: String, CaseIterable, Identifiable {
    case fitness, work, learning
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fitness:  return "Fitness"
        case .work:     return "Work"
        case .learning: return "Learning"
        }
    }

    var icon: String {
        switch self {
        case .fitness:  return "figure.run"
        case .work:     return "briefcase.fill"
        case .learning: return "book.fill"
        }
    }

    var color: Color {
        switch self {
        case .fitness:  return Theme.xpGreen
        case .work:     return Theme.secondaryAccent
        case .learning: return Theme.primaryAccent
        }
    }
}

// MARK: - Event payloads

/// Floating +XP number. Short-lived.
struct XPGainEvent: Identifiable, Equatable {
    let id = UUID()
    let amount: Int
    let track: XPTrack
    /// Seconds since reference date when this event was fired. Used
    /// by the overlay to time out old events if they pile up.
    let firedAt: Double
}

/// Triggered when a track's level increases.
struct LevelUpEvent: Identifiable, Equatable {
    let id = UUID()
    let track: XPTrack
    let newLevel: Int
    let oldLevel: Int
}

/// Personal record celebration.
struct RecordEvent: Identifiable, Equatable {
    let id = UUID()
    let track: XPTrack
    let title: String
    let value: String
}

/// Daily login bonus awarded banner.
struct DailyBonusEvent: Identifiable, Equatable {
    let id = UUID()
    let xp: Int
    let streakDays: Int
}

/// Perfect-week full-screen celebration.
struct PerfectWeekEvent: Identifiable, Equatable {
    let id = UUID()
    let xp: Int
}

// MARK: - The bus

@Observable
final class GameEventCenter {
    static let shared = GameEventCenter()

    // Queues for stacked / short-lived events.
    var xpGains: [XPGainEvent] = []

    // Serialized full-screen overlays — one at a time.
    var pendingLevelUps: [LevelUpEvent] = []
    var currentLevelUp: LevelUpEvent?

    var pendingPerfectWeeks: [PerfectWeekEvent] = []
    var currentPerfectWeek: PerfectWeekEvent?

    // Transient banners.
    var currentRecord: RecordEvent?
    var currentDailyBonus: DailyBonusEvent?

    private init() {}

    // MARK: Fire

    @MainActor
    func fireXPGain(amount: Int, track: XPTrack) {
        guard amount > 0 else { return }
        let event = XPGainEvent(amount: amount,
                                track: track,
                                firedAt: Date().timeIntervalSinceReferenceDate)
        xpGains.append(event)
        // Auto-prune after a beat so the array doesn't grow unbounded.
        let id = event.id
        DispatchQueue.main.asyncAfter(deadline: .now() + AnimConst.xpGainLifetime + 0.3) { [weak self] in
            self?.xpGains.removeAll { $0.id == id }
        }
    }

    @MainActor
    func fireLevelUp(track: XPTrack, oldLevel: Int, newLevel: Int) {
        guard newLevel > oldLevel else { return }
        let event = LevelUpEvent(track: track, newLevel: newLevel, oldLevel: oldLevel)
        pendingLevelUps.append(event)
        advanceLevelUpIfIdle()
    }

    @MainActor
    func fireRecord(track: XPTrack, title: String, value: String) {
        let event = RecordEvent(track: track, title: title, value: value)
        // If a banner is already on screen, overwrite — the most recent
        // PR wins. They're cosmetic, not celebration-critical.
        currentRecord = event
        DispatchQueue.main.asyncAfter(deadline: .now() + AnimConst.bannerVisible) { [weak self] in
            if self?.currentRecord?.id == event.id { self?.currentRecord = nil }
        }
    }

    @MainActor
    func fireDailyBonus(xp: Int, streakDays: Int) {
        let event = DailyBonusEvent(xp: xp, streakDays: streakDays)
        currentDailyBonus = event
        DispatchQueue.main.asyncAfter(deadline: .now() + AnimConst.bannerVisible + 0.5) { [weak self] in
            if self?.currentDailyBonus?.id == event.id { self?.currentDailyBonus = nil }
        }
    }

    @MainActor
    func firePerfectWeek(xp: Int) {
        let event = PerfectWeekEvent(xp: xp)
        pendingPerfectWeeks.append(event)
        advancePerfectWeekIfIdle()
    }

    // MARK: Dismiss

    @MainActor
    func dismissLevelUp() {
        currentLevelUp = nil
        advanceLevelUpIfIdle()
    }

    @MainActor
    func dismissPerfectWeek() {
        currentPerfectWeek = nil
        advancePerfectWeekIfIdle()
    }

    // MARK: Private

    @MainActor
    private func advanceLevelUpIfIdle() {
        guard currentLevelUp == nil, !pendingLevelUps.isEmpty else { return }
        currentLevelUp = pendingLevelUps.removeFirst()
    }

    @MainActor
    private func advancePerfectWeekIfIdle() {
        guard currentPerfectWeek == nil, !pendingPerfectWeeks.isEmpty else { return }
        currentPerfectWeek = pendingPerfectWeeks.removeFirst()
    }
}
