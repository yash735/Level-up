//
//  NotificationManager.swift
//  LEVEL UP — Phase 5
//
//  Handles all UNUserNotificationCenter scheduling — daily reminders,
//  streak alerts, challenge updates, level-up/unlock notifications.
//  Notification tone is casual and direct, like ARYA talking.
//

import Foundation
import UserNotifications
import SwiftData

@MainActor
final class NotificationManager: ObservableObject {

    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Schedule All Daily Notifications

    /// Reschedule all daily notifications. Call on app launch and after settings change.
    func rescheduleAll(container: ModelContainer) {
        center.removeAllPendingNotificationRequests()

        let ctx = ModelContext(container)
        let userDesc = FetchDescriptor<User>()
        guard let user = (try? ctx.fetch(userDesc))?.first else { return }

        let defaults = UserDefaults.standard

        // Guard: master toggle
        guard defaults.object(forKey: "notificationsEnabled") == nil
           || defaults.bool(forKey: "notificationsEnabled") else { return }

        // Morning reminder
        if defaults.object(forKey: "notifMorning") == nil || defaults.bool(forKey: "notifMorning") {
            let hour = defaults.integer(forKey: "notifMorningHour")
            let minute = defaults.integer(forKey: "notifMorningMinute")
            let h = hour > 0 ? hour : 7
            let m = minute >= 0 ? minute : 0
            let split = GymSplitEngine.plannedSplit(for: .now)
            let body = split == "Rest"
                ? "Good morning Yashodev — rest day. Recover hard."
                : "Good morning Yashodev — today is \(split) DAY. Let's get it."
            scheduleDailyNotification(
                id: "morning_reminder",
                title: "LEVEL UP",
                body: body,
                hour: h, minute: m
            )
        }

        // Evening reminder (no log)
        if defaults.object(forKey: "notifEvening") == nil || defaults.bool(forKey: "notifEvening") {
            let hour = defaults.integer(forKey: "notifEveningHour")
            let h = hour > 0 ? hour : 21
            scheduleDailyNotification(
                id: "evening_reminder",
                title: "LEVEL UP",
                body: "You haven't logged anything today Yash. Don't break the streak.",
                hour: h, minute: 0
            )
        }

        // Streak at risk (8 PM)
        if defaults.object(forKey: "notifStreak") == nil || defaults.bool(forKey: "notifStreak") {
            if user.currentStreak >= 3 {
                scheduleDailyNotification(
                    id: "streak_risk",
                    title: "STREAK AT RISK",
                    body: "Your \(user.currentStreak) day streak is at risk. Log something now.",
                    hour: 20, minute: 0
                )
            }
        }

        // Gym reminder
        if defaults.object(forKey: "notifGym") == nil || defaults.bool(forKey: "notifGym") {
            let hour = defaults.integer(forKey: "notifGymHour")
            let h = hour > 0 ? hour : 6
            let m = defaults.integer(forKey: "notifGymMinute")
            let split = GymSplitEngine.plannedSplit(for: .now)
            if split != "Rest" {
                scheduleDailyNotification(
                    id: "gym_reminder",
                    title: "GYM TIME",
                    body: "Time to hit the gym Yashodev — \(split) today.",
                    hour: h, minute: m > 0 ? m : 30
                )
            }
        }

        // Study reminder
        if defaults.object(forKey: "notifStudy") == nil || defaults.bool(forKey: "notifStudy") {
            let hour = defaults.integer(forKey: "notifStudyHour")
            let h = hour > 0 ? hour : 20
            scheduleDailyNotification(
                id: "study_reminder",
                title: "STUDY SESSION",
                body: "Study session time. What course are you on?",
                hour: h, minute: 0
            )
        }

        // Challenge notifications
        if defaults.object(forKey: "notifChallenge") == nil || defaults.bool(forKey: "notifChallenge") {
            scheduleWeeklyChallengeNotifications(in: ctx)
        }
    }

    // MARK: - Event-Driven Notifications

