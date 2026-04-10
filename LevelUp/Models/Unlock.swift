//
//  Unlock.swift
//  LEVEL UP
//
//  One reward/badge/title record. Seeded on first launch by UnlockEngine
//  and then flipped `isUnlocked = true` the moment the user qualifies.
//

import Foundation
import SwiftData

@Model
final class Unlock {
    var id: UUID
    /// "fitness", "work", "learning", or "combined".
    var track: String
    var title: String
    /// Short description / flavour text shown under the title.
    var detail: String
    /// Mirrored from levelRequired via XPEngine for fast lookups.
    var xpRequired: Int
    var levelRequired: Int
    var isUnlocked: Bool
    var unlockedAt: Date?
    /// SF Symbol name.
    var iconName: String

    init(track: String,
         title: String,
         detail: String,
         levelRequired: Int,
         iconName: String) {
        self.id = UUID()
        self.track = track
        self.title = title
        self.detail = detail
        self.levelRequired = levelRequired
        self.xpRequired = XPEngine.xpForLevel(levelRequired)
        self.isUnlocked = false
        self.unlockedAt = nil
        self.iconName = iconName
    }
}
