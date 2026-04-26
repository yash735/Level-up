import SwiftUI
import SwiftData

struct ProjectTabView: View {

    let user: User
    let project: Project

    @Environment(\.modelContext) private var context

    @Query private var allMilestones: [ProjectMilestone]
    @Query(sort: \WorkEntry.date, order: .reverse) private var allEntries: [WorkEntry]

    @State private var actionType = "Deep Work"
    @State private var title = ""
    @State private var detail = ""
    @State private var hoursText = ""
    @State private var toast: String?

    @State private var newMilestoneText = ""
    @State private var isAddingMilestone = false
    @State private var isGeneratingMilestones = false
    @State private var aiError: String?

    private var milestones: [ProjectMilestone] {
        allMilestones
            .filter { $0.project?.id == project.id }
            .sorted { $0.orderIndex < $1.orderIndex }
    }

    private var entries: [WorkEntry] {
        allEntries.filter { $0.project?.id == project.id }
    }

    private var recentEntries: [WorkEntry] {
        Array(entries.prefix(10))
    }

    private var totalHours: Double {
        entries.reduce(0) { $0 + $1.hoursSpent }
    }

    private var totalXP: Int {
        entries.reduce(0) { $0 + $1.xpEarned }
            + milestones.filter { $0.xpAwarded }.count * XPEngine.xpForProjectMilestone
    }

    private var completedMilestones: Int {
        milestones.filter { $0.isCompleted }.count
    }

