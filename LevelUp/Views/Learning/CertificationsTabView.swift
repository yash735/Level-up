//
//  CertificationsTabView.swift
//  LEVEL UP — Phase 2
//
//  Track certifications. Pre-seeds AWS Cloud Practitioner as already
//  earned on first appearance. Earning a cert grants +600 XP.
//

import SwiftUI
import SwiftData

struct CertificationsTabView: View {

    let user: User
    let vm: LearningViewModel

    @Environment(\.modelContext) private var context

    // Add form
    @State private var showingAdd = false
    @State private var newName: String = ""
    @State private var newBody: String = ""
    @State private var newHours: String = "40"
    @State private var useTarget: Bool = false
    @State private var newTarget: Date = .now.addingTimeInterval(60 * 60 * 24 * 30)

    // Per-row study hours draft
    @State private var hourDrafts: [UUID: String] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Button {
                    resetForm()
                    showingAdd = true
                } label: {
                    Label("Add Certification", systemImage: "plus.circle.fill")
                        .font(.subheadline).fontWeight(.semibold)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Theme.primaryAccent.opacity(0.14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Theme.primaryAccent.opacity(0.55), lineWidth: 1)
                        )
                        .foregroundStyle(Theme.primaryAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                Spacer()
            }

            activeCard
            earnedCard
        }
        .sheet(isPresented: $showingAdd) { addSheet }
        .onAppear(perform: seedIfNeeded)
    }

    // MARK: - Active

    private var activeCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("IN PROGRESS")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)
                if vm.activeCertifications.isEmpty {
                    Text("No certifications in progress.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    ForEach(vm.activeCertifications) { cert in
                        certRow(cert)
                    }
                }
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func certRow(_ cert: Certification) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(cert.name)
                        .font(.headline).fontWeight(.bold)
                        .foregroundStyle(Theme.textPrimary)
                    HStack(spacing: 6) {
                        Text(cert.issuingBody)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                        if let due = cert.targetDate {
                            Text("· target \(due.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
                Spacer()
                Text("\(cert.studiedHours, specifier: "%.1f") / \(cert.estimatedHours, specifier: "%.0f") hrs")
                    .font(.subheadline).monospacedDigit().fontWeight(.heavy)
                    .foregroundStyle(Theme.primaryAccent)
            }
            ProgressBar(progress: cert.progress, color: Theme.primaryAccent)
            HStack(spacing: 8) {
                TextField("Hours",
                          text: Binding(
                            get: { hourDrafts[cert.id] ?? "" },
                            set: { hourDrafts[cert.id] = $0 }))
                    .textFieldStyle(.plain)
                    .frame(width: 100)
                    .padding(8)
                    .background(Theme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.cardBorder, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                Button("Log Study") { logStudy(cert) }
                    .buttonStyle(.bordered)
                    .tint(Theme.primaryAccent)
                Spacer()
                Button("Mark Earned") { earn(cert) }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.xpGreen)
                    .foregroundStyle(Color.black)
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

    // MARK: - Earned

    private var earnedCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text("EARNED")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)
                if vm.earnedCertifications.isEmpty {
                    Text("None yet.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    ForEach(vm.earnedCertifications) { c in
                        HStack {
                            Image(systemName: "medal.fill")
                                .foregroundStyle(Theme.xpGreen)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(c.name)
                                    .font(.subheadline).fontWeight(.semibold)
                                    .foregroundStyle(Theme.textPrimary)
                                Text(c.issuingBody)
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            if let at = c.earnedAt {
                                Text(at.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .padding(.vertical, 4)
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
            Text("NEW CERT")
                .font(.title2).fontWeight(.black).tracking(3)
                .foregroundStyle(Theme.textPrimary)
            field("Name", text: $newName)
            field("Issuing Body", text: $newBody)
            field("Estimated hours", text: $newHours)
            Toggle("Target date", isOn: $useTarget)
            if useTarget {
                DatePicker("Target", selection: $newTarget, displayedComponents: .date)
            }
            HStack {
                Button("Cancel") { showingAdd = false }
                Spacer()
                Button("Add", action: addCert)
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.primaryAccent)
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(32)
        .frame(minWidth: 380, minHeight: 420)
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

    private func resetForm() {
        newName = ""
        newBody = ""
        newHours = "40"
        useTarget = false
        newTarget = .now.addingTimeInterval(60 * 60 * 24 * 30)
    }

    private func addCert() {
        let cert = Certification(name: newName.trimmingCharacters(in: .whitespaces),
                                 issuingBody: newBody,
                                 targetDate: useTarget ? newTarget : nil,
                                 estimatedHours: Double(newHours) ?? 0)
        context.insert(cert)
        try? context.save()
        showingAdd = false
    }

    private func logStudy(_ cert: Certification) {
        guard let hours = Double(hourDrafts[cert.id] ?? ""), hours > 0 else { return }
        cert.studiedHours += hours
        let xp = hours >= 1 ? XPEngine.xpForStudy1Hour : XPEngine.xpForStudy30Min
        cert.xpEarned += xp
        user.award(xp, to: .learning)
        PersonalRecordsEngine.evaluateStudySession(minutes: Int(hours * 60),
                                                   courseName: cert.name,
                                                   in: context)
        hourDrafts[cert.id] = ""
        try? context.save()
        evaluate()
    }

    private func earn(_ cert: Certification) {
        guard !cert.isEarned else { return }
        cert.isEarned = true
        cert.earnedAt = .now
        cert.xpEarned += XPEngine.xpForCertification
        user.award(XPEngine.xpForCertification, to: .learning)
        try? context.save()
        evaluate()
    }

    private func evaluate() {
        let newly = UnlockEngine.evaluateUnlocks(user: user, context: context)
        UnlockCenter.shared.present(newly)
    }

    // MARK: - Seed

    /// AWS Cloud Practitioner is pre-seeded as already earned, as the
    /// user has that in real life — gives the Certs tab something to
    /// render on day one.
    private func seedIfNeeded() {
        if vm.certifications.isEmpty {
            let aws = Certification(name: "AWS Certified Cloud Practitioner",
                                    issuingBody: "Amazon Web Services",
                                    estimatedHours: 40)
            aws.isEarned = true
            aws.earnedAt = .now
            aws.studiedHours = 40
            context.insert(aws)
            try? context.save()
        }
    }
}
