//
//  SettingsView.swift
//  LEVEL UP
//
//  Name editing, reset-all-data with confirmation, and the app version
//  block. Keeps a small footprint in Phase 1 — more options can hang off
//  this view as features land.
//

import SwiftUI
import SwiftData

struct SettingsView: View {

    let user: User

    @Environment(\.modelContext) private var context
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var name: String = ""
    @State private var showResetConfirm = false
    @State private var showSavedToast = false

    // Phase 5 — Notification settings
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("notifMorning") private var notifMorning = true
    @AppStorage("notifMorningHour") private var notifMorningHour = 7
    @AppStorage("notifEvening") private var notifEvening = true
    @AppStorage("notifEveningHour") private var notifEveningHour = 21
    @AppStorage("notifGym") private var notifGym = true
    @AppStorage("notifGymHour") private var notifGymHour = 6
    @AppStorage("notifStudy") private var notifStudy = true
    @AppStorage("notifStudyHour") private var notifStudyHour = 20
    @AppStorage("notifStreak") private var notifStreak = true
    @AppStorage("notifChallenge") private var notifChallenge = true
    @AppStorage("notifLevelUp") private var notifLevelUp = true
    @AppStorage("notifUnlock") private var notifUnlock = true

    // Phase 5 — Menu Bar settings
    @AppStorage("menuBarShowBadge") private var menuBarShowBadge = true
    @AppStorage("menuBarShowPulse") private var menuBarShowPulse = true
    @AppStorage("menuBarDefaultTab") private var menuBarDefaultTab = "fitness"

    // Phase 5 — Launch settings
    @AppStorage("launchAtLogin") private var launchAtLogin = true
    @AppStorage("openWindowAtLaunch") private var openWindowAtLaunch = false
    @AppStorage("showLaunchNotification") private var showLaunchNotification = true


    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                // Heading
                Text("SETTINGS")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .tracking(5)
                    .foregroundStyle(Theme.textPrimary)

                // MARK: Name
                Card {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("NAME")
                            .font(.caption).fontWeight(.heavy).tracking(2)
                            .foregroundStyle(Theme.textSecondary)

                        TextField("Your name", text: $name)
                            .textFieldStyle(.plain)
                            .font(.title3)
                            .foregroundStyle(Theme.textPrimary)
                            .padding(14)
                            .background(Theme.background)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Theme.cardBorder, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        HStack {
                            Button("Save Name", action: saveName)
                                .buttonStyle(.borderedProminent)
                                .tint(Theme.primaryAccent)
                                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                            if showSavedToast {
                                Text("Saved")
                                    .font(.caption).fontWeight(.semibold)
                                    .foregroundStyle(Theme.xpGreen)
                                    .transition(.opacity)
                            }
                        }
                    }
                    .padding(Theme.cardPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // MARK: Notifications
                Card {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("NOTIFICATIONS")
                            .font(.caption).fontWeight(.heavy).tracking(2)
                            .foregroundStyle(Theme.primaryAccent)

                        Toggle("Enable Notifications", isOn: $notificationsEnabled)
                            .tint(Theme.primaryAccent)
                            .onChange(of: notificationsEnabled) { rescheduleNotifications() }

                        if notificationsEnabled {
                            Divider().background(Theme.cardBorder)

                            settingsToggleWithTime("Morning Reminder", isOn: $notifMorning, hour: $notifMorningHour)
                            settingsToggleWithTime("Evening Reminder", isOn: $notifEvening, hour: $notifEveningHour)
                            settingsToggleWithTime("Gym Reminder", isOn: $notifGym, hour: $notifGymHour)
                            settingsToggleWithTime("Study Reminder", isOn: $notifStudy, hour: $notifStudyHour)

                            Divider().background(Theme.cardBorder)

                            Toggle("Streak Alerts", isOn: $notifStreak)
                                .tint(Theme.primaryAccent)
                            Toggle("Challenge Alerts", isOn: $notifChallenge)
                                .tint(Theme.primaryAccent)
                            Toggle("Level Up Alerts", isOn: $notifLevelUp)
                                .tint(Theme.primaryAccent)
                            Toggle("Unlock Alerts", isOn: $notifUnlock)
                                .tint(Theme.primaryAccent)
                        }
                    }
                    .padding(Theme.cardPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: notifMorning) { rescheduleNotifications() }
                    .onChange(of: notifEvening) { rescheduleNotifications() }
                    .onChange(of: notifGym) { rescheduleNotifications() }
                    .onChange(of: notifStudy) { rescheduleNotifications() }
                }

