//
//  LevelUpApp.swift
//  LEVEL UP
//
//  App entry point. Wires up the SwiftData model container and kicks off
//  the RootView which decides between the welcome flow and the main UI.
//

import SwiftUI
import SwiftData

@main
struct LevelUpApp: App {

    // MARK: - Persistent Container
    //
    // SwiftData holds every model in a single container. When this list grows
    // in Phase 2 (e.g. new log types), add them here.
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: User.self,
                FitnessLog.self,
                WorkLog.self,
                LearningLog.self,
                Unlock.self,
                // Phase 2 — Fitness
                GymSession.self,
                Exercise.self,
                CardioSession.self,
                FoodEntry.self,
                WeightEntry.self,
                HabitLog.self,
                GymSplitState.self,
                // Phase 2 — Work
                Deal.self,
                ParaLAIMilestone.self,
                ParaLAIEntry.self,
                // Phase 2 — Learning
                Course.self,
                Book.self,
                Certification.self,
                // Phase 3 — Gamification
                LoginStreak.self,
                PersonalRecord.self
            )
        } catch {
            fatalError("LEVEL UP: failed to create ModelContainer — \(error)")
        }
    }

    // MARK: - Scene
    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                // Phase 3 overlays — stacked in z-order.
                // Floating XP numbers sit at the bottom of the overlay
                // stack so level-up / unlock celebrations render above.
                XPGainOverlay()
                BannerOverlay()
                PerfectWeekOverlay()
                LevelUpOverlay()
                UnlockCelebrationView()
            }
            .environment(UnlockCenter.shared)
            .environment(GameEventCenter.shared)
            .preferredColorScheme(.dark)
            .tint(Theme.primaryAccent)
        }
        .modelContainer(container)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1280, height: 840)
    }
}
