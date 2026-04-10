//
//  PlaceholderView.swift
//  LEVEL UP
//
//  "Coming in Phase 2" placeholder shown for the Fitness / Work / Learning
//  sidebar items. Uses the matching track colour so each one still feels
//  like its own space.
//

import SwiftUI

enum TrackType {
    case fitness, work, learning

    var title: String {
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

    var tagline: String {
        switch self {
        case .fitness:  return "Workouts, nutrition, habits, streaks."
        case .work:     return "ParaLAI + BVA deal flow. Ship and close."
        case .learning: return "Study hours, books, courses, certifications."
        }
    }
}

struct PlaceholderView: View {
    let track: TrackType

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: track.icon)
                .font(.system(size: 96))
                .foregroundStyle(track.color)
                .frame(width: 180, height: 180)
                .background(track.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(track.color.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: track.color.opacity(0.4), radius: 24, y: 6)

            Text(track.title.uppercased())
                .font(.system(size: 52, weight: .black, design: .rounded))
                .tracking(5)
                .foregroundStyle(Theme.textPrimary)

            Text(track.tagline)
                .font(.title3)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)

            Text("Coming in Phase 2")
                .font(.headline)
                .tracking(2)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(track.color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(track.color.opacity(0.5), lineWidth: 1)
                )
                .foregroundStyle(track.color)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
        .background(Theme.background)
    }
}
