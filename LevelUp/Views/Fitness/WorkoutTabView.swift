//
//  WorkoutTabView.swift
//  LEVEL UP — Phase 2
//
//  Gym split cycle + cardio logging. Top of the tab shows where the
//  user is in the Upper→Lower→Push→Pull→Legs cycle, current streak,
//  and a missed-days alert. Below: "Log Gym Session" and "Log Cardio"
//  forms, plus a history list.
//

import SwiftUI
import SwiftData

struct WorkoutTabView: View {

    let user: User
    let vm: FitnessViewModel

    @Environment(\.modelContext) private var context

    // Split state (fetched on appear, cached in local state).
    @State private var splitState: GymSplitState?

    // Gym form
    @State private var gymIntensity: XPEngine.FitnessIntensity = .medium
    @State private var gymNotes: String = ""
    @State private var exerciseRows: [ExerciseDraft] = [ExerciseDraft()]
    @State private var gymResultToast: String?
    /// Which split the user is actually training today. Defaults to the
    /// weekday plan (Upper on Mon, Lower on Tue, …) but can be changed
    /// to catch up on a missed day.
    @State private var selectedSplitDay: String = {
        let planned = GymSplitEngine.plannedSplit(for: .now)
        return planned == "Rest" ? "Upper" : planned
    }()

    // Cardio form
    @State private var cardioType: String = "Run"
    @State private var cardioMinutes: String = ""
    @State private var cardioDistance: String = ""
    @State private var cardioIntensity: XPEngine.FitnessIntensity = .medium
    @State private var cardioNotes: String = ""
    @State private var cardioToast: String?

