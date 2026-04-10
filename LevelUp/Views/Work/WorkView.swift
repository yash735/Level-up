//
//  WorkView.swift
//  LEVEL UP — Phase 2
//
//  Container for the Work track. Two tabs: ParaLAI and BVA.
//

import SwiftUI
import SwiftData

struct WorkView: View {

    let user: User

    @Query(sort: \Deal.updatedAt, order: .reverse)
    private var deals: [Deal]

    @Query(sort: \ParaLAIMilestone.orderIndex)
    private var milestones: [ParaLAIMilestone]

    @Query(sort: \ParaLAIEntry.date, order: .reverse)
    private var entries: [ParaLAIEntry]

    enum Tab: String, CaseIterable, Identifiable {
        case paralai, bva
        var id: String { rawValue }
        var title: String {
            switch self {
            case .paralai: return "PARALAI"
            case .bva:     return "BVA"
            }
        }
        var icon: String {
            switch self {
            case .paralai: return "shippingbox.fill"
            case .bva:     return "building.columns.fill"
            }
        }
    }

    @State private var selection: Tab = .paralai

    private var vm: WorkViewModel {
        WorkViewModel(deals: deals, milestones: milestones, entries: entries)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                InternalTabBar(tabs: Tab.allCases,
                               selection: $selection,
                               title: { $0.title },
                               icon: { $0.icon },
                               tint: Theme.secondaryAccent)

                Group {
                    switch selection {
                    case .paralai: ParaLAITabView(user: user, vm: vm)
                    case .bva:     BVATabView(user: user, vm: vm)
                    }
                }
            }
            .padding(32)
            .frame(maxWidth: 1100, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.background.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("WORK")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .tracking(5)
                .foregroundStyle(Theme.secondaryAccent)
                .shadow(color: Theme.secondaryAccent.opacity(0.35), radius: 16, y: 2)
            HStack(spacing: 12) {
                Text("Level \(user.workLevel)")
                    .font(.subheadline).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textPrimary)
                Text("·").foregroundStyle(Theme.textSecondary)
                Text("\(user.workXP.formatted()) XP")
                    .font(.subheadline).monospacedDigit().fontWeight(.heavy)
                    .foregroundStyle(Theme.secondaryAccent)
            }
        }
    }
}
