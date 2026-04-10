//
//  QuickLogPopover.swift
//  LEVEL UP — Phase 5
//
//  Compact popover attached to the menu bar icon. Three tabs
//  for quick logging Fitness / Work / Learning without opening
//  the full app. Auto-closes 1.5 seconds after a successful log.
//

import SwiftUI
import SwiftData

// MARK: - Tab enum

enum QuickLogTab: String, CaseIterable, Identifiable {
    case fitness, work, learning
    var id: String { rawValue }
    var title: String {
        switch self {
        case .fitness:  return "Fitness"
        case .work:     return "Work"
        case .learning: return "Learning"
        }
    }
    var icon: String {
        switch self {
        case .fitness:  return "figure.run"
        case .work:     return "briefcase.fill"
        case .learning: return "book.fill"
        }
    }
    var color: Color {
        switch self {
        case .fitness:  return Theme.xpGreen
        case .work:     return Theme.secondaryAccent
        case .learning: return Theme.primaryAccent
        }
    }
}

// MARK: - Main Popover

struct QuickLogPopover: View {

    @ObservedObject var manager: MenuBarManager
    @Environment(\.modelContext) private var context
    @Query private var users: [User]
    @State private var selectedTab: QuickLogTab = .fitness
    @State private var xpGainText: String?

    private var user: User? { users.first }

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 0) {
                ForEach(QuickLogTab.allCases) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: tab.icon)
                                .font(.caption)
                            Text(tab.title)
                                .font(.caption).fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedTab == tab ? tab.color.opacity(0.2) : Color.clear)
                        .foregroundStyle(selectedTab == tab ? tab.color : Theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Theme.cardBackground)

            Divider().background(Theme.cardBorder)

            // Content
            ScrollView {
                if let user {
                    Group {
                        switch selectedTab {
                        case .fitness:  QuickLogFitnessTab(user: user, onLog: handleLog)
                        case .work:     QuickLogWorkTab(user: user, onLog: handleLog)
                        case .learning: QuickLogLearningTab(user: user, onLog: handleLog)
                        }
                    }
                    .padding(14)
                } else {
                    Text("Open LEVEL UP first to create your profile.")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .padding(20)
                }
            }

            // XP gain overlay
            if let gain = xpGainText {
                HStack {
                    Spacer()
                    Text(gain)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.xpGreen)
                    Spacer()
                }
                .padding(.vertical, 8)
                .background(Theme.xpGreen.opacity(0.1))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(width: 320)
        .background(Theme.background)
        .preferredColorScheme(.dark)
        .onAppear {
            selectedTab = manager.defaultTab
        }
    }

    private func handleLog(xp: Int) {
        withAnimation(.spring(response: 0.3)) {
            xpGainText = "+\(xp) XP"
        }
        manager.pulseIcon()
        manager.logCompleted()
    }
}

// MARK: - Fitness Quick Log Tab

struct QuickLogFitnessTab: View {

    let user: User
    let onLog: (Int) -> Void

    @Environment(\.modelContext) private var context
    @Query(sort: \GymSession.date, order: .reverse) private var gymSessions: [GymSession]
    @Query(sort: \HabitLog.date, order: .reverse) private var habitLogs: [HabitLog]

    @State private var intensity: XPEngine.FitnessIntensity = .medium
    @State private var weightText = ""
    @State private var loggedToday = false

    private var todaysSplit: String {
        GymSplitEngine.plannedSplit(for: .now)
    }

    private var alreadyLoggedToday: Bool {
        let cal = Calendar.current
        return gymSessions.contains { cal.isDateInToday($0.date) && !$0.isRestDay }
    }

    private var todaysFitnessXP: Int {
        let cal = Calendar.current
        return gymSessions.filter { cal.isDateInToday($0.date) }.reduce(0) { $0 + $1.xpEarned }
    }

