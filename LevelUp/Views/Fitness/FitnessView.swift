//
//  FitnessView.swift
//  LEVEL UP — Phase 2
//
//  Container for the Fitness track. Owns the internal tab selection
//  and passes the shared view-model down to the active tab.
//

import SwiftUI
import SwiftData

struct FitnessView: View {

    let user: User

    // All track data is @Query'd here and funneled into FitnessViewModel
    // so the individual tabs stay thin.
    @Query(sort: \GymSession.date, order: .reverse)
    private var gymSessions: [GymSession]

    @Query(sort: \CardioSession.date, order: .reverse)
    private var cardioSessions: [CardioSession]

    @Query(sort: \FoodEntry.date, order: .reverse)
    private var foodEntries: [FoodEntry]

    @Query(sort: \WeightEntry.date, order: .reverse)
    private var weightEntries: [WeightEntry]

    @Query(sort: \HabitLog.date, order: .reverse)
    private var habitLogs: [HabitLog]

    enum Tab: String, CaseIterable, Identifiable {
        case workout, food, weight, habits
        var id: String { rawValue }
        var title: String {
            switch self {
            case .workout: return "WORKOUT"
            case .food:    return "FOOD"
            case .weight:  return "WEIGHT"
            case .habits:  return "HABITS"
            }
        }
        var icon: String {
            switch self {
            case .workout: return "figure.strengthtraining.traditional"
            case .food:    return "fork.knife"
            case .weight:  return "scalemass.fill"
            case .habits:  return "checklist"
            }
        }
    }

    @State private var selection: Tab = .workout

    private var vm: FitnessViewModel {
        FitnessViewModel(gymSessions: gymSessions,
                         cardioSessions: cardioSessions,
                         foodEntries: foodEntries,
                         weightEntries: weightEntries,
                         habitLogs: habitLogs)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                InternalTabBar(tabs: Tab.allCases,
                               selection: $selection,
                               title: { $0.title },
                               icon: { $0.icon },
                               tint: Theme.xpGreen)

                Group {
                    switch selection {
                    case .workout: WorkoutTabView(user: user, vm: vm)
                    case .food:    FoodTabView(user: user, vm: vm)
                    case .weight:  WeightTabView(user: user, vm: vm)
                    case .habits:  HabitsTabView(user: user, vm: vm)
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
            Text("FITNESS")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .tracking(5)
                .foregroundStyle(Theme.xpGreen)
                .shadow(color: Theme.xpGreen.opacity(0.35), radius: 16, y: 2)
            HStack(spacing: 12) {
                Text("Level \(user.fitnessLevel)")
                    .font(.subheadline).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textPrimary)
                Text("·")
                    .foregroundStyle(Theme.textSecondary)
                Text("\(user.fitnessXP.formatted()) XP")
                    .font(.subheadline).monospacedDigit().fontWeight(.heavy)
                    .foregroundStyle(Theme.xpGreen)
            }
        }
    }
}
