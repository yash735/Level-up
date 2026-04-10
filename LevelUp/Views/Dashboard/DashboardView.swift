//
//  DashboardView.swift
//  LEVEL UP
//
//  The home screen of Phase 1. Scrollable character-sheet layout:
//  logo → total-level badge → 3 track cards → recent unlocks →
//  next unlocks → today summary with Phase-2 placeholder actions.
//

import SwiftUI
import SwiftData

struct DashboardView: View {

    let user: User
    @Binding var navigationSelection: SidebarItem?

    @Environment(\.modelContext) private var context
    @Query private var unlocks: [Unlock]
    @Query(sort: \PersonalRecord.date, order: .reverse) private var records: [PersonalRecord]

    // Minimum per-track data needed to drive the densified track-card
    // metrics. We skip CardioSession and HabitLog since the dashboard
    // doesn't surface cardio/habit totals today.
    @Query(sort: \GymSession.date, order: .reverse) private var gymSessions: [GymSession]
    @Query(sort: \FoodEntry.date, order: .reverse) private var foodEntries: [FoodEntry]
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    @Query private var deals: [Deal]
    @Query private var milestones: [ParaLAIMilestone]
    @Query private var paralaiEntries: [ParaLAIEntry]
    @Query private var courses: [Course]
    @Query private var books: [Book]
    @Query private var certifications: [Certification]
    @Query(sort: \LearningLog.date, order: .reverse) private var learningLogs: [LearningLog]
    @Query(sort: \WeeklyChallenge.weekStartDate, order: .reverse) private var allChallenges: [WeeklyChallenge]

    @AppStorage("weeklyStudyHoursTarget") private var weeklyStudyHoursTarget = 10
    @Query private var achievements: [Achievement]

    // Rebuilt on every render — value-type VM stays in sync with @Query.
    private var vm: DashboardViewModel {
        DashboardViewModel(user: user, unlocks: unlocks)
    }

    // Per-track VMs, rebuilt per render. Unused inputs (cardio, habits)
    // are passed as empty arrays since the dashboard doesn't read them.
    private var fitnessVM: FitnessViewModel {
        FitnessViewModel(gymSessions: gymSessions,
                         cardioSessions: [],
                         foodEntries: foodEntries,
                         weightEntries: weightEntries,
                         habitLogs: [])
    }

    private var workVM: WorkViewModel {
        WorkViewModel(deals: deals, milestones: milestones, entries: paralaiEntries)
    }

    private var learningVM: LearningViewModel {
        LearningViewModel(courses: courses, books: books, certifications: certifications)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                header
                multiplierBadge
                heroRow
                trackCards
                activeChallengesSection
                phase45StatusRow
                recordsSection
                recentUnlocksSection
                nextUnlocksSection
                todaySummarySection
            }
            .padding(32)
            .frame(maxWidth: 1100, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.background.ignoresSafeArea())
        .onAppear {
            // Defensive: if the unlock catalog is ever empty (e.g. after a
            // reset that skipped reseeding), seed it now.
            if unlocks.isEmpty {
                UnlockEngine.seedUnlocks(into: context)
                try? context.save()
            }
            // Keep unlocks in sync with current XP whenever the dashboard
            // appears. Idempotent — no-ops if nothing is newly earned.
            UnlockEngine.evaluateUnlocks(user: user, context: context)

            // Phase 3: award the daily login bonus (idempotent — only
            // fires once per calendar day).
            LoginStreakEngine.awardIfNeeded(user: user, in: context)

            // Phase 4.5: seed achievements, check balanced day, update challenges
            BonusEngine.seedAchievements(into: context)
            BonusEngine.checkBalancedDay(user: user, in: context)
            ChallengeManager.updateProgress(user: user, in: context)

            // Sync active multiplier to user
            let mult = BonusEngine.activeMultiplier(in: context)
            if user.resolvedMultiplier != mult {
                user.resolvedMultiplier = mult
                try? context.save()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LEVEL UP")
                .font(.system(size: 64, weight: .black, design: .rounded))
                .tracking(5)
                .foregroundStyle(Theme.heroGradient)
                .shadow(color: Theme.primaryAccent.opacity(0.35), radius: 20, y: 4)

            Text("\(greeting), \(user.name)")
                .font(.title2).fontWeight(.semibold)
                .foregroundStyle(Theme.textPrimary)

            Text(Date.now.formatted(date: .complete, time: .omitted))
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default:      return "Burning the midnight oil"
        }
    }