    /// Cancel the evening "no log" reminder for today (user logged something).
    func cancelEveningReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["evening_reminder"])
    }

    /// Fire an immediate notification for level-up.
    func notifyLevelUp(track: String, newLevel: Int) {
        guard UserDefaults.standard.object(forKey: "notifLevelUp") == nil
           || UserDefaults.standard.bool(forKey: "notifLevelUp") else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(track.uppercased()) LEVEL UP"
        content.body = "You are now Level \(newLevel) in \(track). Open LEVEL UP to see what's new."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "levelup_\(track)_\(newLevel)",
            content: content,
            trigger: nil // immediate
        )
        center.add(request)
    }

    /// Fire an immediate notification for unlock.
    func notifyUnlock(title: String) {
        guard UserDefaults.standard.object(forKey: "notifUnlock") == nil
           || UserDefaults.standard.bool(forKey: "notifUnlock") else { return }

        let content = UNMutableNotificationContent()
        content.title = "NEW UNLOCK"
        content.body = "\(title). Open LEVEL UP to claim it."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "unlock_\(UUID().uuidString.prefix(8))",
            content: content,
            trigger: nil
        )
        center.add(request)
    }

    /// Fire an immediate notification for challenge completion.
    func notifyChallengeComplete(title: String, xp: Int, tier: String) {
        guard UserDefaults.standard.object(forKey: "notifChallenge") == nil
           || UserDefaults.standard.bool(forKey: "notifChallenge") else { return }

        let content = UNMutableNotificationContent()
        content.title = "CHALLENGE COMPLETE"
        content.body = "+\(xp) XP earned. \(tier) difficulty beaten."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "challenge_complete_\(UUID().uuidString.prefix(8))",
            content: content,
            trigger: nil
        )
        center.add(request)
    }

    /// Notify streak milestone.
    func notifyStreakMilestone(days: Int) {
        guard UserDefaults.standard.object(forKey: "notifStreak") == nil
           || UserDefaults.standard.bool(forKey: "notifStreak") else { return }

        let content = UNMutableNotificationContent()
        content.title = "STREAK MILESTONE"
        content.body = "\(days) days in a row. You're on fire Yashodev."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "streak_milestone_\(days)",
            content: content,
            trigger: nil
        )
        center.add(request)
    }

    /// Launch notification shown when app starts from login item.
    func notifyLaunch() {
        guard UserDefaults.standard.object(forKey: "showLaunchNotification") == nil
           || UserDefaults.standard.bool(forKey: "showLaunchNotification") else { return }

        let split = GymSplitEngine.plannedSplit(for: .now)
        let dayText = split == "Rest" ? "rest" : split
        let content = UNMutableNotificationContent()
        content.title = "LEVEL UP"
        content.body = "LEVEL UP is running. Today is \(dayText) day."
        content.sound = nil

        let request = UNNotificationRequest(
            identifier: "launch_\(UUID().uuidString.prefix(8))",
            content: content,
            trigger: nil
        )
        center.add(request)
    }

    // MARK: - Private Helpers

    private func scheduleDailyNotification(id: String, title: String, body: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    private func scheduleWeeklyChallengeNotifications(in ctx: ModelContext) {
        let challDesc = FetchDescriptor<WeeklyChallenge>(
            sortBy: [SortDescriptor(\.weekStartDate, order: .reverse)]
        )
        let challenges = (try? ctx.fetch(challDesc)) ?? []
        guard let active = challenges.first(where: { !$0.isCompleted && !$0.isFailed }) else { return }

        // Monday 9 AM — new challenge
        let mondayContent = UNMutableNotificationContent()
        mondayContent.title = "NEW CHALLENGE"
        mondayContent.body = "New challenge dropped — \(active.title). \(active.xpReward) XP up for grabs this week."
        mondayContent.sound = .default

        var mondayComponents = DateComponents()
        mondayComponents.weekday = 2 // Monday
        mondayComponents.hour = 9
        let mondayTrigger = UNCalendarNotificationTrigger(dateMatching: mondayComponents, repeats: true)
        center.add(UNNotificationRequest(identifier: "challenge_monday", content: mondayContent, trigger: mondayTrigger))

        // Wednesday midweek check
        let wedContent = UNMutableNotificationContent()
        wedContent.title = "MIDWEEK CHECK"
        wedContent.body = "Halfway through the week — your challenge is \(Int(active.progress * 100))% done. Pick it up Boss."
        wedContent.sound = .default

        var wedComponents = DateComponents()
        wedComponents.weekday = 4 // Wednesday
        wedComponents.hour = 12
        let wedTrigger = UNCalendarNotificationTrigger(dateMatching: wedComponents, repeats: true)
        center.add(UNNotificationRequest(identifier: "challenge_wednesday", content: wedContent, trigger: wedTrigger))

        // Sunday 6 PM — final push
        let sunContent = UNMutableNotificationContent()
        sunContent.title = "FINAL PUSH"
        sunContent.body = "Final push — hours left to complete your \(active.tierLabel) challenge."
        sunContent.sound = .default

        var sunComponents = DateComponents()
        sunComponents.weekday = 1 // Sunday
        sunComponents.hour = 18
        let sunTrigger = UNCalendarNotificationTrigger(dateMatching: sunComponents, repeats: true)
        center.add(UNNotificationRequest(identifier: "challenge_sunday", content: sunContent, trigger: sunTrigger))
    }
}
