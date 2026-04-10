//
//  LevelUpApp.swift
//  LEVEL UP
//
//  App entry point. Wires up the SwiftData model container, the main window,
//  the Phase 5 menu bar item, and notification scheduling.
//

import SwiftUI
import SwiftData

@main
struct LevelUpApp: App {

    // MARK: - Persistent Container

    @NSApplicationDelegateAdaptor(LevelUpAppDelegate.self) var appDelegate

    let container: ModelContainer

    /// Phase 5: Menu bar manager lives for the app's lifetime.
    @State private var menuBarManager: MenuBarManager?

    private static let allModelTypes: [any PersistentModel.Type] = [
        User.self,
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
        PersonalRecord.self,
        // Phase 4 — Stats & Analytics
        OtherWorkLog.self,
        WeeklyReport.self,
        // Phase 4.5 — Bonuses & Challenges
        RankStreakState.self,
        BalancedDayLog.self,
        FounderWeekLog.self,
        WeeklyChallenge.self,
        BaselineStats.self,
        SeasonCarryover.self,
        Achievement.self
    ]

    init() {
        do {
            let schema = Schema(Self.allModelTypes)
            container = try ModelContainer(for: schema)
        } catch {
            let storeURL = URL.applicationSupportDirectory
                .appending(path: "default.store")
            for ext in ["", "-wal", "-shm"] {
                try? FileManager.default.removeItem(
                    at: storeURL.deletingLastPathComponent()
                        .appending(path: storeURL.lastPathComponent + ext)
                )
            }
            do {
                let schema = Schema(Self.allModelTypes)
                container = try ModelContainer(for: schema)
            } catch {
                fatalError("LEVEL UP: failed to create ModelContainer — \(error)")
            }
        }
    }

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                XPGainOverlay()
                BannerOverlay()
                PerfectWeekOverlay()
                LevelUpOverlay()
                UnlockCelebrationView()
                WeeklyReportRoot()
            }
            .environment(UnlockCenter.shared)
            .environment(GameEventCenter.shared)
            .preferredColorScheme(.dark)
            .tint(Theme.primaryAccent)
            .onAppear {
                setupPhase5()
            }
        }
        .modelContainer(container)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1280, height: 840)
        .commands {
            // CMD+Q actually quits (overriding default close behavior)
            CommandGroup(replacing: .appTermination) {
                Button("Quit LEVEL UP") {
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q")
            }
        }
    }

    // MARK: - Phase 5 Setup

    @MainActor
    private func setupPhase5() {
        // Menu bar manager — create once
        if menuBarManager == nil {
            menuBarManager = MenuBarManager(container: container)
        }

        // Keep app running when last window closes (lives in menu bar)
        NSApp.setActivationPolicy(.regular)

        // Notifications — request permission and schedule
        Task {
            await NotificationManager.shared.requestPermission()
            NotificationManager.shared.rescheduleAll(container: container)
        }

        // Launch at login — default ON on first run
        if UserDefaults.standard.object(forKey: "launchAtLoginSet") == nil {
            UserDefaults.standard.set(true, forKey: "launchAtLoginSet")
            LoginItemManager.setEnabled(true)
        }

        // Launch notification if started from login item
        if UserDefaults.standard.object(forKey: "showLaunchNotification") == nil
            || UserDefaults.standard.bool(forKey: "showLaunchNotification") {
            // Only fire if we're launching fresh (not from user clicking)
            if !NSApp.isActive {
                NotificationManager.shared.notifyLaunch()
            }
        }
    }
}

// MARK: - App Delegate for window management

/// Keeps the app alive when the last window is closed.
/// The menu bar icon stays active.
final class LevelUpAppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false // Keep running in menu bar
    }
}
