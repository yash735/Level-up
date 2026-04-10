//
//  Theme.swift
//  LEVEL UP
//
//  Centralised design tokens. Any colour, corner radius, or spacing value
//  that gets reused should live here so the whole app moves in lockstep.
//  Vibe: Solo Leveling — dark, dramatic, electric.
//

import SwiftUI

enum Theme {

    // MARK: - Colours
    /// #0A0A0F — the base black-blue the whole app sits on.
    static let background       = Color(red: 0x0A / 255, green: 0x0A / 255, blue: 0x0F / 255)
    /// #13131F — card fill.
    static let cardBackground   = Color(red: 0x13 / 255, green: 0x13 / 255, blue: 0x1F / 255)
    /// #2A2A3F — subtle card stroke.
    static let cardBorder       = Color(red: 0x2A / 255, green: 0x2A / 255, blue: 0x3F / 255)

    /// #6C63FF — electric purple, primary hero accent.
    static let primaryAccent    = Color(red: 0x6C / 255, green: 0x63 / 255, blue: 0xFF / 255)
    /// #00D4FF — electric blue, secondary accent / work track.
    static let secondaryAccent  = Color(red: 0x00 / 255, green: 0xD4 / 255, blue: 0xFF / 255)
    /// #00FF88 — electric green, used for XP numbers and the fitness track.
    static let xpGreen          = Color(red: 0x00 / 255, green: 0xFF / 255, blue: 0x88 / 255)
    /// #FFD700 — legendary gold. Used on level-up overlays, milestone badges,
    /// personal records, and season rank accents.
    static let xpGold           = Color(red: 0xFF / 255, green: 0xD7 / 255, blue: 0x00 / 255)
    /// #FF6A3D — flame-orange, inner streak flame.
    static let flameHot         = Color(red: 0xFF / 255, green: 0x6A / 255, blue: 0x3D / 255)
    /// #FFB74D — flame-yellow, outer streak flame.
    static let flameWarm        = Color(red: 0xFF / 255, green: 0xB7 / 255, blue: 0x4D / 255)

    static let textPrimary      = Color.white
    /// #8888AA — muted labels.
    static let textSecondary    = Color(red: 0x88 / 255, green: 0x88 / 255, blue: 0xAA / 255)

    // MARK: - Geometry
    static let cornerRadius: CGFloat = 12
    static let cardPadding: CGFloat = 18

    // MARK: - Gradients
    static let heroGradient = LinearGradient(
        colors: [secondaryAccent, primaryAccent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Legendary gold → electric purple. Used for level-up overlays.
    static let levelUpGradient = LinearGradient(
        colors: [xpGold, primaryAccent],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Flame gradient for streak flames.
    static let flameGradient = LinearGradient(
        colors: [flameWarm, flameHot, .red],
        startPoint: .top,
        endPoint: .bottom
    )
}
