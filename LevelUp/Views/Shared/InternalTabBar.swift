//
//  InternalTabBar.swift
//  LEVEL UP — Phase 2
//
//  Pill-style segmented tab bar used inside track screens
//  (Fitness, Work, Learning). Not to be confused with the sidebar —
//  this picks between the sub-tabs of a single track.
//

import SwiftUI

struct InternalTabBar<Tab: Hashable & Identifiable>: View {

    let tabs: [Tab]
    @Binding var selection: Tab
    let title: (Tab) -> String
    let icon: (Tab) -> String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            ForEach(tabs) { tab in
                let isSelected = tab == selection
                Button {
                    withAnimation(.easeOut(duration: 0.15)) { selection = tab }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: icon(tab))
                            .font(.caption)
                        Text(title(tab))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .tracking(1)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .foregroundStyle(isSelected ? tint : Theme.textSecondary)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isSelected ? tint.opacity(0.14) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isSelected ? tint.opacity(0.55) : Theme.cardBorder,
                                    lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
    }
}
