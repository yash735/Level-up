//
//  XPTrackCard.swift
//  LEVEL UP
//
//  One of the three big track cards on the dashboard: Fitness, Work,
//  Learning. Shows the current level, a gradient progress bar, and the
//  exact XP needed to hit the next level.
//

import SwiftUI

struct XPTrackCard: View {

    /// One compact metric rendered in the densified footer row.
    /// `tint` lets the caller highlight e.g. overdue counts in red.
    struct Metric: Identifiable {
        let id = UUID()
        let label: String
        let value: String
        var tint: Color? = nil
    }

    let title: String
    let icon: String
    let color: Color
    let level: Int
    let xp: Int
    var metrics: [Metric] = []

    // Derived from XPEngine so all maths flow from one place.
    private var progress: Double     { XPEngine.progressToNextLevel(currentXP: xp) }
    private var nextLevelXP: Int     { XPEngine.xpForNextLevel(currentXP: xp) }
    private var xpToNext: Int        { XPEngine.xpRemainingToNextLevel(currentXP: xp) }
    private var atMaxLevel: Bool     { level >= XPEngine.maxLevel }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {

                // Header row
                HStack(alignment: .top) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                        .frame(width: 44, height: 44)
                        .background(color.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("LEVEL")
                            .font(.caption2).fontWeight(.heavy).tracking(2)
                            .foregroundStyle(Theme.textSecondary)
                        Text("\(level)")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                    }
                }

                Text(title.uppercased())
                    .font(.caption).fontWeight(.heavy).tracking(3)
                    .foregroundStyle(color)

                ProgressBar(progress: progress, color: color)

                HStack {
                    Text("\(xp.formatted()) / \(nextLevelXP.formatted()) XP")
                        .font(.caption).monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    if atMaxLevel {
                        Text("MAX")
                            .font(.caption).fontWeight(.heavy)
                            .foregroundStyle(Theme.xpGreen)
                    } else {
                        Text("\(xpToNext.formatted()) to next")
                            .font(.caption).monospacedDigit()
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                // Densified footer row: 3 compact (value, label) columns
                // showing live per-track state. Hidden when no metrics
                // are supplied so the card stays backwards-compatible.
                if !metrics.isEmpty {
                    Divider().background(Theme.cardBorder)
                    HStack(spacing: 0) {
                        ForEach(metrics) { metric in
                            VStack(spacing: 3) {
                                Text(metric.value)
                                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                                    .foregroundStyle(metric.tint ?? Theme.textPrimary)
                                    .monospacedDigit()
                                Text(metric.label)
                                    .font(.caption2).fontWeight(.heavy).tracking(1)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