    private var todaysHabitLog: HabitLog? {
        let cal = Calendar.current
        return habitLogs.first { cal.isDateInToday($0.date) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Today's workout card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("TODAY: \(todaysSplit) DAY")
                        .font(.caption).fontWeight(.heavy).tracking(2)
                        .foregroundStyle(Theme.xpGreen)
                    Spacer()
                    if alreadyLoggedToday || loggedToday {
                        Text("DONE")
                            .font(.caption2).fontWeight(.heavy)
                            .foregroundStyle(Theme.xpGreen)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Theme.xpGreen.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }

                if todaysSplit == "Rest" {
                    Text("Recovery day — walk, stretch, sleep")
                        .font(.caption).foregroundStyle(Theme.textSecondary)
                } else if !alreadyLoggedToday && !loggedToday {
                    Text(GymSplitEngine.description(for: todaysSplit))
                        .font(.caption).foregroundStyle(Theme.textSecondary)

                    // Intensity picker
                    HStack(spacing: 8) {
                        Text("Intensity:")
                            .font(.caption).foregroundStyle(Theme.textSecondary)
                        Picker("", selection: $intensity) {
                            ForEach(XPEngine.FitnessIntensity.allCases, id: \.self) { i in
                                Text(i.rawValue.capitalized).tag(i)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                    }

                    Button("Mark Done") {
                        logWorkout()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.xpGreen)
                }
            }
            .padding(12)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.cardBorder, lineWidth: 1))

            // Quick weight log
            VStack(alignment: .leading, spacing: 6) {
                Text("QUICK WEIGHT LOG")
                    .font(.caption2).fontWeight(.heavy).tracking(1)
                    .foregroundStyle(Theme.textSecondary)
                HStack(spacing: 8) {
                    TextField("kg", text: $weightText)
                        .textFieldStyle(.plain)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textPrimary)
                        .padding(8)
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.cardBorder, lineWidth: 1))
                        .frame(width: 80)
                    Button("Log Weight") {
                        logWeight()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.xpGreen)
                    .disabled(Double(weightText) == nil)
                }
            }

            // Habits quick check
            if let habitLog = todaysHabitLog {
                VStack(alignment: .leading, spacing: 6) {
                    Text("TODAY'S HABITS")
                        .font(.caption2).fontWeight(.heavy).tracking(1)
                        .foregroundStyle(Theme.textSecondary)
                    habitRow("Sleep 7+ hrs", isOn: habitLog.sleep) { habitLog.sleep = $0; saveHabits(habitLog) }
                    habitRow("3L water", isOn: habitLog.water) { habitLog.water = $0; saveHabits(habitLog) }
                    habitRow("10k steps", isOn: habitLog.steps) { habitLog.steps = $0; saveHabits(habitLog) }
                    habitRow("No junk food", isOn: habitLog.noJunk) { habitLog.noJunk = $0; saveHabits(habitLog) }
                    habitRow("Morning workout", isOn: habitLog.morningWorkout) { habitLog.morningWorkout = $0; saveHabits(habitLog) }
                    habitRow("Evening stretch", isOn: habitLog.eveningStretch) { habitLog.eveningStretch = $0; saveHabits(habitLog) }
                }
            }

            // Today's XP
            HStack {
                Text("TODAY'S FITNESS XP")
                    .font(.caption2).fontWeight(.heavy).tracking(1)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("\(todaysFitnessXP)")
                    .font(.subheadline).fontWeight(.heavy).monospacedDigit()
                    .foregroundStyle(Theme.xpGreen)
            }
        }
    }

    private func habitRow(_ label: String, isOn: Bool, toggle: @escaping (Bool) -> Void) -> some View {
        HStack(spacing: 8) {
            Button {
                toggle(!isOn)
            } label: {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isOn ? Theme.xpGreen : Theme.textSecondary)
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
            Text(label)
                .font(.caption)
                .foregroundStyle(isOn ? Theme.textPrimary : Theme.textSecondary)
            Spacer()
        }
    }

    private func logWorkout() {
        let state = GymSplitEngine.state(in: context)
        let result = GymSplitEngine.logGymSession(
            user: user, state: state,
            splitDay: todaysSplit == "Rest" ? "Upper" : todaysSplit,
            intensity: intensity,
            notes: "Quick log",
            exercises: [],
            in: context
        )
        user.award(result.totalXP, to: .fitness)
        ChallengeManager.updateProgress(user: user, in: context)
        try? context.save()
        loggedToday = true
        onLog(result.totalXP)
    }

    private func logWeight() {
        guard let kg = Double(weightText) else { return }
        let entry = WeightEntry(weightKg: kg, xpEarned: XPEngine.xpForWeightLog)
        context.insert(entry)
        user.award(XPEngine.xpForWeightLog, to: .fitness)
        try? context.save()
        weightText = ""
        onLog(XPEngine.xpForWeightLog)
    }

    private func saveHabits(_ log: HabitLog) {
        if log.allCompleted && !log.bonusAwarded {
            log.bonusAwarded = true
            let xp = XPEngine.xpForAllDailyHabits
            log.xpEarned += xp
            user.award(xp, to: .fitness)
        }
        try? context.save()
    }
}