    // MARK: - Hero row (Total level badge + streak flame)

    private var heroRow: some View {
        HStack(spacing: 32) {
            Spacer()
            totalLevelBadge
            Spacer()
            StreakBadge(days: user.currentStreak)
                .frame(width: 120)
            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var totalLevelBadge: some View {
        VStack(spacing: 14) {
            Text("TOTAL LEVEL")
                .font(.caption).fontWeight(.heavy).tracking(3)
                .foregroundStyle(Theme.textSecondary)

            ZStack {
                Circle()
                    .fill(Theme.cardBackground)
                    .frame(width: 180, height: 180)
                Circle()
                    .stroke(Theme.heroGradient, lineWidth: 5)
                    .frame(width: 180, height: 180)
                    .shadow(color: Theme.primaryAccent.opacity(0.5), radius: 16)
                Text("\(user.totalLevel)")
                    .font(.system(size: 84, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
            }

            Text("\(user.totalXP.formatted()) TOTAL XP")
                .font(.subheadline).monospacedDigit().fontWeight(.heavy).tracking(2)
                .foregroundStyle(Theme.xpGreen)
        }
    }

    // MARK: - XP Multiplier Badge

    @ViewBuilder
    private var multiplierBadge: some View {
        if user.resolvedMultiplier > 1.0 {
            let days = BonusEngine.multiplierDaysRemaining(in: context)
            HStack(spacing: 12) {
                Image(systemName: "bolt.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.xpGold)
                Text("\(String(format: "%.0f", user.resolvedMultiplier))x XP ACTIVE")
                    .font(.subheadline).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.xpGold)
                if days > 0 {
                    Text("· \(days)d remaining")
                        .font(.caption).fontWeight(.semibold)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
            }
            .padding(14)
            .background(Theme.xpGold.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Theme.xpGold.opacity(0.4), lineWidth: 1.5)
            )
        }
    }

    // MARK: - Active Challenges

    @ViewBuilder
    private var activeChallengesSection: some View {
        let active = allChallenges.filter { !$0.isCompleted && !$0.isFailed }
        if !active.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Active Challenges")
                VStack(spacing: 10) {
                    ForEach(active) { challenge in
                        Card {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(challenge.tierLabel)
                                        .font(.caption2).fontWeight(.heavy).tracking(1)
                                        .foregroundStyle(challenge.tier >= 3 ? Theme.xpGold : Theme.primaryAccent)
                                        .padding(.horizontal, 8).padding(.vertical, 3)
                                        .background((challenge.tier >= 3 ? Theme.xpGold : Theme.primaryAccent).opacity(0.15))
                                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                                    if challenge.isMegaChallenge {
                                        Text("MEGA")
                                            .font(.caption2).fontWeight(.heavy).tracking(1)
                                            .foregroundStyle(.purple)
                                            .padding(.horizontal, 8).padding(.vertical, 3)
                                            .background(Color.purple.opacity(0.15))
                                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                    }

                                    Spacer()

                                    Text("+\(challenge.xpReward) XP")
                                        .font(.caption).fontWeight(.heavy).monospacedDigit()
                                        .foregroundStyle(Theme.xpGreen)
                                }

                                Text(challenge.title)
                                    .font(.subheadline).fontWeight(.semibold)
                                    .foregroundStyle(Theme.textPrimary)

                                Text(challenge.challengeDescription)
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)

                                ProgressBar(progress: challenge.progress,
                                            color: challenge.tier >= 3 ? Theme.xpGold : Theme.primaryAccent)

                                HStack {
                                    Text(String(format: "%.1f / %.1f", challenge.currentValue, challenge.targetValue))
                                        .font(.caption).monospacedDigit()
                                        .foregroundStyle(Theme.textSecondary)
                                    Spacer()
                                    Text("\(Int(challenge.progress * 100))%")
                                        .font(.caption).fontWeight(.heavy).monospacedDigit()
                                        .foregroundStyle(challenge.progress >= 1 ? Theme.xpGreen : Theme.textSecondary)
                                }
                            }
                            .padding(Theme.cardPadding)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Phase 4.5 Status Row

    private var phase45StatusRow: some View {
        HStack(spacing: 16) {
            // Balanced day streak
            Card {
                VStack(spacing: 8) {
                    Image(systemName: "scale.3d")
                        .font(.title2)
                        .foregroundStyle(Theme.xpGreen)
                    Text("\(BonusEngine.balancedDayStreak(in: context))")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text("BALANCED\nSTREAK")
                        .font(.caption2).fontWeight(.heavy).tracking(1)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.cardPadding)
            }

            // Founder week count
            Card {
                VStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.xpGold)
                    Text("\(BonusEngine.founderWeekCount(in: context))")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text("FOUNDER\nWEEKS")
                        .font(.caption2).fontWeight(.heavy).tracking(1)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.cardPadding)
            }

            // Challenge streak
            Card {
                VStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.primaryAccent)
                    Text("\(ChallengeManager.consecutiveChallengesCompleted(in: context))")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text("CHALLENGE\nSTREAK")
                        .font(.caption2).fontWeight(.heavy).tracking(1)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.cardPadding)
            }

            // Achievements earned
            Card {
                VStack(spacing: 8) {
                    Image(systemName: "medal.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.secondaryAccent)
                    Text("\(achievements.filter(\.isEarned).count)")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text("ACHIEVE-\nMENTS")
                        .font(.caption2).fontWeight(.heavy).tracking(1)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.cardPadding)
            }
        }
    }

    // MARK: - Personal Records

    @ViewBuilder
    private var recordsSection: some View {
        if !records.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Personal Records")
                VStack(spacing: 10) {
                    ForEach(records.prefix(3)) { record in
                        HStack(spacing: 14) {
                            Image(systemName: "trophy.fill")
                                .font(.title3)
                                .foregroundStyle(Theme.xpGold)
                                .frame(width: 40, height: 40)
                                .background(Theme.xpGold.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.title)
                                    .font(.subheadline).fontWeight(.semibold)
                                    .foregroundStyle(Theme.textPrimary)
                                Text("\(record.track) · \(record.value)")
                                    .font(.caption).monospacedDigit()
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            Text(record.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .padding(14)
                        .background(Theme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Theme.cardBorder, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        }
    }

    // MARK: - Track Cards

    private var trackCards: some View {
        HStack(spacing: 16) {
            XPTrackCard(
                title: "Fitness",
                icon: "figure.run",
                color: Theme.xpGreen,
                level: user.fitnessLevel,
                xp: user.fitnessXP,
                metrics: fitnessMetrics
            )
            XPTrackCard(
                title: "Work",
                icon: "briefcase.fill",
                color: Theme.secondaryAccent,
                level: user.workLevel,
                xp: user.workXP,
                metrics: workMetrics
            )
            XPTrackCard(
                title: "Learning",
                icon: "book.fill",
                color: Theme.primaryAccent,
                level: user.learningLevel,
                xp: user.learningXP,
                metrics: learningMetrics
            )
        }
    }

    // MARK: - Track card metrics

    private var fitnessMetrics: [XPTrackCard.Metric] {
        let weightText: String
        if let latest = fitnessVM.latestWeight {
            weightText = String(format: "%.1f kg", latest.weightKg)
        } else {
            weightText = "—"
        }
        return [
            .init(label: "WEEK",   value: "\(fitnessVM.sessionsThisWeek)/5"),
            .init(label: "TODAY",  value: "\(fitnessVM.todaysCalories) kcal"),
            .init(label: "WEIGHT", value: weightText)
        ]
    }

    private var workMetrics: [XPTrackCard.Metric] {
        let overdueCount = workVM.overdueDeals.count
        return [
            .init(label: "PIPELINE",
                  value: String(format: "$%.1fM", workVM.pipelineValueMillion)),
            .init(label: "DEALS",
                  value: "\(workVM.openDeals.count) open"),
            .init(label: "OVERDUE",
                  value: "\(overdueCount)",
                  tint: overdueCount > 0 ? .red : nil)
        ]
    }

    private var studyHoursThisWeek: Double {
        let cal = Calendar.current
        let weekStart = cal.dateInterval(of: .weekOfYear, for: .now)?.start ?? cal.startOfDay(for: .now)
        return learningLogs
            .filter { $0.date >= weekStart }
            .reduce(0) { $0 + $1.hoursStudied }
    }

    private var learningMetrics: [XPTrackCard.Metric] {
        let hit = studyHoursThisWeek >= Double(weeklyStudyHoursTarget)
        return [
            .init(label: "COURSES", value: "\(learningVM.coursesInProgress.count) active"),
            .init(label: "BOOKS",   value: "\(learningVM.booksInProgress.count) reading"),
            .init(label: "STUDY",
                  value: String(format: "%.0f/%d hrs", studyHoursThisWeek, weeklyStudyHoursTarget),
                  tint: hit ? Theme.xpGreen : nil)
        ]
    }

    // MARK: - Recent Unlocks

    private var recentUnlocksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recent Unlocks")
            if vm.recentUnlocks.isEmpty {
                Card {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(Theme.textSecondary)
                        Text("Keep going — first unlock at Level 3")
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Theme.cardPadding)
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(vm.recentUnlocks) { unlock in
                        UnlockRow(unlock: unlock)
                    }
                }
            }
        }
    }

    // MARK: - Next Unlocks

    private var nextUnlocksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Next Unlocks")
            HStack(spacing: 16) {
                nextCard(track: "fitness",
                         label: "Fitness",
                         currentXP: user.fitnessXP,
                         color: Theme.xpGreen)
                nextCard(track: "work",
                         label: "Work",
                         currentXP: user.workXP,
                         color: Theme.secondaryAccent)
                nextCard(track: "learning",
                         label: "Learning",
                         currentXP: user.learningXP,
                         color: Theme.primaryAccent)
            }
        }
    }

    @ViewBuilder
    private func nextCard(track: String, label: String, currentXP: Int, color: Color) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text(label.uppercased())
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(color)

                if let next = vm.nextUnlock(forTrack: track) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: next.iconName)
                            .font(.title2)
                            .foregroundStyle(color)
                            .frame(width: 40, height: 40)
                            .background(color.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(next.title)
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundStyle(Theme.textPrimary)
                            let need = max(0, next.xpRequired - currentXP)
                            Text("\(need.formatted()) XP away · Lv \(next.levelRequired)")
                                .font(.caption).monospacedDigit()
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                    }
                } else {
                    Text("All unlocks earned — legend.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.xpGreen)
                }
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Today's Summary

    private var todaySummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Today")
            Card {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("XP EARNED TODAY")
                                .font(.caption).fontWeight(.heavy).tracking(2)
                                .foregroundStyle(Theme.textSecondary)
                            Text("\(vm.xpEarnedToday.formatted())")
                                .font(.system(size: 40, weight: .black, design: .rounded))
                                .foregroundStyle(Theme.xpGreen)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("STREAK")
                                .font(.caption).fontWeight(.heavy).tracking(2)
                                .foregroundStyle(Theme.textSecondary)
                            Text("Day \(user.currentStreak)")
                                .font(.system(size: 40, weight: .black, design: .rounded))
                                .foregroundStyle(Theme.primaryAccent)
                        }
                    }

                    Divider().background(Theme.cardBorder)

                    HStack(spacing: 12) {
                        actionButton(title: "Log Workout",
                                     icon: "figure.run",
                                     color: Theme.xpGreen,
                                     destination: .fitness)
                        actionButton(title: "Log Work",
                                     icon: "briefcase.fill",
                                     color: Theme.secondaryAccent,
                                     destination: .work)
                        actionButton(title: "Log Learning",
                                     icon: "book.fill",
                                     color: Theme.primaryAccent,
                                     destination: .learning)
                    }
                }
                .padding(Theme.cardPadding)
            }
        }
    }

    private func actionButton(title: String, icon: String, color: Color, destination: SidebarItem) -> some View {
        Button {
            navigationSelection = destination
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .stroke(color.opacity(0.5), lineWidth: 1)
            )
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
