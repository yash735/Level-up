import SwiftUI
import SwiftData

struct QuickLogPopover: View {

    @ObservedObject var manager: MenuBarManager
    @Environment(\.modelContext) private var context

    @Query private var users: [User]
    @Query(sort: \Project.orderIndex) private var projects: [Project]
    @Query private var courses: [Course]
    @Query private var books: [Book]
    @Query private var certifications: [Certification]
    @Query(sort: \WorkEntry.date, order: .reverse) private var workEntries: [WorkEntry]
    @Query(sort: \GymSession.date, order: .reverse) private var gymSessions: [GymSession]
    @Query(sort: \CardioSession.date, order: .reverse) private var cardioSessions: [CardioSession]
    @Query(sort: \LearningLog.date, order: .reverse) private var learningLogs: [LearningLog]
    @Query(sort: \WeightEntry.date, order: .reverse) private var weightEntries: [WeightEntry]
    @Query(sort: \FoodEntry.date, order: .reverse) private var foodEntries: [FoodEntry]

    @State private var aiInput = ""
    @State private var aiState: AILogState = .idle
    @State private var xpGainText: String?

    private enum AILogState {
        case idle, processing
        case success(String, Int)
        case error(String)
    }

    private var user: User? { users.first }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 10)

            Divider().background(Theme.cardBorder)

            ScrollView {
                VStack(spacing: 16) {
                    aiInputSection
                    statusSection
                    recentLogsSection
                }
                .padding(16)
            }
        }
        .frame(width: 320)
        .background(Theme.background)
        .preferredColorScheme(.dark)
        .overlay(alignment: .bottom) {
            if let text = xpGainText {
                Text(text)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.xpGreen)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Theme.xpGreen.opacity(0.15))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("LEVEL UP")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .tracking(2)
                .foregroundStyle(Theme.heroGradient)
            Spacer()
            if let user {
                Text("Lv \(user.totalLevel)")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.primaryAccent)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Theme.primaryAccent.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    // MARK: - AI Input

    private var aiInputSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.xpGold)

            TextField("Log anything...", text: $aiInput)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundStyle(Theme.textPrimary)
                .onSubmit { submitLog() }
                .disabled(isProcessing)

            if isProcessing {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 20, height: 20)
            } else {
                Button(action: submitLog) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(aiInput.trimmingCharacters(in: .whitespaces).isEmpty
                                         ? Theme.textSecondary.opacity(0.3)
                                         : Theme.primaryAccent)
                }
                .buttonStyle(.plain)
                .disabled(aiInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(12)
        .background(Theme.cardBackground)
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
            .stroke(Theme.cardBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var isProcessing: Bool {
        if case .processing = aiState { return true }
        return false
    }

    // MARK: - Status

    @ViewBuilder
    private var statusSection: some View {
        switch aiState {
        case .idle, .processing:
            EmptyView()

        case .success(let summary, let xp):
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.xpGreen)
                VStack(alignment: .leading, spacing: 2) {
                    Text(summary)
                        .font(.caption).fontWeight(.semibold)
                        .foregroundStyle(Theme.textPrimary)
                    Text("+\(xp) XP")
                        .font(.caption).fontWeight(.heavy)
                        .foregroundStyle(Theme.xpGreen)
                }
                Spacer()
            }
            .padding(10)
            .background(Theme.xpGreen.opacity(0.1))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Theme.xpGreen.opacity(0.3), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

        case .error(let message):
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Button {
                    withAnimation { aiState = .idle }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(10)
            .background(Color.red.opacity(0.1))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.red.opacity(0.3), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    // MARK: - Recent Logs

    private var recentLogsSection: some View {
        let today = Calendar.current.startOfDay(for: .now)
        let todayWork = workEntries.filter { $0.date >= today }
        let todayGym = gymSessions.filter { $0.date >= today && !$0.isRestDay }
        let todayLearn = learningLogs.filter { $0.date >= today }
        let todayWeight = weightEntries.filter { $0.date >= today }
        let todayCardio = cardioSessions.filter { $0.date >= today }
        let todayFood = foodEntries.filter { $0.date >= today }

        let hasAny = !todayWork.isEmpty || !todayGym.isEmpty || !todayCardio.isEmpty
            || !todayLearn.isEmpty || !todayWeight.isEmpty || !todayFood.isEmpty

        return VStack(alignment: .leading, spacing: 10) {
            if hasAny {
                Text("TODAY")
                    .font(.caption2).fontWeight(.heavy).tracking(1.5)
                    .foregroundStyle(Theme.textSecondary)

                ForEach(todayGym.prefix(3)) { s in
                    recentRow(icon: "dumbbell.fill", color: Theme.xpGreen,
                              text: "\(s.splitDay) day — \(s.intensityRaw)",
                              xp: s.xpEarned)
                }
                ForEach(todayCardio.prefix(3)) { c in
                    recentRow(icon: "figure.run", color: Theme.xpGreen,
                              text: "\(c.type) — \(c.durationMinutes) min",
                              xp: c.xpEarned)
                }
                ForEach(todayWork.prefix(4)) { e in
                    recentRow(icon: "briefcase.fill", color: Theme.secondaryAccent,
                              text: "\(e.title) — \(String(format: "%.1fh", e.hoursSpent))",
                              xp: e.xpEarned)
                }
                ForEach(todayLearn.prefix(3)) { l in
                    recentRow(icon: "book.fill", color: Theme.primaryAccent,
                              text: "\(l.name) — \(String(format: "%.0fmin", l.hoursStudied * 60))",
                              xp: l.xpEarned)
                }
                ForEach(todayWeight.prefix(1)) { w in
                    recentRow(icon: "scalemass.fill", color: Theme.textSecondary,
                              text: String(format: "%.1f kg", w.weightKg),
                              xp: w.xpEarned)
                }
                ForEach(todayFood.prefix(2)) { f in
                    recentRow(icon: "fork.knife", color: Theme.xpGreen,
                              text: "\(f.foodName) — \(f.calories) kcal",
                              xp: f.xpEarned)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(Theme.xpGold.opacity(0.5))
                    Text("Type above to log anything")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    Text("\"2h deep work on BVA\"\n\"upper body workout, hard\"\n\"30 min cricket\"\n\"studied React for 1 hour\"\n\"82.5 kg\"")
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
    }

    private func recentRow(icon: String, color: Color, text: String, xp: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption2).foregroundStyle(color)
                .frame(width: 18)
            Text(text)
                .font(.caption)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
            Spacer()
            Text("+\(xp)")
                .font(.caption2).fontWeight(.heavy).monospacedDigit()
                .foregroundStyle(Theme.xpGreen)
        }
    }

    // MARK: - Submit

    private func submitLog() {
        let input = aiInput.trimmingCharacters(in: .whitespaces)
        guard !input.isEmpty, user != nil else { return }

        withAnimation { aiState = .processing }

        Task {
            do {
                let ctx = buildContextString()
                let result = try await AIClient.parseQuickLog(input: input, context: ctx)

                if result.confidence >= 0.5 {
                    let xp = try await executeLog(result)
                    withAnimation {
                        aiState = .success(result.summary, xp)
                        xpGainText = "+\(xp) XP"
                    }
                    aiInput = ""
                    manager.pulseIcon()
                    manager.logCompleted()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { xpGainText = nil }
                    }
                } else {
                    withAnimation {
                        aiState = .error(result.summary)
                    }
                }
            } catch let error as AIClient.AIError where error.localizedDescription.contains("No Anthropic API key") {
                withAnimation {
                    aiState = .error("Set up your API key to use AI logging.")
                }
            } catch let error as LogError {
                withAnimation {
                    aiState = .error(error.localizedDescription ?? "Log failed.")
                }
            } catch {
                withAnimation {
                    aiState = .error("Couldn't reach AI — try again.")
                }
            }
        }
    }

    // MARK: - Execute Log

    private enum LogError: LocalizedError {
        case projectNotFound(String)
        case learningNotFound(String)
        case foodFailed

        var errorDescription: String? {
            switch self {
            case .projectNotFound(let name): return "No active project matching '\(name)'"
            case .learningNotFound(let name): return "No active course/book/cert matching '\(name)'"
            case .foodFailed: return "Could not analyze food."
            }
        }
    }

    private func executeLog(_ result: AIClient.QuickLogResult) async throws -> Int {
        guard let user else { return 0 }
        let d = result.data

        let xp: Int
        switch result.type {
        case "work":
            xp = logWork(d, user: user)
        case "gym":
            xp = logGym(d, user: user)
        case "cardio":
            xp = logCardio(d, user: user)
        case "learning":
            xp = try logLearning(d, user: user)
        case "weight":
            xp = logWeight(d, user: user)
        case "food":
            xp = try await logFood(d, user: user)
        case "todo":
            xp = logTodo(d, summary: result.summary)
        default:
            xp = 0
        }

        if xp > 0 {
            let newly = UnlockEngine.evaluateUnlocks(user: user, context: context)
            UnlockCenter.shared.present(newly)
        }
        return xp
    }

    private func logWork(_ d: [String: Any], user: User) -> Int {
        let projectName = d["projectName"] as? String ?? ""
        let actionType = d["actionType"] as? String ?? "Other"
        let title = d["title"] as? String ?? "Work session"
        let hours = AIClient.doubleFromAny(d["hours"])
        let resolvedHours = hours > 0 ? hours : 1.0

        let project = projects.filter { !$0.isArchived }
            .first { $0.name.localizedCaseInsensitiveContains(projectName) || projectName.localizedCaseInsensitiveContains($0.name) }

        let xp = WorkEntry.calculateXP(hours: resolvedHours, actionType: actionType)
        let entry = WorkEntry(project: project, actionType: actionType,
                              title: title, hoursSpent: resolvedHours, xpEarned: xp)
        context.insert(entry)
        user.award(xp, to: .work)
        ChallengeManager.updateProgress(user: user, in: context)
        try? context.save()
        return xp
    }

    private func logGym(_ d: [String: Any], user: User) -> Int {
        let rawSplit = d["splitDay"] as? String ?? GymSplitEngine.plannedSplit(for: .now)
        let splitDay = GymSplitEngine.splitDays.first { $0.localizedCaseInsensitiveCompare(rawSplit) == .orderedSame }
            ?? GymSplitEngine.plannedSplit(for: .now)
        let intensityStr = d["intensity"] as? String ?? "medium"
        let intensity = XPEngine.FitnessIntensity(rawValue: intensityStr) ?? .medium

        let state = GymSplitEngine.state(in: context)
        let result = GymSplitEngine.logGymSession(
            user: user, state: state,
            splitDay: splitDay == "Rest" ? "Upper" : splitDay,
            intensity: intensity,
            notes: "AI quick log",
            exercises: [],
            in: context
        )
        user.award(result.totalXP, to: .fitness)
        ChallengeManager.updateProgress(user: user, in: context)
        try? context.save()
        return result.totalXP
    }

    private func logCardio(_ d: [String: Any], user: User) -> Int {
        let sport = d["sport"] as? String ?? "Other"
        let minutes = AIClient.intFromAny(d["durationMinutes"])
        let resolvedMinutes = minutes > 0 ? minutes : 30
        let intensityStr = d["intensity"] as? String ?? "medium"
        let intensity = XPEngine.FitnessIntensity(rawValue: intensityStr) ?? .medium
        let distance = AIClient.doubleFromAny(d["distanceKm"])

        let xp = XPEngine.xpForCardio(intensity: intensity)
        let session = CardioSession(date: .now, type: sport,
                                    durationMinutes: resolvedMinutes,
                                    intensity: intensity,
                                    distanceKm: distance,
                                    notes: "AI quick log",
                                    xpEarned: xp)
        context.insert(session)
        user.award(xp, to: .fitness)
        ChallengeManager.updateProgress(user: user, in: context)
        try? context.save()
        return xp
    }

    private func logLearning(_ d: [String: Any], user: User) throws -> Int {
        let learningType = d["learningType"] as? String ?? "course"
        let name = d["name"] as? String ?? ""
        let minutes = AIClient.intFromAny(d["durationMinutes"])
        let resolvedMinutes = minutes > 0 ? minutes : 30
        let hours = Double(resolvedMinutes) / 60.0
        let xp = hours >= 1 ? XPEngine.xpForStudy1Hour : XPEngine.xpForStudy30Min

        switch learningType {
        case "course":
            guard let course = courses.filter({ !$0.isCompleted })
                .first(where: { $0.name.localizedCaseInsensitiveContains(name) || name.localizedCaseInsensitiveContains($0.name) })
            else { throw LogError.learningNotFound(name) }
            course.totalHours += hours
            course.xpEarned += xp
            if resolvedMinutes >= 30 {
                course.completedLessons = min(course.totalLessons, course.completedLessons + 1)
            }
            user.award(xp, to: .learning)
            context.insert(LearningLog(type: "course", name: course.name, hoursStudied: hours, xpEarned: xp))

        case "book":
            guard let book = books.filter({ !$0.isFinished })
                .first(where: { $0.title.localizedCaseInsensitiveContains(name) || name.localizedCaseInsensitiveContains($0.title) })
            else { throw LogError.learningNotFound(name) }
            let bookXP = 30
            book.totalHours += hours
            book.pagesRead = min(book.totalPages, book.pagesRead + max(1, Int(Double(resolvedMinutes) / 2)))
            book.xpEarned += bookXP
            user.award(bookXP, to: .learning)
            context.insert(LearningLog(type: "book", name: book.title, hoursStudied: hours, xpEarned: bookXP))
            ChallengeManager.updateProgress(user: user, in: context)
            try? context.save()
            return bookXP

        case "certification":
            guard let cert = certifications.filter({ !$0.isEarned })
                .first(where: { $0.name.localizedCaseInsensitiveContains(name) || name.localizedCaseInsensitiveContains($0.name) })
            else { throw LogError.learningNotFound(name) }
            cert.studiedHours += hours
            cert.xpEarned += xp
            user.award(xp, to: .learning)
            context.insert(LearningLog(type: "certification", name: cert.name, hoursStudied: hours, xpEarned: xp))

        default:
            throw LogError.learningNotFound(name)
        }

        ChallengeManager.updateProgress(user: user, in: context)
        try? context.save()
        return xp
    }

    private func logWeight(_ d: [String: Any], user: User) -> Int {
        let kg = AIClient.doubleFromAny(d["weightKg"])
        guard kg > 0 else { return 0 }
        let xp = XPEngine.xpForWeightLog
        let entry = WeightEntry(weightKg: kg, xpEarned: xp)
        context.insert(entry)
        user.award(xp, to: .fitness)
        ChallengeManager.updateProgress(user: user, in: context)
        try? context.save()
        return xp
    }

    private func logTodo(_ d: [String: Any], summary: String) -> Int {
        let title = d["title"] as? String ?? summary
        let item = DailyTodoItem(title: title)
        context.insert(item)
        try? context.save()
        return 0
    }

    private func logFood(_ d: [String: Any], user: User) async throws -> Int {
        let mealType = d["mealType"] as? String ?? "Lunch"
        let description = d["description"] as? String ?? ""
        guard !description.isEmpty else { throw LogError.foodFailed }

        let estimate = try await AIClient.analyzeMeal(description)
        let xp = XPEngine.xpForNutritionLog
        let entry = FoodEntry(
            mealType: mealType, foodName: description,
            calories: estimate.calories, protein: Double(estimate.protein),
            carbs: Double(estimate.carbs), fats: Double(estimate.fats),
            xpEarned: xp
        )
        context.insert(entry)
        user.award(xp, to: .fitness)
        ChallengeManager.updateProgress(user: user, in: context)
        try? context.save()
        return xp
    }

    // MARK: - Context Builder

    private func buildContextString() -> String {
        var parts: [String] = []

        let active = projects.filter { !$0.isArchived }
        if !active.isEmpty {
            parts.append("PROJECTS (active): " + active.map { "\"\($0.name)\"" }.joined(separator: ", "))
        }

        let activeCourses = courses.filter { !$0.isCompleted }
        if !activeCourses.isEmpty {
            parts.append("COURSES (in progress): " + activeCourses.map { "\"\($0.name)\" (\($0.platform))" }.joined(separator: ", "))
        }

        let activeBooks = books.filter { !$0.isFinished }
        if !activeBooks.isEmpty {
            parts.append("BOOKS (reading): " + activeBooks.map { "\"\($0.title)\" by \($0.author)" }.joined(separator: ", "))
        }

        let activeCerts = certifications.filter { !$0.isEarned }
        if !activeCerts.isEmpty {
            parts.append("CERTS (studying): " + activeCerts.map { "\"\($0.name)\" (\($0.issuingBody))" }.joined(separator: ", "))
        }

        let split = GymSplitEngine.plannedSplit(for: .now)
        parts.append("TODAY'S GYM SPLIT: \(split)")
        parts.append("GYM SPLITS: Upper, Lower, Push, Pull, Legs")
        parts.append("CARDIO/SPORT TYPES: Run, Swim, Cycle, HIIT, Yoga, Walk, Cricket, Football, Basketball, Tennis, Other")
        parts.append("WORK ACTION TYPES: " + WorkEntry.actionTypes.joined(separator: ", "))

        return parts.joined(separator: "\n")
    }
}