// MARK: - Work Quick Log Tab

struct QuickLogWorkTab: View {

    let user: User
    let onLog: (Int) -> Void

    @Environment(\.modelContext) private var context
    @Query(sort: \ParaLAIEntry.date, order: .reverse) private var paralaiEntries: [ParaLAIEntry]
    @Query(sort: \OtherWorkLog.date, order: .reverse) private var otherLogs: [OtherWorkLog]
    @Query private var deals: [Deal]

    enum WorkType: String, CaseIterable {
        case paralai = "ParaLAI"
        case bva = "BVA"
        case projects = "Projects"
    }

    @State private var workType: WorkType = .paralai
    @State private var title = ""
    @State private var hours = 1.0
    @State private var actionType = "Feature Built"
    @State private var category = "Other"

    private var todaysWorkXP: Int {
        let cal = Calendar.current
        let pXP = paralaiEntries.filter { cal.isDateInToday($0.date) }.reduce(0) { $0 + $1.xpEarned }
        let oXP = otherLogs.filter { cal.isDateInToday($0.date) }.reduce(0) { $0 + $1.xpEarned }
        return pXP + oXP
    }

    private var activeDealsCount: Int {
        deals.filter { !$0.isClosedWon && !$0.isClosedLost }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Type picker
            Picker("", selection: $workType) {
                ForEach(WorkType.allCases, id: \.self) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            .pickerStyle(.segmented)

            // Title
            TextField("What did you work on?", text: $title)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .foregroundStyle(Theme.textPrimary)
                .padding(8)
                .background(Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.cardBorder, lineWidth: 1))

            // Category picker (Projects only)
            if workType == .projects {
                HStack {
                    Text("Category:")
                        .font(.caption).foregroundStyle(Theme.textSecondary)
                    Picker("", selection: $category) {
                        ForEach(OtherWorkLog.categories, id: \.self) { c in
                            Text(c).tag(c)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // Action type (ParaLAI only)
            if workType == .paralai {
                HStack {
                    Text("Type:")
                        .font(.caption).foregroundStyle(Theme.textSecondary)
                    Picker("", selection: $actionType) {
                        ForEach(["Feature Built", "Bug Fixed", "Milestone Shipped", "Meeting", "Research", "Other"], id: \.self) { t in
                            Text(t).tag(t)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // Hours
            HStack {
                Text("Hours:")
                    .font(.caption).foregroundStyle(Theme.textSecondary)
                HStack(spacing: 6) {
                    Button { hours = max(0.5, hours - 0.5) } label: {
                        Image(systemName: "minus.circle")
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    Text(String(format: "%.1f", hours))
                        .font(.subheadline).fontWeight(.semibold).monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                        .frame(width: 40, alignment: .center)
                    Button { hours = min(12, hours + 0.5) } label: {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(Theme.secondaryAccent)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Log button
            Button("Log Work") {
                logWork()
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.secondaryAccent)
            .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)

            Divider().background(Theme.cardBorder)

            // Info row
            HStack {
                Text("TODAY'S WORK XP")
                    .font(.caption2).fontWeight(.heavy).tracking(1)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("\(todaysWorkXP)")
                    .font(.subheadline).fontWeight(.heavy).monospacedDigit()
                    .foregroundStyle(Theme.secondaryAccent)
            }

            if workType == .bva {
                HStack {
                    Image(systemName: "building.columns.fill")
                        .foregroundStyle(Theme.secondaryAccent)
                    Text("\(activeDealsCount) active deals")
                        .font(.caption).foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    private func logWork() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }

        switch workType {
        case .paralai:
            let xp: Int
            switch actionType {
            case "Feature Built":       xp = XPEngine.xpForParaLAIFeature
            case "Bug Fixed":           xp = XPEngine.xpForParaLAIBug
            case "Milestone Shipped":   xp = XPEngine.xpForParaLAIMilestone
            default:                    xp = 50
            }
            let entry = ParaLAIEntry(actionType: actionType, title: trimmedTitle,
                                     detail: "", hoursSpent: hours, xpEarned: xp)
            context.insert(entry)
            user.award(xp, to: .work)
            ChallengeManager.updateProgress(user: user, in: context)
            try? context.save()
            title = ""
            onLog(xp)

        case .bva:
            // Quick BVA log — stage update on most recent deal
            let xp = XPEngine.xpForBVAMeeting
            let entry = ParaLAIEntry(actionType: "Meeting", title: "BVA: \(trimmedTitle)",
                                     detail: "", hoursSpent: hours, xpEarned: xp)
            context.insert(entry)
            user.award(xp, to: .work)
            ChallengeManager.updateProgress(user: user, in: context)
            try? context.save()
            title = ""
            onLog(xp)

        case .projects:
            let xp = OtherWorkLog.calculateXP(hours: hours, actionType: "Deep Work", category: category)
            let log = OtherWorkLog(category: category, projectName: trimmedTitle,
                                   actionType: "Deep Work", title: trimmedTitle,
                                   hoursSpent: hours, xpEarned: xp)
            context.insert(log)
            user.award(xp, to: .work)
            ChallengeManager.updateProgress(user: user, in: context)
            try? context.save()
            title = ""
            onLog(xp)
        }
    }
}

// MARK: - Learning Quick Log Tab

struct QuickLogLearningTab: View {

    let user: User
    let onLog: (Int) -> Void

    @Environment(\.modelContext) private var context
    @Query private var courses: [Course]
    @Query private var books: [Book]
    @Query private var certifications: [Certification]

    enum LearningType: String, CaseIterable {
        case course = "Course"
        case book = "Book"
        case cert = "Cert"
    }

    @State private var learningType: LearningType = .course
    @State private var selectedCourseName = ""
    @State private var selectedBookTitle = ""
    @State private var selectedCertName = ""
    @State private var durationMinutes = 30.0

    private var activeCourses: [Course] {
        courses.filter { !$0.isCompleted }
    }

    private var activeBooks: [Book] {
        books.filter { !$0.isFinished }
    }

    private var activeCerts: [Certification] {
        certifications.filter { !$0.isEarned }
    }

    private var todaysLearningXP: Int {
        // Approximate — courses don't track per-session dates
        0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Type picker
            Picker("", selection: $learningType) {
                ForEach(LearningType.allCases, id: \.self) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            .pickerStyle(.segmented)

            switch learningType {
            case .course:
                if activeCourses.isEmpty {
                    emptyState("No active courses — add one in the main app.")
                } else {
                    Picker("Course:", selection: $selectedCourseName) {
                        Text("Select...").tag("")
                        ForEach(activeCourses) { course in
                            Text(course.name).tag(course.name)
                        }
                    }
                    durationPicker
                    Button("Log Session") { logCourseSession() }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.primaryAccent)
                        .disabled(selectedCourseName.isEmpty)
                }

            case .book:
                if activeBooks.isEmpty {
                    emptyState("No books in progress — add one in the main app.")
                } else {
                    Picker("Book:", selection: $selectedBookTitle) {
                        Text("Select...").tag("")
                        ForEach(activeBooks) { book in
                            Text(book.title).tag(book.title)
                        }
                    }
                    durationPicker
                    Button("Log Session") { logBookSession() }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.primaryAccent)
                        .disabled(selectedBookTitle.isEmpty)
                }

            case .cert:
                if activeCerts.isEmpty {
                    emptyState("No certifications — add one in the main app.")
                } else {
                    Picker("Certification:", selection: $selectedCertName) {
                        Text("Select...").tag("")
                        ForEach(activeCerts) { cert in
                            Text(cert.name).tag(cert.name)
                        }
                    }
                    durationPicker
                    Button("Log Session") { logCertSession() }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.primaryAccent)
                        .disabled(selectedCertName.isEmpty)
                }
            }

            Divider().background(Theme.cardBorder)

            // Summary
            HStack {
                Text("ACTIVE")
                    .font(.caption2).fontWeight(.heavy).tracking(1)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("\(activeCourses.count) courses · \(activeBooks.count) books · \(activeCerts.count) certs")
                    .font(.caption).monospacedDigit()
                    .foregroundStyle(Theme.primaryAccent)
            }
        }
    }

    private var durationPicker: some View {
        HStack {
            Text("Duration:")
                .font(.caption).foregroundStyle(Theme.textSecondary)
            HStack(spacing: 6) {
                Button { durationMinutes = max(15, durationMinutes - 15) } label: {
                    Image(systemName: "minus.circle")
                        .foregroundStyle(Theme.textSecondary)
                }
                .buttonStyle(.plain)
                Text("\(Int(durationMinutes)) min")
                    .font(.subheadline).fontWeight(.semibold).monospacedDigit()
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: 60, alignment: .center)
                Button { durationMinutes = min(240, durationMinutes + 15) } label: {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(Theme.primaryAccent)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func emptyState(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(Theme.textSecondary)
            .padding(.vertical, 8)
    }

    private func logCourseSession() {
        guard let course = activeCourses.first(where: { $0.name == selectedCourseName }) else { return }
        let hours = durationMinutes / 60.0
        let xp = hours >= 1 ? XPEngine.xpForStudy1Hour : XPEngine.xpForStudy30Min
        course.totalHours += hours
        course.xpEarned += xp
        if durationMinutes >= 30 {
            course.completedLessons = min(course.totalLessons, course.completedLessons + 1)
        }
        user.award(xp, to: .learning)
        context.insert(LearningLog(type: "course", name: course.name, hoursStudied: hours, xpEarned: xp))
        ChallengeManager.updateProgress(user: user, in: context)
        try? context.save()
        onLog(xp)
    }

    private func logBookSession() {
        guard let book = activeBooks.first(where: { $0.title == selectedBookTitle }) else { return }
        let hours = durationMinutes / 60.0
        let xp = 30
        book.totalHours += hours
        book.pagesRead = min(book.totalPages, book.pagesRead + max(1, Int(durationMinutes / 2)))
        book.xpEarned += xp
        user.award(xp, to: .learning)
        context.insert(LearningLog(type: "book", name: book.title, hoursStudied: hours, xpEarned: xp))
        ChallengeManager.updateProgress(user: user, in: context)
        try? context.save()
        onLog(xp)
    }

    private func logCertSession() {
        guard let cert = activeCerts.first(where: { $0.name == selectedCertName }) else { return }
        let hours = durationMinutes / 60.0
        let xp = hours >= 1 ? XPEngine.xpForStudy1Hour : XPEngine.xpForStudy30Min
        cert.studiedHours += hours
        cert.xpEarned += xp
        user.award(xp, to: .learning)
        context.insert(LearningLog(type: "certification", name: cert.name, hoursStudied: hours, xpEarned: xp))
        ChallengeManager.updateProgress(user: user, in: context)
        try? context.save()
        onLog(xp)
    }
}
