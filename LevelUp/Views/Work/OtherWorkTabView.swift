//
//  OtherWorkTabView.swift
//  LEVEL UP — Phase 4.5
//
//  Structured project work logger with category-based XP,
//  target company tracking, project list, and history.
//

import SwiftUI
import SwiftData

struct OtherWorkTabView: View {

    let user: User

    @Environment(\.modelContext) private var context
    @Query(sort: \OtherWorkLog.date, order: .reverse) private var logs: [OtherWorkLog]

    // Form state
    @State private var category = "Other"
    @State private var targetCompany = ""
    @State private var projectName = ""
    @State private var actionType = "Deep Work"
    @State private var title = ""
    @State private var detail = ""
    @State private var hoursText = ""
    @State private var toast: String?

    // Filter
    @State private var filterProject: String?
    @State private var filterCategory: String?
    @State private var filterCompany: String?

    // MARK: - Derived

    private struct ProjectInfo: Identifiable {
        var id: String { name }
        let name: String
        let hours: Double
        let xp: Int
        let lastDate: Date
        let category: String
        let targetCompany: String?
    }

    private var projects: [ProjectInfo] {
        var map: [String: (hours: Double, xp: Int, last: Date, cat: String, company: String?)] = [:]
        for log in logs {
            let key = log.projectName
            let existing = map[key] ?? (hours: 0, xp: 0, last: .distantPast, cat: log.resolvedCategory, company: nil)
            map[key] = (hours: existing.hours + log.hoursSpent,
                        xp: existing.xp + log.xpEarned,
                        last: max(existing.last, log.date),
                        cat: log.resolvedCategory,
                        company: log.targetCompany ?? existing.company)
        }
        return map.map { ProjectInfo(name: $0.key, hours: $0.value.hours, xp: $0.value.xp,
                                      lastDate: $0.value.last, category: $0.value.cat,
                                      targetCompany: $0.value.company) }
            .sorted { $0.lastDate > $1.lastDate }
    }

    private struct CompanyInfo: Identifiable {
        var id: String { name }
        let name: String
        let hours: Double
        let firstDate: Date
        let sessionCount: Int
    }

    private var targetCompanies: [CompanyInfo] {
        var map: [String: (hours: Double, first: Date, count: Int)] = [:]
        for log in logs {
            guard let company = log.targetCompany, !company.isEmpty else { continue }
            let existing = map[company] ?? (hours: 0, first: .distantFuture, count: 0)
            map[company] = (hours: existing.hours + log.hoursSpent,
                            first: min(existing.first, log.date),
                            count: existing.count + 1)
        }
        return map.map { CompanyInfo(name: $0.key, hours: $0.value.hours,
                                      firstDate: $0.value.first, sessionCount: $0.value.count) }
            .sorted { $0.hours > $1.hours }
    }

    private var filteredLogs: [OtherWorkLog] {
        logs.filter { log in
            if let fp = filterProject, log.projectName != fp { return false }
            if let fc = filterCategory, log.resolvedCategory != fc { return false }
            if let fco = filterCompany, log.targetCompany != fco { return false }
            return true
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            logForm
            if !targetCompanies.isEmpty { targetCompanyTracker }
            if !projects.isEmpty { projectsList }
            historyCard
        }
    }

    // MARK: - Log Form

