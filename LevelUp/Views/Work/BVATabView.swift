//
//  BVATabView.swift
//  LEVEL UP — Phase 2
//
//  BVA deal pipeline. Add deals, progress stages, close won/lost. Each
//  stage advance grants 75 XP; closing won grants 500 XP. Overdue
//  next-actions get a red badge.
//

import SwiftUI
import SwiftData

struct BVATabView: View {

    let user: User
    let vm: WorkViewModel

    @Environment(\.modelContext) private var context

    // Form state
    @State private var showingAdd = false
    @State private var newName: String = ""
    @State private var newCompany: String = ""
    @State private var newSize: String = ""
    @State private var newStage: String = "Prospecting"
    @State private var newType: String = "Growth Capital"
    @State private var newAction: String = ""
    @State private var newDue: Date = .now
    @State private var useDue: Bool = false

    static let stages = ["Prospecting", "Initial Contact", "Due Diligence",
                         "Term Sheet", "Closing"]
    static let dealTypes = ["Growth Capital", "Debt Structuring",
                            "M&A Advisory", "Private Credit", "Deal Structuring"]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            statsRow
            actionsRow
            pipelineCard
            closedCard
        }
        .sheet(isPresented: $showingAdd) { addSheet }
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 16) {
            statCard(label: "PIPELINE",
                     value: String(format: "$%.1fM", vm.pipelineValueMillion),
                     subtitle: "\(vm.openDeals.count) active",
                     color: Theme.secondaryAccent)
            statCard(label: "CLOSED WON",
                     value: String(format: "$%.1fM", vm.wonValueMillion),
                     subtitle: "\(vm.deals.filter { $0.isClosedWon }.count) deals",
                     color: Theme.xpGreen)
            statCard(label: "OVERDUE",
                     value: "\(vm.overdueDeals.count)",
                     subtitle: "next actions",
                     color: .red)
        }
    }

    private func statCard(label: String, value: String, subtitle: String, color: Color) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)
                Text(value)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(color)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Actions row

    private var actionsRow: some View {
        HStack {
            Button {
                resetAddForm()
                showingAdd = true
            } label: {
                Label("Add Deal", systemImage: "plus.circle.fill")
                    .font(.subheadline).fontWeight(.semibold)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Theme.secondaryAccent.opacity(0.14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.secondaryAccent.opacity(0.55), lineWidth: 1)
                    )
                    .foregroundStyle(Theme.secondaryAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    // MARK: - Pipeline

    private var pipelineCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("ACTIVE PIPELINE")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)
                if vm.openDeals.isEmpty {
                    Text("No active deals. Add one to get started.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    ForEach(vm.openDeals) { deal in
                        dealRow(deal)
                    }
                }
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func dealRow(_ deal: Deal) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(deal.dealName)
                            .font(.headline).fontWeight(.bold)
                            .foregroundStyle(Theme.textPrimary)
                        if deal.isOverdue {
                            Text("OVERDUE")
                                .font(.caption2).fontWeight(.heavy).tracking(1)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.red.opacity(0.2))
                                .foregroundStyle(.red)
                                .clipShape(Capsule())
                        }
                    }
                    Text("\(deal.companyName) · \(deal.dealType)")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Text("$\(deal.dealSizeMillion, specifier: "%.1f")M")
                    .font(.subheadline).fontWeight(.heavy).monospacedDigit()
                    .foregroundStyle(Theme.secondaryAccent)
            }

            HStack(spacing: 6) {
                ForEach(Array(Self.stages.enumerated()), id: \.offset) { idx, s in
                    let current = Self.stages.firstIndex(of: deal.stage) ?? 0
                    RoundedRectangle(cornerRadius: 3)
                        .fill(idx <= current ? Theme.secondaryAccent : Theme.cardBorder)
                        .frame(height: 6)
                }
            }
            HStack {
                Text(deal.stage.uppercased())
                    .font(.caption2).fontWeight(.heavy).tracking(1)
                    .foregroundStyle(Theme.secondaryAccent)
                Spacer()
                if !deal.nextAction.isEmpty {
                    Text("Next: \(deal.nextAction)")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            HStack(spacing: 8) {
                Button("Advance Stage") { advance(deal) }
                    .buttonStyle(.bordered)
                    .tint(Theme.secondaryAccent)
                    .disabled(deal.stage == Self.stages.last)
                Button("Close Won") { close(deal, won: true) }
                    .buttonStyle(.bordered)
                    .tint(Theme.xpGreen)
                Button("Close Lost") { close(deal, won: false) }
                    .buttonStyle(.bordered)
                    .tint(.red)
                Spacer()
            }
            .font(.caption)
        }
        .padding(12)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Closed list

    private var closedCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text("CLOSED")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)
                if vm.closedDeals.isEmpty {
                    Text("None yet.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    ForEach(vm.closedDeals) { deal in
                        HStack {
                            Image(systemName: deal.isClosedWon ? "checkmark.seal.fill" : "xmark.seal.fill")
                                .foregroundStyle(deal.isClosedWon ? Theme.xpGreen : .red)
                            Text(deal.dealName)
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text("$\(deal.dealSizeMillion, specifier: "%.1f")M")
                                .font(.caption).monospacedDigit()
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .padding(.vertical, 3)
                    }
                }
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Add sheet

    private var addSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("NEW DEAL")
                .font(.title2).fontWeight(.black).tracking(3)
                .foregroundStyle(Theme.textPrimary)

            field("Deal Name", text: $newName)
            field("Company", text: $newCompany)
            field("Size ($M)", text: $newSize)

            Picker("Stage", selection: $newStage) {
                ForEach(Self.stages, id: \.self) { Text($0) }
            }
            Picker("Type", selection: $newType) {
                ForEach(Self.dealTypes, id: \.self) { Text($0) }
            }

            field("Next Action", text: $newAction)
            Toggle("Set due date", isOn: $useDue)
            if useDue {
                DatePicker("Due", selection: $newDue, displayedComponents: .date)
            }

            HStack {
                Button("Cancel") { showingAdd = false }
                Spacer()
                Button("Add Deal", action: addDeal)
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.secondaryAccent)
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty
                              || Double(newSize) == nil)
            }
        }
        .padding(32)
        .frame(minWidth: 420, minHeight: 540)
        .background(Theme.background)
    }

    private func field(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(Theme.textSecondary)
            TextField(label, text: text)
                .textFieldStyle(.plain)
                .padding(10)
                .background(Theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Theme.cardBorder, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    // MARK: - Actions

    private func resetAddForm() {
        newName = ""
        newCompany = ""
        newSize = ""
        newStage = "Prospecting"
        newType = "Growth Capital"
        newAction = ""
        newDue = .now
        useDue = false
    }

    private func addDeal() {
        guard let size = Double(newSize) else { return }
        let deal = Deal(dealName: newName.trimmingCharacters(in: .whitespaces),
                        companyName: newCompany,
                        dealSizeMillion: size,
                        stage: newStage,
                        dealType: newType,
                        nextAction: newAction,
                        nextActionDue: useDue ? newDue : nil)
        context.insert(deal)
        user.award(XPEngine.xpForBVADealAdded, to: .work)
        deal.xpEarned += XPEngine.xpForBVADealAdded
        try? context.save()

        let newly = UnlockEngine.evaluateUnlocks(user: user, context: context)
        UnlockCenter.shared.present(newly)
        showingAdd = false
    }

    private func advance(_ deal: Deal) {
        guard let idx = Self.stages.firstIndex(of: deal.stage),
              idx + 1 < Self.stages.count else { return }
        deal.stage = Self.stages[idx + 1]
        deal.updatedAt = .now
        deal.xpEarned += XPEngine.xpForBVADealStageUpdate
        user.award(XPEngine.xpForBVADealStageUpdate, to: .work)
        try? context.save()
        let newly = UnlockEngine.evaluateUnlocks(user: user, context: context)
        UnlockCenter.shared.present(newly)
    }

    private func close(_ deal: Deal, won: Bool) {
        deal.isClosedWon = won
        deal.isClosedLost = !won
        deal.updatedAt = .now
        if won {
            let xp = XPEngine.xpForBVADealClosed
            deal.xpEarned += xp
            user.award(xp, to: .work)
            // Personal record: biggest deal by dollar value.
            let valueUSD = deal.dealSizeMillion * 1_000_000
            PersonalRecordsEngine.evaluateDealClose(valueUSD: valueUSD,
                                                    dealName: deal.dealName,
                                                    in: context)
        }
        try? context.save()
        let newly = UnlockEngine.evaluateUnlocks(user: user, context: context)
        UnlockCenter.shared.present(newly)
    }
}