    private let cardioTypes = ["Run", "Swim", "Cycle", "HIIT", "Yoga", "Walk", "Other"]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            cycleCard
            if let state = splitState, GymSplitEngine.shouldShowMissedAlert(state) {
                missedAlert(state: state)
            }
            gymLogCard
            cardioLogCard
            historyCard
        }
        .onAppear {
            if splitState == nil {
                splitState = GymSplitEngine.state(in: context)
            }
        }
    }

    // MARK: - Cycle card

    private var cycleCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TODAY'S SPLIT")
                            .font(.caption).fontWeight(.heavy).tracking(2)
                            .foregroundStyle(Theme.textSecondary)
                        Text(splitState.map { GymSplitEngine.todaysPlan($0) } ?? "—")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundStyle(Theme.xpGreen)
                        if let state = splitState {
                            Text(GymSplitEngine.description(for: GymSplitEngine.todaysPlan(state)))
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("STREAK")
                            .font(.caption).fontWeight(.heavy).tracking(2)
                            .foregroundStyle(Theme.textSecondary)
                        Text("\(splitState?.currentStreak ?? 0) days")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(Theme.primaryAccent)
                        Text("\(vm.sessionsThisWeek)/5 this week")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Divider().background(Theme.cardBorder)

                if let state = splitState {
                    HStack(spacing: 10) {
                        ForEach(Array(GymSplitEngine.nextSessions(state, count: 4).enumerated()), id: \.offset) { _, name in
                            nextPill(name)
                        }
                    }
                }

                HStack(spacing: 10) {
                    Button(action: logRestDay) {
                        Text("Mark Rest Day")
                            .font(.caption).fontWeight(.semibold)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(Theme.cardBorder.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func nextPill(_ name: String) -> some View {
        Text(name.uppercased())
            .font(.caption).fontWeight(.heavy).tracking(2)
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Theme.background)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Theme.cardBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Missed alert

    private func missedAlert(state: GymSplitState) -> some View {
        let days = GymSplitEngine.missedDays(state) ?? 0
        return Card {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                VStack(alignment: .leading, spacing: 2) {
                    Text("MISSED \(days) DAYS")
                        .font(.caption).fontWeight(.heavy).tracking(2)
                        .foregroundStyle(.red)
                    Text("Get back in the gym today — streak resets after a gap.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textPrimary)
                }
                Spacer()
            }
            .padding(Theme.cardPadding)
        }
    }

    // MARK: - Gym log card

    private var gymLogCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("LOG GYM SESSION")
                        .font(.caption).fontWeight(.heavy).tracking(2)
                        .foregroundStyle(Theme.xpGreen)
                    Spacer()
                    Text("PLANNED: \(GymSplitEngine.plannedSplit(for: .now).uppercased())")
                        .font(.caption2).fontWeight(.heavy).tracking(1)
                        .foregroundStyle(Theme.textSecondary)
                }

                splitDayPicker
                intensityPicker(selection: $gymIntensity)

                VStack(spacing: 8) {
                    ForEach($exerciseRows) { $row in
                        HStack(spacing: 8) {
                            TextField("Exercise", text: $row.name)
                                .textFieldStyle(.plain)
                                .padding(10)
                                .background(Theme.background)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Theme.cardBorder, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                            numField("Sets", text: $row.setsText, width: 60)
                            numField("Reps", text: $row.repsText, width: 60)
                            numField("Kg", text: $row.weightText, width: 72)
                        }
                    }
                    Button {
                        exerciseRows.append(ExerciseDraft())
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add exercise")
                        }
                        .font(.caption).fontWeight(.semibold)
                        .foregroundStyle(Theme.xpGreen)
                    }
                    .buttonStyle(.plain)
                }

                TextField("Notes (optional)", text: $gymNotes)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Theme.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.cardBorder, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                HStack {
                    Button("Log Gym Session", action: submitGym)
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.xpGreen)
                        .foregroundStyle(Color.black)
                    if let toast = gymResultToast {
                        Text(toast)
                            .font(.caption).fontWeight(.semibold)
                            .foregroundStyle(Theme.xpGreen)
                    }
                }
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Pill row for picking which split the user is actually training today.
    /// Defaults to the weekday plan but can be overridden — e.g. if you
    /// missed Monday's Upper day, pick Upper on Tuesday.
    private var splitDayPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TRAINING TODAY")
                .font(.caption2).fontWeight(.heavy).tracking(1)
                .foregroundStyle(Theme.textSecondary)
            HStack(spacing: 8) {
                ForEach(GymSplitEngine.splitDays, id: \.self) { day in
                    let active = selectedSplitDay == day
                    Button {
                        selectedSplitDay = day
                    } label: {
                        Text(day.uppercased())
                            .font(.caption).fontWeight(.heavy).tracking(1)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .foregroundStyle(active ? Theme.xpGreen : Theme.textSecondary)
                            .background(active ? Theme.xpGreen.opacity(0.14) : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(active ? Theme.xpGreen.opacity(0.55) : Theme.cardBorder,
                                            lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func intensityPicker(selection: Binding<XPEngine.FitnessIntensity>) -> some View {
        HStack(spacing: 8) {
            ForEach(XPEngine.FitnessIntensity.allCases, id: \.self) { level in
                let active = selection.wrappedValue == level
                Button {
                    selection.wrappedValue = level
                } label: {
                    Text(level.rawValue.capitalized)
                        .font(.caption).fontWeight(.heavy).tracking(1)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .foregroundStyle(active ? Theme.xpGreen : Theme.textSecondary)
                        .background(active ? Theme.xpGreen.opacity(0.14) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(active ? Theme.xpGreen.opacity(0.55) : Theme.cardBorder,
                                        lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func numField(_ placeholder: String, text: Binding<String>, width: CGFloat) -> some View {
        TextField(placeholder, text: text)
            .textFieldStyle(.plain)
            .frame(width: width)
            .padding(10)
            .background(Theme.background)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Theme.cardBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Cardio log card

    private var cardioLogCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("LOG CARDIO")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.xpGreen)

                Picker("Type", selection: $cardioType) {
                    ForEach(cardioTypes, id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)

                HStack(spacing: 8) {
                    numField("Minutes", text: $cardioMinutes, width: 100)
                    numField("Distance km", text: $cardioDistance, width: 120)
                }
                intensityPicker(selection: $cardioIntensity)
                TextField("Notes (optional)", text: $cardioNotes)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Theme.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.cardBorder, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                HStack {
                    Button("Log Cardio", action: submitCardio)
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.xpGreen)
                        .foregroundStyle(Color.black)
                        .disabled(Int(cardioMinutes) == nil)
                    if let toast = cardioToast {
                        Text(toast)
                            .font(.caption).fontWeight(.semibold)
                            .foregroundStyle(Theme.xpGreen)
                    }
                }
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - History

    private var historyCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("RECENT")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)

                if vm.recentGymSessions.isEmpty && vm.recentCardioSessions.isEmpty {
                    Text("No sessions yet — log one above.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    ForEach(vm.recentGymSessions) { session in
                        historyRow(icon: "dumbbell.fill",
                                   title: session.splitDay,
                                   subtitle: "\(session.exercises.count) exercises · \(session.intensity.rawValue.capitalized)",
                                   xp: session.xpEarned,
                                   date: session.date)
                    }
                    ForEach(vm.recentCardioSessions) { c in
                        historyRow(icon: "figure.run",
                                   title: c.type,
                                   subtitle: "\(c.durationMinutes) min · \(c.intensity.rawValue.capitalized)",
                                   xp: c.xpEarned,
                                   date: c.date)
                    }
                }
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func historyRow(icon: String, title: String, subtitle: String, xp: Int, date: Date) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Theme.xpGreen)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("+\(xp) XP")
                    .font(.caption).fontWeight(.heavy)
                    .foregroundStyle(Theme.xpGreen)
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Actions

    private func submitGym() {
        guard let state = splitState else { return }
        let exercises = exerciseRows.compactMap { $0.make() }
        let result = GymSplitEngine.logGymSession(user: user,
                                                  state: state,
                                                  splitDay: selectedSplitDay,
                                                  intensity: gymIntensity,
                                                  notes: gymNotes,
                                                  exercises: exercises,
                                                  in: context)

        // Phase 3: route total XP through the central award helper so
        // gain + level-up events fire.
        user.award(result.totalXP, to: .fitness)

        // Fire the perfect-week overlay if the bonus landed.
        if result.perfectWeekBonus > 0 {
            GameEventCenter.shared.firePerfectWeek(xp: result.perfectWeekBonus)
        }

        // Personal records: evaluate the set of exercises just logged.
        PersonalRecordsEngine.evaluateLift(exercises: exercises, in: context)

        // Evaluate unlocks after granting XP.
        let newly = UnlockEngine.evaluateUnlocks(user: user, context: context)
        UnlockCenter.shared.present(newly)

        var parts = ["+\(result.baseXP)"]
        if result.mondayBonus > 0 { parts.append("+\(result.mondayBonus) Monday") }
        if result.perfectWeekBonus > 0 { parts.append("+\(result.perfectWeekBonus) Perfect Week") }
        if result.streakMilestoneBonus > 0 { parts.append("+\(result.streakMilestoneBonus) 30-day") }
        gymResultToast = parts.joined(separator: " · ")

        exerciseRows = [ExerciseDraft()]
        gymNotes = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { gymResultToast = nil }
    }

    private func submitCardio() {
        guard let minutes = Int(cardioMinutes) else { return }
        let distance = Double(cardioDistance) ?? 0
        let xp = XPEngine.xpForCardio(intensity: cardioIntensity)
        let session = CardioSession(date: .now,
                                    type: cardioType,
                                    durationMinutes: minutes,
                                    intensity: cardioIntensity,
                                    distanceKm: distance,
                                    notes: cardioNotes,
                                    xpEarned: xp)
        context.insert(session)
        user.award(xp, to: .fitness)
        try? context.save()

        PersonalRecordsEngine.evaluateCardio(session: session, in: context)

        let newly = UnlockEngine.evaluateUnlocks(user: user, context: context)
        UnlockCenter.shared.present(newly)

        cardioToast = "+\(xp) XP"
        cardioMinutes = ""
        cardioDistance = ""
        cardioNotes = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { cardioToast = nil }
    }

    private func logRestDay() {
        guard let state = splitState else { return }
        GymSplitEngine.logRestDay(state: state, in: context)
    }
}

// MARK: - Exercise draft

private struct ExerciseDraft: Identifiable {
    let id = UUID()
    var name: String = ""
    var setsText: String = ""
    var repsText: String = ""
    var weightText: String = ""

    func make() -> Exercise? {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        let sets = Int(setsText) ?? 0
        let reps = Int(repsText) ?? 0
        let weight = Double(weightText) ?? 0
        return Exercise(name: trimmed, sets: sets, reps: reps, weightKg: weight)
    }
}