                // MARK: Menu Bar
                Card {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("MENU BAR")
                            .font(.caption).fontWeight(.heavy).tracking(2)
                            .foregroundStyle(Theme.secondaryAccent)

                        Toggle("Show Level Badge", isOn: $menuBarShowBadge)
                            .tint(Theme.secondaryAccent)
                        Toggle("Show XP Pulse Animation", isOn: $menuBarShowPulse)
                            .tint(Theme.secondaryAccent)

                        HStack {
                            Text("Default Quick Log Tab")
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Picker("", selection: $menuBarDefaultTab) {
                                Text("Fitness").tag("fitness")
                                Text("Work").tag("work")
                                Text("Learning").tag("learning")
                            }
                            .frame(width: 140)
                        }
                    }
                    .padding(Theme.cardPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // MARK: Launch
                Card {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("LAUNCH")
                            .font(.caption).fontWeight(.heavy).tracking(2)
                            .foregroundStyle(Theme.xpGreen)

                        Toggle("Launch at Login", isOn: $launchAtLogin)
                            .tint(Theme.xpGreen)
                            .onChange(of: launchAtLogin) {
                                LoginItemManager.setEnabled(launchAtLogin)
                            }
                        Toggle("Open Main Window at Launch", isOn: $openWindowAtLaunch)
                            .tint(Theme.xpGreen)
                        Toggle("Show Launch Notification", isOn: $showLaunchNotification)
                            .tint(Theme.xpGreen)
                    }
                    .padding(Theme.cardPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }


                // MARK: Danger zone
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("DANGER ZONE")
                            .font(.caption).fontWeight(.heavy).tracking(2)
                            .foregroundStyle(.red)
                        Text("Reset all data — wipes your user, XP, logs, and unlocks. Cannot be undone.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                        Button("Reset All Data", role: .destructive) {
                            showResetConfirm = true
                        }
                    }
                    .padding(Theme.cardPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // MARK: Debug tools (DEBUG builds only)
                #if DEBUG
                debugPanel
                #endif

                // MARK: About
                Card {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("VERSION")
                                .font(.caption).fontWeight(.heavy).tracking(2)
                                .foregroundStyle(Theme.textSecondary)
                            Text(appVersion)
                                .font(.subheadline)
                                .foregroundStyle(Theme.textPrimary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("OWNER")
                                .font(.caption).fontWeight(.heavy).tracking(2)
                                .foregroundStyle(Theme.textSecondary)
                            Text(user.name)
                                .font(.subheadline)
                                .foregroundStyle(Theme.textPrimary)
                        }
                    }
                    .padding(Theme.cardPadding)
                }
            }
            .padding(32)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.background.ignoresSafeArea())
        .onAppear { name = user.name }
        .alert("Reset all data?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive, action: resetAllData)
        } message: {
            Text("This will erase all XP, logs, and unlocks. You'll go back to the welcome screen.")
        }
    }

    // MARK: - Phase 5 Helpers

    private func settingsToggleWithTime(_ label: String, isOn: Binding<Bool>, hour: Binding<Int>) -> some View {
        HStack {
            Toggle(label, isOn: isOn)
                .tint(Theme.primaryAccent)
            if isOn.wrappedValue {
                Picker("", selection: hour) {
                    ForEach(0..<24, id: \.self) { h in
                        Text(String(format: "%02d:00", h)).tag(h)
                    }
                }
                .frame(width: 80)
            }
        }
    }


    private func rescheduleNotifications() {
        NotificationManager.shared.rescheduleAll(container: context.container)
    }

    // MARK: - Version

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }

    // MARK: - Actions

    private func saveName() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        user.name = trimmed
        try? context.save()
        withAnimation { showSavedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showSavedToast = false }
        }
    }

    private func resetAllData() {
        // Wipe every model type registered in the container.
        // Phase 1
        try? context.delete(model: User.self)
        try? context.delete(model: FitnessLog.self)
        try? context.delete(model: WorkLog.self)
        try? context.delete(model: LearningLog.self)
        try? context.delete(model: Unlock.self)
        // Phase 2 — Fitness
        try? context.delete(model: GymSession.self)
        try? context.delete(model: Exercise.self)
        try? context.delete(model: CardioSession.self)
        try? context.delete(model: FoodEntry.self)
        try? context.delete(model: WeightEntry.self)
        try? context.delete(model: HabitLog.self)
        try? context.delete(model: GymSplitState.self)
        // Phase 2 — Work
        try? context.delete(model: Deal.self)
        try? context.delete(model: ParaLAIMilestone.self)
        try? context.delete(model: ParaLAIEntry.self)
        // Phase 2 — Learning
        try? context.delete(model: Course.self)
        try? context.delete(model: Book.self)
        try? context.delete(model: Certification.self)
        // Phase 3 — Gamification
        try? context.delete(model: LoginStreak.self)
        try? context.delete(model: PersonalRecord.self)
        // Phase 4 — Stats & Analytics
        try? context.delete(model: OtherWorkLog.self)
        try? context.delete(model: WeeklyReport.self)
        // Phase 4.5 — Bonuses & Challenges
        try? context.delete(model: RankStreakState.self)
        try? context.delete(model: BalancedDayLog.self)
        try? context.delete(model: FounderWeekLog.self)
        try? context.delete(model: WeeklyChallenge.self)
        try? context.delete(model: BaselineStats.self)
        try? context.delete(model: SeasonCarryover.self)
        try? context.delete(model: Achievement.self)

        try? context.save()
        hasCompletedOnboarding = false
    }

    // MARK: - Debug Panel
    //
    // Visible only in DEBUG builds. Lets you jam XP into each track so you
    // can stress-test the dashboard, the level curve, and the unlock flow
    // without waiting for the Phase 2 logging screens.
    #if DEBUG
    @ViewBuilder
    private var debugPanel: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("DEBUG — STRESS TESTING")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.secondaryAccent)
                Text("These buttons only exist in debug builds. Use them to see how the dashboard looks with real XP before Phase 2 lands.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Per-track +500 row
                HStack(spacing: 10) {
                    debugButton("+500 Fitness", color: Theme.xpGreen) {
                        grantXP(500, toTrack: "fitness")
                    }
                    debugButton("+500 Work", color: Theme.secondaryAccent) {
                        grantXP(500, toTrack: "work")
                    }
                    debugButton("+500 Learning", color: Theme.primaryAccent) {
                        grantXP(500, toTrack: "learning")
                    }
                }

                // Big multi-grant + evaluate row
                HStack(spacing: 10) {
                    debugButton("+5,000 ALL", color: Theme.primaryAccent) {
                        grantXP(5_000, toTrack: "fitness")
                        grantXP(5_000, toTrack: "work")
                        grantXP(5_000, toTrack: "learning")
                    }
                    debugButton("Evaluate Unlocks", color: Theme.textSecondary) {
                        UnlockEngine.evaluateUnlocks(user: user, context: context)
                    }
                    debugButton("Clear All XP", color: .red) {
                        user.fitnessXP = 0
                        user.workXP = 0
                        user.learningXP = 0
                        try? context.save()
                    }
                }
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func debugButton(_ title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption).fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(color.opacity(0.5), lineWidth: 1)
                )
                .foregroundStyle(color)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    /// Grant XP to a specific track and evaluate unlocks in one shot.
    private func grantXP(_ amount: Int, toTrack track: String) {
        switch track {
        case "fitness":  user.award(amount, to: .fitness)
        case "work":     user.award(amount, to: .work)
        case "learning": user.award(amount, to: .learning)
        default: break
        }
        UnlockEngine.evaluateUnlocks(user: user, context: context)
        try? context.save()
    }
    #endif
}
