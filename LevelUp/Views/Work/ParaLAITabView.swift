//
//  ParaLAITabView.swift
//  LEVEL UP — Phase 2
//
//  ParaLAI milestone tracker + entry log. Seeds 10 default milestones
//  on first appearance. Ticking a milestone awards +300 XP exactly once.
//

import SwiftUI
import SwiftData

struct ParaLAITabView: View {

    let user: User
    let vm: WorkViewModel

    @Environment(\.modelContext) private var context

    // Entry form
    @State private var actionType: String = "Feature Built"
    @State private var title: String = ""
    @State private var detail: String = ""
    @State private var hoursText: String = ""
    @State private var toast: String?

    private let actionTypes = ["Feature Built", "Bug Fixed", "Milestone Shipped",
                               "Meeting", "Research", "Other"]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            progressCard
            milestonesCard
            logCard
            entriesCard
        }
        .onAppear(perform: seedMilestonesIfNeeded)
    }

    // MARK: - Progress card

    private var progressCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PARALAI ROADMAP")
                            .font(.caption).fontWeight(.heavy).tracking(2)
                            .foregroundStyle(Theme.textSecondary)
                        Text("\(vm.completedMilestoneCount) / \(vm.totalMilestoneCount) milestones")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(Theme.secondaryAccent)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("HOURS LOGGED")
                            .font(.caption).fontWeight(.heavy).tracking(2)
                            .foregroundStyle(Theme.textSecondary)
                        Text("\(vm.totalParaLAIHours, specifier: "%.1f")")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                ProgressBar(progress: vm.milestoneProgress, color: Theme.secondaryAccent)
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Milestones

    private var milestonesCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("MILESTONES")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)
                ForEach(vm.orderedMilestones) { m in
                    milestoneRow(m)
                }
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func milestoneRow(_ m: ParaLAIMilestone) -> some View {
        Button {
            toggle(m)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: m.isCompleted ? "checkmark.seal.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(m.isCompleted ? Theme.xpGreen : Theme.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(m.name)
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(m.isCompleted ? Theme.textPrimary : Theme.textSecondary)
                    if let at = m.completedAt {
                        Text("Shipped \(at.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                Spacer()
                if m.isCompleted {
                    Text("+\(XPEngine.xpForParaLAIMilestone) XP")
                        .font(.caption).fontWeight(.heavy)
                        .foregroundStyle(Theme.xpGreen)
                }
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Log form

    private var logCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("LOG PARALAI WORK")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.secondaryAccent)

                Picker("Type", selection: $actionType) {
                    ForEach(actionTypes, id: \.self) { Text($0) }
                }
                .pickerStyle(.menu)

                TextField("Title (what did you do?)", text: $title)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Theme.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.cardBorder, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                TextField("Detail (optional)", text: $detail)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Theme.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.cardBorder, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                TextField("Hours spent", text: $hoursText)
                    .textFieldStyle(.plain)
                    .frame(width: 160)
                    .padding(10)
                    .background(Theme.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.cardBorder, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                HStack {
                    Button("Log Entry", action: submit)
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.secondaryAccent)
                        .foregroundStyle(Color.black)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                    if let toast {
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

    // MARK: - Entries list

    private var entriesCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("RECENT ENTRIES")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)
                if vm.recentEntries.isEmpty {
                    Text("Nothing logged yet.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    ForEach(vm.recentEntries) { e in
                        HStack(spacing: 12) {
                            Image(systemName: iconFor(e.actionType))
                                .foregroundStyle(Theme.secondaryAccent)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(e.title)
                                    .font(.subheadline).fontWeight(.semibold)
                                    .foregroundStyle(Theme.textPrimary)
                                Text("\(e.actionType) · \(e.hoursSpent, specifier: "%.1f")h · \(e.date.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            Text("+\(e.xpEarned) XP")
                                .font(.caption).fontWeight(.heavy)
                                .foregroundStyle(Theme.xpGreen)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func iconFor(_ type: String) -> String {
        switch type {
        case "Feature Built":     return "hammer.fill"
        case "Bug Fixed":         return "ant.fill"
        case "Milestone Shipped": return "shippingbox.fill"
        case "Meeting":           return "person.2.fill"
        case "Research":          return "magnifyingglass"
        default:                  return "circle.fill"
        }
    }

    // MARK: - Actions

    private func submit() {
        let name = title.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let xp: Int
        switch actionType {
        case "Feature Built": xp = XPEngine.xpForParaLAIFeature
        case "Bug Fixed":     xp = XPEngine.xpForParaLAIBug
        default:              xp = 50
        }
        let entry = ParaLAIEntry(date: .now,
                                 actionType: actionType,
                                 title: name,
                                 detail: detail,
                                 hoursSpent: Double(hoursText) ?? 0,
                                 xpEarned: xp)
        context.insert(entry)
        user.award(xp, to: .work)
        try? context.save()

        let newly = UnlockEngine.evaluateUnlocks(user: user, context: context)
        UnlockCenter.shared.present(newly)

        toast = "+\(xp) XP"
        title = ""
        detail = ""
        hoursText = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { toast = nil }
    }

    private func toggle(_ m: ParaLAIMilestone) {
        if !m.isCompleted {
            m.isCompleted = true
            m.completedAt = .now
            if !m.xpAwarded {
                user.award(XPEngine.xpForParaLAIMilestone, to: .work)
                m.xpAwarded = true
            }
        } else {
            // Untoggle is non-destructive: keeps the XP already awarded.
            m.isCompleted = false
            m.completedAt = nil
        }
        try? context.save()
        let newly = UnlockEngine.evaluateUnlocks(user: user, context: context)
        UnlockCenter.shared.present(newly)
    }

    // MARK: - Seed

    private func seedMilestonesIfNeeded() {
        guard vm.orderedMilestones.isEmpty else { return }
        let names: [String] = [
            "Landing page live",
            "Auth + onboarding",
            "Case intake MVP",
            "Document parsing pipeline",
            "First paying firm",
            "Mobile companion",
            "Multi-user workspaces",
            "Billing + invoicing",
            "10 paying firms",
            "Series A ready"
        ]
        for (i, name) in names.enumerated() {
            context.insert(ParaLAIMilestone(name: name, orderIndex: i))
        }
        try? context.save()
    }
}
