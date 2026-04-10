//
//  HabitsTabView.swift
//  LEVEL UP — Phase 2
//
//  The six-item daily checklist. Sleep 7+ hrs, 3L water, 10k steps,
//  no junk food, morning workout, evening stretch. Completing all six
//  in one day awards a 30 XP bonus (once per day). Individual ticks
//  do NOT award XP — only the full-house bonus does.
//

import SwiftUI
import SwiftData

struct HabitsTabView: View {

    let user: User
    let vm: FitnessViewModel

    @Environment(\.modelContext) private var context

    // Localised handle for today's log (fetched / created on appear
    // and cached so toggles re-render instantly).
    @State private var todayLog: HabitLog?

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerCard
            checklistCard
            streakStripCard
        }
        .onAppear(perform: ensureTodayLog)
    }

    // MARK: - Header

    private var headerCard: some View {
        Card {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DAILY HABITS")
                        .font(.caption).fontWeight(.heavy).tracking(2)
                        .foregroundStyle(Theme.textSecondary)
                    Text(Date.now.formatted(date: .complete, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(Theme.textPrimary)
                }
                Spacer()
                if let log = todayLog, log.allCompleted {
                    Label("ALL DONE", systemImage: "checkmark.seal.fill")
                        .font(.caption).fontWeight(.heavy).tracking(2)
                        .foregroundStyle(Theme.xpGreen)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Theme.xpGreen.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .padding(Theme.cardPadding)
        }
    }

    // MARK: - Checklist

    private var checklistCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                habitRow("Sleep 7+ hrs", icon: "bed.double.fill",
                         get: { todayLog?.sleep ?? false },
                         set: { todayLog?.sleep = $0 })
                habitRow("3L water", icon: "drop.fill",
                         get: { todayLog?.water ?? false },
                         set: { todayLog?.water = $0 })
                habitRow("10k steps", icon: "figure.walk",
                         get: { todayLog?.steps ?? false },
                         set: { todayLog?.steps = $0 })
                habitRow("No junk food", icon: "leaf.fill",
                         get: { todayLog?.noJunk ?? false },
                         set: { todayLog?.noJunk = $0 })
                habitRow("Morning workout", icon: "sunrise.fill",
                         get: { todayLog?.morningWorkout ?? false },
                         set: { todayLog?.morningWorkout = $0 })
                habitRow("Evening stretch", icon: "figure.cooldown",
                         get: { todayLog?.eveningStretch ?? false },
                         set: { todayLog?.eveningStretch = $0 })
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func habitRow(_ title: String,
                          icon: String,
                          get: @escaping () -> Bool,
                          set: @escaping (Bool) -> Void) -> some View {
        let value = get()
        return Button {
            set(!value)
            checkBonus()
            try? context.save()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: value ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(value ? Theme.xpGreen : Theme.textSecondary)
                Image(systemName: icon)
                    .foregroundStyle(value ? Theme.xpGreen : Theme.textSecondary)
                    .frame(width: 24)
                Text(title)
                    .font(.body).fontWeight(.semibold)
                    .foregroundStyle(value ? Theme.textPrimary : Theme.textSecondary)
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(value ? Theme.xpGreen.opacity(0.08) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Streak strip

    private var streakStripCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("LAST 7 DAYS")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)
                HStack(spacing: 10) {
                    ForEach(pastSevenDays(), id: \.self) { day in
                        let done = vm.habitLogs.first {
                            Calendar.current.isDate($0.date, inSameDayAs: day)
                        }?.allCompleted ?? false
                        VStack(spacing: 6) {
                            Text(day.formatted(.dateTime.weekday(.narrow)))
                                .font(.caption2).fontWeight(.heavy)
                                .foregroundStyle(Theme.textSecondary)
                            Circle()
                                .fill(done ? Theme.xpGreen : Theme.background)
                                .frame(width: 26, height: 26)
                                .overlay(
                                    Circle().stroke(done ? Theme.xpGreen : Theme.cardBorder,
                                                    lineWidth: 1)
                                )
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func pastSevenDays() -> [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return (0..<7).compactMap { offset in
            cal.date(byAdding: .day, value: -offset, to: today)
        }.reversed()
    }

    // MARK: - Logic

    private func ensureTodayLog() {
        if let existing = vm.todayHabitLog() {
            todayLog = existing
            return
        }
        let fresh = HabitLog(date: .now)
        context.insert(fresh)
        try? context.save()
        todayLog = fresh
    }

    /// Award the 30 XP bonus exactly once, the first time all six
    /// habits are ticked on a given day.
    private func checkBonus() {
        guard let log = todayLog else { return }
        if log.allCompleted, !log.bonusAwarded {
            log.bonusAwarded = true
            log.xpEarned += XPEngine.xpForAllDailyHabits
            user.award(XPEngine.xpForAllDailyHabits, to: .fitness)
            try? context.save()
            let newly = UnlockEngine.evaluateUnlocks(user: user, context: context)
            UnlockCenter.shared.present(newly)
        }
    }
}
