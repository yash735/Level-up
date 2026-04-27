import SwiftUI
import SwiftData

struct QuickTasksTabView: View {

    let user: User

    @Environment(\.modelContext) private var context
    @Query(sort: \WorkEntry.date, order: .reverse) private var allEntries: [WorkEntry]
    @Query(sort: \DailyTodoItem.orderIndex) private var allTodoItems: [DailyTodoItem]

    @State private var actionType = "Admin"
    @State private var title = ""
    @State private var hoursText = ""
    @State private var toast: String?
    @State private var newTodoTitle = ""

    private let tint = Theme.secondaryAccent

    private var entries: [WorkEntry] {
        allEntries.filter { $0.project == nil }
    }

    private var recentEntries: [WorkEntry] {
        Array(entries.prefix(15))
    }

    private var totalHours: Double {
        entries.reduce(0) { $0 + $1.hoursSpent }
    }

    private var totalXP: Int {
        entries.reduce(0) { $0 + $1.xpEarned }
    }

    private var todayItems: [DailyTodoItem] {
        let start = Calendar.current.startOfDay(for: .now)
        return allTodoItems.filter { $0.date == start }
    }

    private var todayCompletedCount: Int {
        todayItems.filter(\.isCompleted).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            statsRow
            todayTasksCard
            logCard
            recentCard
        }
        .onAppear(perform: rolloverIncompleteTasks)
    }

    // MARK: - Stats

    private var statsRow: some View {
        Card {
            HStack(spacing: 24) {
                stat("TASKS", "\(entries.count)")
                stat("HOURS", String(format: "%.1f", totalHours))
                stat("XP EARNED", totalXP.formatted())
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2).fontWeight(.heavy).tracking(1)
                .foregroundStyle(Theme.textSecondary)
            Text(value)
                .font(.title3).fontWeight(.heavy).monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
        }
    }

    // MARK: - Log

    private var logCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("LOG TASK")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(tint)

                VStack(alignment: .leading, spacing: 4) {
                    Text("TYPE")
                        .font(.caption2).fontWeight(.heavy).tracking(1)
                        .foregroundStyle(Theme.textSecondary)
                    HStack(spacing: 8) {
                        ForEach(WorkEntry.actionTypes, id: \.self) { type in
                            Button { actionType = type } label: {
                                Text(type)
                                    .font(.caption).fontWeight(.semibold)
                                    .padding(.horizontal, 12).padding(.vertical, 7)
                                    .foregroundStyle(actionType == type ? tint : Theme.textSecondary)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(actionType == type ? tint.opacity(0.14) : Color.clear)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(actionType == type ? tint.opacity(0.55) : Theme.cardBorder,
                                                    lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("WHAT DID YOU DO?")
                        .font(.caption2).fontWeight(.heavy).tracking(1)
                        .foregroundStyle(Theme.textSecondary)
                    TextField("e.g. Filed taxes, paid lawyer fees", text: $title)
                        .textFieldStyle(.plain)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textPrimary)
                        .padding(10)
                        .background(Theme.background)
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.cardBorder, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("HOURS")
                            .font(.caption2).fontWeight(.heavy).tracking(1)
                            .foregroundStyle(Theme.textSecondary)
                        HStack(spacing: 6) {
                            TextField("e.g. 0.5", text: $hoursText)
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

                    Spacer()

                    if let hours = Double(hoursText), hours > 0 {
                        Text("+\(WorkEntry.calculateXP(hours: hours, actionType: actionType)) XP")
                            .font(.subheadline).fontWeight(.heavy)
                            .foregroundStyle(tint)
                            .monospacedDigit()
                    }

                    Button(action: submitEntry) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("Log")
                        }
                        .font(.subheadline).fontWeight(.semibold)
                        .padding(.horizontal, 18).padding(.vertical, 10)
                        .background(tint.opacity(0.15))
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(tint.opacity(0.5), lineWidth: 1))
                        .foregroundStyle(tint)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty
                              || (Double(hoursText) ?? 0) <= 0)
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

    // MARK: - Recent

    private var recentCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("RECENT")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)

                if recentEntries.isEmpty {
                    Text("No tasks logged yet.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    ForEach(recentEntries) { e in
                        HStack(spacing: 12) {
                            Text(e.actionType)
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .padding(.horizontal, 6).padding(.vertical, 3)
                                .background(tint.opacity(0.15))
                                .foregroundStyle(tint)
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

    // MARK: - Today's Tasks

    private var todayTasksCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("TODAY'S TASKS")
                        .font(.caption).fontWeight(.heavy).tracking(2)
                        .foregroundStyle(tint)
                    Spacer()
                    if !todayItems.isEmpty {
                        let allDone = todayCompletedCount == todayItems.count
                        Text("\(todayCompletedCount)/\(todayItems.count)")
                            .font(.caption).fontWeight(.heavy).monospacedDigit()
                            .foregroundStyle(allDone ? Theme.xpGreen : Theme.textSecondary)
                    }
                }

                ForEach(todayItems) { item in
                    Button {
                        item.isCompleted.toggle()
                        try? context.save()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(item.isCompleted ? Theme.xpGreen : Theme.textSecondary)
                            Text(item.title)
                                .font(.subheadline).fontWeight(.medium)
                                .foregroundStyle(item.isCompleted ? Theme.textSecondary : Theme.textPrimary)
                                .strikethrough(item.isCompleted, color: Theme.textSecondary)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteTodoItem(item)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }

                HStack(spacing: 8) {
                    TextField("Add a task...", text: $newTodoTitle)
                        .textFieldStyle(.plain)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textPrimary)
                        .padding(10)
                        .background(Theme.background)
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.cardBorder, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .onSubmit { addTodoItem() }

                    Button(action: addTodoItem) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(newTodoTitle.trimmingCharacters(in: .whitespaces).isEmpty
                                             ? Theme.textSecondary.opacity(0.3) : tint)
                    }
                    .buttonStyle(.plain)
                    .disabled(newTodoTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func addTodoItem() {
        let trimmed = newTodoTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let item = DailyTodoItem(title: trimmed, orderIndex: todayItems.count)
        context.insert(item)
        try? context.save()
        newTodoTitle = ""
    }

    private func deleteTodoItem(_ item: DailyTodoItem) {
        context.delete(item)
        try? context.save()
    }

    private func rolloverIncompleteTasks() {
        let today = Calendar.current.startOfDay(for: .now)
        let stale = allTodoItems.filter { $0.date < today && !$0.isCompleted }
        for item in stale {
            item.date = today
        }
        if !stale.isEmpty { try? context.save() }
    }

    // MARK: - Actions

    private func submitEntry() {
        guard let hours = Double(hoursText), hours > 0 else { return }
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let xp = WorkEntry.calculateXP(hours: hours, actionType: actionType)
        let entry = WorkEntry(actionType: actionType,
                              title: trimmed,
                              hoursSpent: hours,
                              xpEarned: xp)
        context.insert(entry)
        user.award(xp, to: .work)
        ChallengeManager.updateProgress(user: user, in: context)
        try? context.save()

        let newly = UnlockEngine.evaluateUnlocks(user: user, context: context)
        UnlockCenter.shared.present(newly)

        toast = "+\(xp) XP"
        title = ""
        hoursText = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { toast = nil }
    }
}