    private var logForm: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("LOG WORK")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)

                // Category + Action Type row
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CATEGORY")
                            .font(.caption2).fontWeight(.heavy).tracking(1)
                            .foregroundStyle(Theme.textSecondary)
                        Picker("", selection: $category) {
                            ForEach(OtherWorkLog.categories, id: \.self) { Text($0) }
                        }
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("ACTION TYPE")
                            .font(.caption2).fontWeight(.heavy).tracking(1)
                            .foregroundStyle(Theme.textSecondary)
                        Picker("", selection: $actionType) {
                            ForEach(OtherWorkLog.actionTypes, id: \.self) { Text($0) }
                        }
                        .labelsHidden()
                        .frame(width: 140)
                    }
                }

                // Target Company (only for Acquisitions Research)
                if category == "Acquisitions Research" {
                    formField("TARGET COMPANY (RECOMMENDED)",
                              placeholder: "e.g. Edible Oil Plant Hyderabad",
                              text: $targetCompany)
                }

                // Project / Area
                formField("PROJECT / AREA",
                          placeholder: "e.g. ARYA app, BVA pitch deck",
                          text: $projectName)

                // Title
                formField("TITLE", placeholder: "What did you do?", text: $title)

                // Description
                VStack(alignment: .leading, spacing: 4) {
                    Text("DESCRIPTION (OPTIONAL)")
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

                // Hours + Submit
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("HOURS SPENT")
                            .font(.caption2).fontWeight(.heavy).tracking(1)
                            .foregroundStyle(Theme.textSecondary)
                        TextField("e.g. 1.5", text: $hoursText)
                            .textFieldStyle(.plain)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textPrimary)
                            .padding(10)
                            .background(Theme.background)
                            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Theme.cardBorder, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .frame(width: 120)
                    }

                    // XP rate indicator
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(OtherWorkLog.xpRate(for: category)) XP/hr")
                            .font(.caption2).fontWeight(.heavy)
                            .foregroundStyle(Theme.secondaryAccent)
                        if actionType == "Deep Work" {
                            Text("1.5x Deep Work")
                                .font(.caption2)
                                .foregroundStyle(Theme.xpGold)
                        }
                    }

                    Spacer()

                    if let hours = Double(hoursText), hours > 0 {
                        let preview = OtherWorkLog.calculateXP(
                            hours: hours, actionType: actionType, category: category
                        )
                        Text("+\(preview) XP")
                            .font(.subheadline).fontWeight(.heavy)
                            .foregroundStyle(Theme.secondaryAccent)
                            .monospacedDigit()
                    }

                    Button(action: submit) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("Log Work")
                        }
                        .font(.subheadline).fontWeight(.semibold)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Theme.secondaryAccent.opacity(0.15))
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Theme.secondaryAccent.opacity(0.5), lineWidth: 1))
                        .foregroundStyle(Theme.secondaryAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(projectName.trimmingCharacters(in: .whitespaces).isEmpty
                              || title.trimmingCharacters(in: .whitespaces).isEmpty
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

    private func formField(_ label: String, placeholder: String,
                           text: Binding<String>) -> some View {
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

    // MARK: - Target Company Tracker

    private var targetCompanyTracker: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("TARGET COMPANIES")
                        .font(.caption).fontWeight(.heavy).tracking(2)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    if filterCompany != nil {
                        Button("Clear") { filterCompany = nil }
                            .font(.caption).foregroundStyle(Theme.secondaryAccent)
                            .buttonStyle(.plain)
                    }
                }

                ForEach(targetCompanies) { company in
                    Button {
                        filterCompany = filterCompany == company.name ? nil : company.name
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "building.2.fill")
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryAccent)
                                .frame(width: 28, height: 28)
                                .background(Theme.secondaryAccent.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(company.name)
                                    .font(.subheadline).fontWeight(.semibold)
                                    .foregroundStyle(filterCompany == company.name
                                                     ? Theme.secondaryAccent : Theme.textPrimary)
                                Text("First researched: \(company.firstDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption2).foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(String(format: "%.1fh", company.hours))
                                    .font(.caption).fontWeight(.heavy).monospacedDigit()
                                    .foregroundStyle(Theme.textPrimary)
                                Text("\(company.sessionCount) sessions")
                                    .font(.caption2).foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Projects List

    private var projectsList: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("PROJECTS")
                        .font(.caption).fontWeight(.heavy).tracking(2)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    if filterProject != nil {
                        Button("Clear") { filterProject = nil }
                            .font(.caption).foregroundStyle(Theme.secondaryAccent)
                            .buttonStyle(.plain)
                    }
                }

                ForEach(projects) { project in
                    Button {
                        filterProject = filterProject == project.name ? nil : project.name
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(filterProject == project.name
                                      ? Theme.secondaryAccent : Theme.cardBorder)
                                .frame(width: 8, height: 8)
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(project.name)
                                        .font(.subheadline).fontWeight(.semibold)
                                        .foregroundStyle(Theme.textPrimary)
                                    categoryBadge(project.category)
                                }
                                if let company = project.targetCompany, !company.isEmpty {
                                    Text(company)
                                        .font(.caption2).foregroundStyle(Theme.secondaryAccent)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("+\(project.xp) XP")
                                    .font(.caption).fontWeight(.heavy)
                                    .foregroundStyle(Theme.xpGreen).monospacedDigit()
                                Text(String(format: "%.1fh", project.hours))
                                    .font(.caption).monospacedDigit()
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Text(project.lastDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
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
                HStack {
                    Text("HISTORY")
                        .font(.caption).fontWeight(.heavy).tracking(2)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    if filterCategory != nil {
                        Button("Clear") { filterCategory = nil }
                            .font(.caption).foregroundStyle(Theme.secondaryAccent)
                            .buttonStyle(.plain)
                    }
                    Picker("", selection: Binding(
                        get: { filterCategory ?? "All" },
                        set: { filterCategory = $0 == "All" ? nil : $0 }
                    )) {
                        Text("All").tag("All")
                        ForEach(OtherWorkLog.categories, id: \.self) { Text($0).tag($0) }
                    }
                    .labelsHidden()
                    .frame(width: 180)
                }

                if filteredLogs.isEmpty {
                    Text("No work logged yet.")
                        .font(.subheadline).foregroundStyle(Theme.textSecondary)
                } else {
                    ForEach(filteredLogs.prefix(20)) { log in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    categoryBadge(log.resolvedCategory)
                                    Text(log.projectName)
                                        .font(.caption).fontWeight(.heavy)
                                        .foregroundStyle(Theme.secondaryAccent)
                                    if let company = log.targetCompany, !company.isEmpty {
                                        Text("· \(company)")
                                            .font(.caption)
                                            .foregroundStyle(Theme.textSecondary)
                                    }
                                }
                                Text(log.title)
                                    .font(.subheadline).fontWeight(.semibold)
                                    .foregroundStyle(Theme.textPrimary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("+\(log.xpEarned) XP")
                                    .font(.caption).fontWeight(.heavy)
                                    .foregroundStyle(Theme.xpGreen)
                                Text(String(format: "%.1fh", log.hoursSpent))
                                    .font(.caption).monospacedDigit()
                                    .foregroundStyle(Theme.textSecondary)
                                Text(log.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption2)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Helpers

    private func categoryBadge(_ cat: String) -> some View {
        let short: String
        switch cat {
        case "Acquisitions Research": short = "ACQ"
        case "Investor Relations":   short = "IR"
        case "Market Research":      short = "MR"
        case "Venture Building":     short = "VB"
        case "Admin & Ops":          short = "OPS"
        case "Content & Brand":      short = "CTN"
        default:                     short = "OTH"
        }
        return Text(short)
            .font(.system(size: 9, weight: .heavy, design: .rounded))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Theme.secondaryAccent.opacity(0.15))
            .foregroundStyle(Theme.secondaryAccent)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    // MARK: - Actions

    private func submit() {
        guard let hours = Double(hoursText), hours > 0 else { return }
        let project = projectName.trimmingCharacters(in: .whitespaces)
        let titleTrimmed = title.trimmingCharacters(in: .whitespaces)
        guard !project.isEmpty, !titleTrimmed.isEmpty else { return }

        let company = category == "Acquisitions Research"
            ? targetCompany.trimmingCharacters(in: .whitespaces)
            : nil

        let xp = OtherWorkLog.calculateXP(hours: hours, actionType: actionType,
                                            category: category)
        let log = OtherWorkLog(category: category,
                               targetCompany: company?.isEmpty == true ? nil : company,
                               projectName: project,
                               actionType: actionType,
                               title: titleTrimmed,
                               detail: detail,
                               hoursSpent: hours,
                               xpEarned: xp)
        context.insert(log)
        user.award(xp, to: .work)
        try? context.save()

        // Update challenge progress
        ChallengeManager.updateProgress(user: user, in: context)

        let newly = UnlockEngine.evaluateUnlocks(user: user, context: context)
        UnlockCenter.shared.present(newly)

        toast = "+\(xp) XP"
        title = ""
        detail = ""
        hoursText = ""
        targetCompany = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { toast = nil }
    }
}
