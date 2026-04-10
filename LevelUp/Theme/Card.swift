//
//  Card.swift
//  LEVEL UP
//
//  Reusable container chrome: the dark "card" look and its matching
//  section header. Kept in the Theme folder because these are purely
//  presentational building blocks, not features.
//

import SwiftUI

/// A dark rounded card with a subtle stroke. Wrap any content in this
/// for consistent chrome across the dashboard.
struct Card<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .stroke(Theme.cardBorder, lineWidth: 1)
            )
    }
}

/// The small uppercase label used above every dashboard section.
struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.caption)
            .fontWeight(.heavy)
            .tracking(3)
            .foregroundStyle(Theme.textSecondary)
    }
}

/// A thin animated progress bar used inside XP track cards.
struct ProgressBar: View {
    let progress: Double       // 0.0 ... 1.0
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Theme.background)
                    .frame(height: 10)

                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.65), color],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: max(0, min(1, progress)) * geo.size.width,
                        height: 10
                    )
                    .shadow(color: color.opacity(0.6), radius: 4, y: 0)
                    .animation(.easeInOut(duration: 0.4), value: progress)
            }
        }
        .frame(height: 10)
    }
}
