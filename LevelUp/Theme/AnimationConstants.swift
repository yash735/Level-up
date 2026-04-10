//
//  AnimationConstants.swift
//  LEVEL UP — Phase 3
//
//  Centralised animation timings & spring curves so every celebration,
//  button press, and transition in the app moves with the same rhythm.
//  Views should prefer these over inlining magic numbers.
//

import SwiftUI

enum AnimConst {

    // MARK: - Durations

    /// Quick feedback (button press, tap bounce).
    static let quick: Double = 0.18
    /// Most in-place state changes.
    static let standard: Double = 0.35
    /// Slower, more dramatic transitions.
    static let dramatic: Double = 0.65
    /// Floating XP gain number lifetime.
    static let xpGainLifetime: Double = 1.2
    /// How long a level-up overlay sits before auto-dismiss is allowed.
    static let levelUpHoldMin: Double = 1.8
    /// Banner (daily bonus, record) visible duration.
    static let bannerVisible: Double = 3.4

    // MARK: - Springs

    /// Snappy spring for cards, pills, and generic pop-ins.
    static let snappy = Animation.spring(response: 0.35, dampingFraction: 0.78)
    /// Heavier spring for full-screen overlays.
    static let dramaticSpring = Animation.spring(response: 0.55, dampingFraction: 0.72)
    /// Bouncier spring for "pop" moments (XP numbers, level badges).
    static let pop = Animation.spring(response: 0.4, dampingFraction: 0.55)
    /// Gentle ease for continuous loops (flame flicker, pulse).
    static let gentleLoop = Animation.easeInOut(duration: 1.1).repeatForever(autoreverses: true)

    // MARK: - Button / interactive

    /// Scale applied to a button while pressed.
    static let pressedScale: CGFloat = 0.96
    /// Scale applied to a card while hovered.
    static let hoverScale: CGFloat = 1.015

    // MARK: - Stagger

    /// Delay between list items animating in.
    static let listStagger: Double = 0.04
}
