//
//  UnlockRow.swift
//  LEVEL UP
//
//  Single row in the "Recent Unlocks" list on the dashboard.
//

import SwiftUI

struct UnlockRow: View {

    let unlock: Unlock

    var body: some View {
        Card {
            HStack(spacing: 14) {
                Image(systemName: unlock.iconName)
                    .font(.title2)
                    .foregroundStyle(tint)
                    .frame(width: 48, height: 48)
                    .background(tint.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(unlock.title)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text(unlock.detail)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                if let date = unlock.unlockedAt {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption).monospacedDigit()
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(Theme.cardPadding)
        }
    }

    /// Colour-code the unlock by the track it belongs to.
    private var tint: Color {
        switch unlock.track {
        case "fitness":  return Theme.xpGreen
        case "work":     return Theme.secondaryAccent
        case "learning": return Theme.primaryAccent
        case "combined": return Theme.primaryAccent
        default:         return Theme.primaryAccent
        }
    }
}
