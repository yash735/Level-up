//
//  ConfettiView.swift
//  LEVEL UP — Phase 2
//
//  Lightweight particle burst driven by TimelineView. No external
//  dependencies. Each particle is a colored rounded rectangle that
//  falls under gravity with a randomised drift and rotation.
//
//  Used as a background layer inside UnlockCelebrationView.
//

import SwiftUI

struct ConfettiView: View {

    private struct Particle: Identifiable {
        let id = UUID()
        let xFraction: Double        // 0...1 of width
        let delay: Double            // seconds before launch
        let drift: Double            // horizontal drift, px
        let hue: Double              // 0...1
        let spin: Double             // degrees / sec
        let size: CGFloat
        let duration: Double
    }

    private let particles: [Particle] = {
        (0..<80).map { _ in
            Particle(
                xFraction: .random(in: 0...1),
                delay: .random(in: 0...0.6),
                drift: .random(in: -60...60),
                hue: .random(in: 0...1),
                spin: .random(in: -240...240),
                size: .random(in: 6...12),
                duration: .random(in: 1.8...3.0)
            )
        }
    }()

    private let start = Date()

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSince(start)
                Canvas { ctx, size in
                    for p in particles {
                        let local = max(0, t - p.delay)
                        guard local <= p.duration else { continue }
                        let progress = local / p.duration
                        let x = p.xFraction * size.width + p.drift * progress
                        // gravity-ish curve
                        let y = -40 + (size.height + 80) * pow(progress, 1.4)
                        let angle = Angle.degrees(p.spin * local)

                        let shape = Path(roundedRect:
                            CGRect(x: -p.size/2, y: -p.size/2,
                                   width: p.size, height: p.size * 0.45),
                            cornerRadius: 1.5)

                        var transform = ctx
                        transform.translateBy(x: x, y: y)
                        transform.rotate(by: angle)
                        let color = Color(hue: p.hue, saturation: 0.85, brightness: 1.0)
                            .opacity(1 - progress * 0.6)
                        transform.fill(shape, with: .color(color))
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .allowsHitTesting(false)
    }
}