    private var entriesThisWeek: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return entries.filter { $0.date >= weekAgo }.count
    }

    private var projectColor: Color {
        Color(hex: project.colorHex) ?? Theme.secondaryAccent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            statsRow
            milestonesCard
            logCard
            recentCard
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 14) {
            statCell("HOURS", value: String(format: "%.1f", totalHours), color: Theme.textPrimary)
            statCell("XP EARNED", value: totalXP.formatted(), color: Theme.xpGreen)
            statCell("MILESTONES", value: "\(completedMilestones)/\(milestones.count)", color: Theme.xpGold)
            statCell("THIS WEEK", value: "\(entriesThisWeek)", color: projectColor)
        }
    }

    private func statCell(_ label: String, value: String, color: Color) -> some View {
        Card {
            VStack(spacing: 6) {
                Text(label)
                    .font(.caption2).fontWeight(.heavy).tracking(1)
                    .foregroundStyle(Theme.textSecondary)
                Text(value)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(color)
                    .monospacedDigit()
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Milestones

    private var milestonesCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("MILESTONES")
                        .font(.caption).fontWeight(.heavy).tracking(2)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    if isGeneratingMilestones {
                        ProgressView()
                            .controlSize(.small)
                            .tint(projectColor)
                    }
                }

                if milestones.isEmpty && !isAddingMilestone {
                    VStack(spacing: 12) {
                        Text("No milestones yet.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                        HStack(spacing: 12) {
                            Button { generateMilestones() } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                    Text("Generate with AI")
                                }
                                .font(.subheadline).fontWeight(.semibold)
                                .padding(.horizontal, 16).padding(.vertical, 8)
                                .background(projectColor.opacity(0.15))
                                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(projectColor.opacity(0.5), lineWidth: 1))
                                .foregroundStyle(projectColor)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .disabled(isGeneratingMilestones)

                            Button { isAddingMilestone = true } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus")
                                    Text("Add Manually")
                                }
                                .font(.subheadline).fontWeight(.semibold)
                                .padding(.horizontal, 16).padding(.vertical, 8)
                                .background(Theme.cardBorder.opacity(0.3))
                                .foregroundStyle(Theme.textSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                } else {
                    ForEach(milestones) { m in
                        milestoneRow(m)
                    }

                    if isAddingMilestone {
                        HStack(spacing: 10) {
                            Image(systemName: "circle")
                                .font(.title3)
                                .foregroundStyle(Theme.textSecondary)
                            TextField("New milestone...", text: $newMilestoneText)
                                .textFieldStyle(.plain)
                                .font(.subheadline)
                                .foregroundStyle(Theme.textPrimary)
                                .onSubmit { commitNewMilestone() }
                            Button("Add") { commitNewMilestone() }
                                .font(.caption).fontWeight(.semibold)
                                .foregroundStyle(projectColor)
                                .buttonStyle(.plain)
                                .disabled(newMilestoneText.trimmingCharacters(in: .whitespaces).isEmpty)
                            Button("Cancel") {
                                isAddingMilestone = false
                                newMilestoneText = ""
                            }
                            .font(.caption).foregroundStyle(Theme.textSecondary)
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }

                    HStack(spacing: 12) {
                        Button { isAddingMilestone = true } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle")
                                Text("Add")
                            }
                            .font(.caption).fontWeight(.semibold)
                            .foregroundStyle(Theme.textSecondary)
                        }
                        .buttonStyle(.plain)
                        .disabled(isAddingMilestone)

                        Button { generateMilestones() } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                Text("Generate with AI")
                            }
                            .font(.caption).fontWeight(.semibold)
                            .foregroundStyle(projectColor)
                        }
                        .buttonStyle(.plain)
                        .disabled(isGeneratingMilestones)
                    }
                }

                if let aiError {
                    Text(aiError)
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.8))
                }
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func milestoneRow(_ m: ProjectMilestone) -> some View {
        Button { toggleMilestone(m) } label: {
            HStack(spacing: 14) {
                Image(systemName: m.isCompleted ? "checkmark.seal.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(m.isCompleted ? Theme.xpGreen : Theme.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(m.title)
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundStyle(m.isCompleted ? Theme.textPrimary : Theme.textSecondary)
                        if m.isAISuggested {
                            Image(systemName: "sparkles")
                                .font(.caption2)
                                .foregroundStyle(projectColor.opacity(0.6))
                        }
                    }
                    if let at = m.completedAt {
                        Text("Completed \(at.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                Spacer()
                if m.isCompleted && m.xpAwarded {
                    Text("+\(XPEngine.xpForProjectMilestone) XP")
                        .font(.caption).fontWeight(.heavy)
                        .foregroundStyle(Theme.xpGreen)
                } else if !m.isCompleted {
                    Text("+\(XPEngine.xpForProjectMilestone) XP")
                        .font(.caption).fontWeight(.heavy)
                        .foregroundStyle(Theme.xpGold.opacity(0.6))
                }
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Log Work

    private var logCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("LOG WORK")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(projectColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text("ACTION TYPE")
                        .font(.caption2).fontWeight(.heavy).tracking(1)
                        .foregroundStyle(Theme.textSecondary)
                    HStack(spacing: 8) {
                        ForEach(WorkEntry.actionTypes, id: \.self) { type in
                            Button { actionType = type } label: {
                                Text(type)
                                    .font(.caption).fontWeight(.semibold)
                                    .padding(.horizontal, 12).padding(.vertical, 7)
                                    .foregroundStyle(actionType == type ? projectColor : Theme.textSecondary)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(actionType == type ? projectColor.opacity(0.14) : Color.clear)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(actionType == type ? projectColor.opacity(0.55) : Theme.cardBorder,
                                                    lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                formField("TITLE", placeholder: "What did you do?", text: $title)

                VStack(alignment: .leading, spacing: 4) {
                    Text("DETAIL (OPTIONAL)")
                        .font(.caption2).fontWeight(.heavy).tracking(1)
                        .foregroundStyle(Theme.textSecondary)
                    TextField("Details...", text: $detail, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(3...6)
                        .padding(10)
                        .background(Theme.background)
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.cardBorder, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("HOURS SPENT")
                            .font(.caption2).fontWeight(.heavy).tracking(1)
                            .foregroundStyle(Theme.textSecondary)
                        HStack(spacing: 6) {
                            TextField("e.g. 1.5", text: $hoursText)
                                .textFieldStyle(.plain)
                                .font(.subheadline)
                                .foregroundStyle(Theme.textPrimary)
                                .padding(10)
                                .background(Theme.background)
                                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Theme.cardBorder, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .frame(width: 100)
                            Stepper("", value: Binding(
                                get: { Double(hoursText) ?? 0 },
                                set: { hoursText = String(format: "%.1f", max(0, $0)) }
                            ), in: 0...24, step: 0.5)
                            .labelsHidden()
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        if actionType == "Deep Work" {
                            Text("\(Int(Double(WorkEntry.xpRate(for: actionType)) * 1.5)) XP/hr")
                                .font(.caption2).fontWeight(.heavy)
                                .foregroundStyle(Theme.xpGold)
                            Text("1.5x Deep Work")
                                .font(.caption2)
                                .foregroundStyle(Theme.xpGold.opacity(0.7))
                        } else {
                            Text("\(WorkEntry.xpRate(for: actionType)) XP/hr")
                                .font(.caption2).fontWeight(.heavy)
                                .foregroundStyle(projectColor)
                        }
                    }

                    Spacer()

                    if let hours = Double(hoursText), hours > 0 {
                        Text("+\(WorkEntry.calculateXP(hours: hours, actionType: actionType)) XP")
                            .font(.subheadline).fontWeight(.heavy)
                            .foregroundStyle(projectColor)
                            .monospacedDigit()
                    }

                    Button(action: submitEntry) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("Log")
                        }
                        .font(.subheadline).fontWeight(.semibold)
                        .padding(.horizontal, 18).padding(.vertical, 10)
                        .background(projectColor.opacity(0.15))
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(projectColor.opacity(0.5), lineWidth: 1))
                        .foregroundStyle(projectColor)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty
                              || Double(hoursText) == nil)
                }

                if let toast {
                    Text(toast)
                        .font(.caption).fontWeight(.semibold)
                        .foregroundStyle(Theme.xpGreen)
                        .transition(.opacity)
                }
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func formField(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2).fontWeight(.heavy).tracking(1)
                .foregroundStyle(Theme.textSecondary)
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .foregroundStyle(Theme.textPrimary)
                .padding(10)
                .background(Theme.background)
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Theme.cardBorder, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    // MARK: - Recent Entries

    private var recentCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("RECENT")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)

                if recentEntries.isEmpty {
                    Text("Nothing logged yet.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    ForEach(recentEntries) { e in
                        HStack(spacing: 12) {
                            Text(e.actionType)
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .padding(.horizontal, 6).padding(.vertical, 3)
                                .background(projectColor.opacity(0.15))
                                .foregroundStyle(projectColor)
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                .frame(width: 72)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(e.title)
                                    .font(.subheadline).fontWeight(.semibold)
                                    .foregroundStyle(Theme.textPrimary)
                                Text("\(e.hoursSpent, specifier: "%.1f")h \u{00B7} \(e.date.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            Text("+\(e.xpEarned) XP")
                                .font(.caption).fontWeight(.heavy)
                                .foregroundStyle(Theme.xpGreen)
                                .monospacedDigit()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Actions

    private func submitEntry() {
        guard let hours = Double(hoursText), hours > 0 else { return }
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let xp = WorkEntry.calculateXP(hours: hours, actionType: actionType)
        let entry = WorkEntry(project: project,
                              actionType: actionType,
                              title: trimmed,
                              detail: detail,
                              hoursSpent: hours,
                              xpEarned: xp)
        context.insert(entry)
        user.award(xp, to: .work)
        try? context.save()

        ChallengeManager.updateProgress(user: user, in: context)
        let newly = UnlockEngine.evaluateUnlocks(user: user, context: context)
        UnlockCenter.shared.present(newly)

        toast = "+\(xp) XP"
        title = ""
        detail = ""
        hoursText = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { toast = nil }
    }

    private func toggleMilestone(_ m: ProjectMilestone) {
        if !m.isCompleted {
            m.isCompleted = true
            m.completedAt = .now
            if !m.xpAwarded {
                user.award(XPEngine.xpForProjectMilestone, to: .work)
                m.xpAwarded = true
            }
        } else {
            m.isCompleted = false
            m.completedAt = nil
        }
        try? context.save()
        let newly = UnlockEngine.evaluateUnlocks(user: user, context: context)
        UnlockCenter.shared.present(newly)
    }

    private func commitNewMilestone() {
        let text = newMilestoneText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        let milestone = ProjectMilestone(project: project,
                                         title: text,
                                         orderIndex: milestones.count)
        context.insert(milestone)
        try? context.save()
        newMilestoneText = ""
        isAddingMilestone = false
    }

    private func generateMilestones() {
        isGeneratingMilestones = true
        aiError = nil
        Task {
            do {
                let titles = try await AIClient.generateMilestones(
                    projectName: project.name,
                    description: project.projectDescription
                )
                let startIndex = milestones.count
                for (i, t) in titles.enumerated() {
                    let m = ProjectMilestone(project: project,
                                             title: t,
                                             isAISuggested: true,
                                             orderIndex: startIndex + i)
                    context.insert(m)
                }
                try? context.save()
            } catch {
                aiError = error.localizedDescription
            }
            isGeneratingMilestones = false
        }
    }
}
