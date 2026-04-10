//
//  StreakFlameView.swift
//  LEVEL UP — Phase 3
//
//  Canvas-driven animated flame for the dashboard streak display.
//  Pure SwiftUI, no external assets — the flame is built from layered
//  blurred ellipses with a TimelineView flicker.
//
//  `intensity` (0...1) controls the flame's height and glow reach:
//    0.25 — single day (ember)
//    0.55 — week streak
//    0.85 — month streak
//    1.00 — 90+ day legendary
//

import SwiftUI

struct StreakFlameView: View {
    let days: Int
    var size: CGFloat = 64

    /// 0...1 intensity curve — slow ramp early, saturates around 90 days.
    private var intensity: Double {
        let raw = Double(max(0, days)) / 90.0
        return min(1.0, 0.25 + raw * 0.9)
    }

    private let start = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSince(start)
            Canvas { ctx, canvasSize in
                drawFlame(ctx: ctx, size: canvasSize, time: t)
            }
        }
        .frame(width: size, height: size * 1.35)
        .allowsHitTesting(false)
    }

    private func drawFlame(ctx: GraphicsContext, size: CGSize, time: Double) {
        let cx = size.width / 2
        let baseY = size.height * 0.9

        // Flicker wiggle.
        let wobble = sin(time * 6.2) * 2.5 + sin(time * 3.1 + 1.2) * 1.5
        let heightMul = 1.0 + (sin(time * 5.0) * 0.07)
        let flameHeight = size.height * 0.82 * heightMul * CGFloat(intensity)

        // Outer warm halo.
        var outer = ctx
        outer.addFilter(.blur(radius: 14))
        let outerRect = CGRect(
            x: cx - size.width * 0.42,
            y: baseY - flameHeight * 1.05,
            width: size.width * 0.84,
            height: flameHeight * 1.2
        ).offsetBy(dx: wobble * 0.3, dy: 0)
        outer.fill(
            Path(ellipseIn: outerRect),
            with: .color(Theme.flameWarm.opacity(0.55 * intensity))
        )

        // Mid flame body.
        var mid = ctx
        mid.addFilter(.blur(radius: 7))
        let midRect = CGRect(
            x: cx - size.width * 0.30,
            y: baseY - flameHeight * 0.92,
            width: size.width * 0.60,
            height: flameHeight * 1.05
        ).offsetBy(dx: wobble * 0.6, dy: 0)
        mid.fill(
            Path(ellipseIn: midRect),
            with: .color(Theme.flameHot.opacity(0.9))
        )

        // Inner bright core.
        var core = ctx
        core.addFilter(.blur(radius: 3))
        let coreRect = CGRect(
            x: cx - size.width * 0.18,
            y: baseY - flameHeight * 0.65,
            width: size.width * 0.36,
            height: flameHeight * 0.78
        ).offsetBy(dx: wobble, dy: 2)
        core.fill(
            Path(ellipseIn: coreRect),
            with: .color(Color(red: 1, green: 0.92, blue: 0.55).opacity(0.95))
        )

        // Tiny sparks.
        for i in 0..<4 {
            let seed = Double(i) * 1.37 + time * 0.9
            let sparkProg = (sin(seed) + 1) / 2 // 0...1
            let sparkX = cx + CGFloat(sin(seed * 1.7) * 14)
            let sparkY = baseY - flameHeight * CGFloat(1.0 + sparkProg * 0.2)
            let sparkSize: CGFloat = 2.4
            var sp = ctx
            sp.addFilter(.blur(radius: 1.2))
            sp.fill(
                Path(ellipseIn: CGRect(x: sparkX - sparkSize/2,
                                        y: sparkY - sparkSize/2,
                                        width: sparkSize,
                                        height: sparkSize)),
                with: .color(Theme.xpGold.opacity(0.85))
            )
        }
    }
}

// MARK: - Compact streak badge

/// Combined flame + day count used on the dashboard.
struct StreakBadge: View {
    let days: Int

    var body: some View {
        VStack(spacing: 2) {
            StreakFlameView(days: days, size: 56)
            Text("\(days)")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
            Text("DAY STREAK")
                .font(.caption2).fontWeight(.heavy).tracking(2)
                .foregroundStyle(Theme.textSecondary)
        }
    }
}
