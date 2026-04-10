//
//  MainNavigationView.swift
//  LEVEL UP
//
//  Sidebar shell: Dashboard / Fitness / Work / Learning / Settings.
//  Keeps the current selection in @State and swaps the detail pane
//  accordingly.
//

import SwiftUI
import SwiftData

// MARK: - Sidebar Items

enum SidebarItem: String, CaseIterable, Identifiable {
    case dashboard, fitness, work, learning, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .fitness:   return "Fitness"
        case .work:      return "Work"
        case .learning:  return "Learning"
        case .settings:  return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .fitness:   return "figure.run"
        case .work:      return "briefcase.fill"
        case .learning:  return "book.fill"
        case .settings:  return "gearshape.fill"
        }
    }

    var tint: Color {
        switch self {
        case .dashboard: return Theme.primaryAccent
        case .fitness:   return Theme.xpGreen
        case .work:      return Theme.secondaryAccent
        case .learning:  return Theme.primaryAccent
        case .settings:  return Theme.textSecondary
        }
    }
}

// MARK: - View

struct MainNavigationView: View {
    let user: User
    @State private var selection: SidebarItem? = .dashboard

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
                .background(Theme.background.ignoresSafeArea())
        }
        .navigationSplitViewStyle(.balanced)
    }

    // MARK: Sidebar

    private var sidebar: some View {
        List(SidebarItem.allCases, selection: $selection) { item in
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .font(.body)
                    .foregroundStyle(item.tint)
                    .frame(width: 22)
                Text(item.title)
                    .font(.body)
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(.vertical, 4)
            .tag(item)
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("LEVEL UP")
        .frame(minWidth: 220)
    }

    // MARK: Detail

    @ViewBuilder
    private var detail: some View {
        switch selection ?? .dashboard {
        case .dashboard: DashboardView(user: user, navigationSelection: $selection)
        case .fitness:   FitnessView(user: user)
        case .work:      WorkView(user: user)
        case .learning:  LearningView(user: user)
        case .settings:  SettingsView(user: user)
        }
    }
}
