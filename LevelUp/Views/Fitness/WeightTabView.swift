//
//  WeightTabView.swift
//  LEVEL UP — Phase 2
//
//  Weight logging with a Swift Charts line chart. Top card shows
//  latest weight + delta vs first entry. Middle is a log form.
//  Bottom is the history list.
//

import SwiftUI
import SwiftData
import Charts

struct WeightTabView: View {

    let user: User
    let vm: FitnessViewModel

    @Environment(\.modelContext) private var context

    @State private var weightText: String = ""
    @State private var notesText: String = ""
    @State private var toast: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            summaryCard
            chartCard
            logCard
            historyCard
        }
    }

    // MARK: - Summary

    private var summaryCard: some View {
        Card {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LATEST")
                        .font(.caption).fontWeight(.heavy).tracking(2)
                        .foregroundStyle(Theme.textSecondary)
                    if let latest = vm.latestWeight {
                        Text("\(latest.weightKg, specifier: "%.1f") kg")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundStyle(Theme.xpGreen)
                        Text(latest.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    } else {
                        Text("—")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                Spacer()
                if let delta = vm.weightDelta {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("CHANGE")
                            .font(.caption).fontWeight(.heavy).tracking(2)
                            .foregroundStyle(Theme.textSecondary)
                        let up = delta >= 0
                        Text("\(up ? "+" : "")\(delta, specifier: "%.1f") kg")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(up ? Theme.primaryAccent : Theme.xpGreen)
                        Text("since first entry")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .padding(Theme.cardPadding)
        }
    }

    // MARK: - Chart

    private var chartCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("TREND")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)

                if vm.weightSeries.count < 2 {
                    Text("Log at least 2 entries to see the trend.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 200, alignment: .center)
                } else {
                    Chart(vm.weightSeries) { entry in
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("kg", entry.weightKg)
                        )
                        .foregroundStyle(Theme.xpGreen)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Date", entry.date),
                            y: .value("kg", entry.weightKg)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.xpGreen.opacity(0.35), .clear],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", entry.date),
                            y: .value("kg", entry.weightKg)
                        )
                        .foregroundStyle(Theme.xpGreen)
                    }
                    .frame(height: 240)
                    .chartXAxis {
                        AxisMarks(values: .automatic) { _ in
                            AxisValueLabel().foregroundStyle(Theme.textSecondary)
                            AxisGridLine().foregroundStyle(Theme.cardBorder)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisValueLabel().foregroundStyle(Theme.textSecondary)
                            AxisGridLine().foregroundStyle(Theme.cardBorder)
                        }
                    }
                }
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Log

    private var logCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("LOG WEIGHT")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.xpGreen)

                HStack(spacing: 8) {
                    TextField("Weight (kg)", text: $weightText)
                        .textFieldStyle(.plain)
                        .frame(width: 160)
                        .padding(10)
                        .background(Theme.background)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Theme.cardBorder, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    TextField("Notes", text: $notesText)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(Theme.background)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Theme.cardBorder, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                HStack {
                    Button("Log Weight", action: submit)
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.xpGreen)
                        .foregroundStyle(Color.black)
                        .disabled(Double(weightText) == nil)
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

    // MARK: - History

    private var historyCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("HISTORY")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)
                let recent = vm.weightEntries.sorted { $0.date > $1.date }.prefix(6)
                if recent.isEmpty {
                    Text("No entries yet.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    ForEach(Array(recent)) { entry in
                        HStack {
                            Text("\(entry.weightKg, specifier: "%.1f") kg")
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundStyle(Theme.textPrimary)
                            if !entry.notes.isEmpty {
                                Text("· \(entry.notes)")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Action

    private func submit() {
        guard let kg = Double(weightText) else { return }
        let entry = WeightEntry(date: .now,
                                weightKg: kg,
                                notes: notesText,
                                xpEarned: XPEngine.xpForWeightLog)
        context.insert(entry)
        user.award(XPEngine.xpForWeightLog, to: .fitness)
        try? context.save()

        let newly = UnlockEngine.evaluateUnlocks(user: user, context: context)
        UnlockCenter.shared.present(newly)

        toast = "+\(XPEngine.xpForWeightLog) XP"
        weightText = ""
        notesText = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { toast = nil }
    }
}
