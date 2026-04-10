//
//  WeeklyReportOverlay.swift
//  LEVEL UP — Phase 4
//
//  Full-screen "WEEK IN REVIEW" overlay. Same dramatic style as
//  the Phase 3 level-up overlay. Shows last week's stats, grade,
//  and summary.
//

import SwiftUI

struct WeeklyReportOverlay: View {

    let report: WeeklyReport
    let onDismiss: () -> Void

    @State private var show = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.82).ignoresSafeArea()
            ConfettiView().ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    card
                }
                .padding(40)
                .frame(maxWidth: .infinity)
            }
        }
        .zIndex(180)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { show = true }
        }
    }

    private var card: some View {
        VStack(spacing: 22) {
            Text("WEEK IN REVIEW")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .tracking(8)
                .foregroundStyle(Theme.xpGold)
                .scaleEffect(show ? 1 : 0.8)
                .opacity(show ? 1 : 0)

            Text(dateRange)
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(Theme.textSecondary)

            // Grade badge
            ZStack {
                Circle()
                    .fill(gradeColor.opacity(0.15))
                    .frame(width: 100, height: 100)
                Circle()
                    .stroke(gradeColor, lineWidth: 4)
                    .frame(width: 100, height: 100)
                    .shadow(color: gradeColor.opacity(0.6), radius: 16)
                Text(report.grade)
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(gradeColor)
            }
            .scaleEffect(show ? 1 : 0.3)

            // Stats grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()),
                                GridItem(.flexible())], spacing: 14) {
                statCell("TOTAL XP", "\(report.totalXP)", Theme.xpGreen)
                statCell("WORKOUTS", "\(report.workoutsCompleted)", Theme.xpGreen)
                statCell("GYM", "\(report.gymSessionsCompleted)/5", Theme.xpGreen)
                statCell("BVA", "\(report.bvaActionsCount)", Theme.secondaryAccent)
                statCell("PARALAI", "\(report.paralaiLogsCount)", Theme.secondaryAccent)
                statCell("OTHER WORK", String(format: "%.0fh", report.otherWorkHours), Theme.secondaryAccent)
                statCell("STUDY", String(format: "%.0fh", report.studyHours), Theme.primaryAccent)
                statCell("HABITS", String(format: "%.0f%%", report.habitsCompletionRate * 100), Theme.primaryAccent)
                statCell("VS LAST WEEK", xpChangeText, xpChangeColor)
            }

            Divider().background(Theme.cardBorder)

            // Summary
            Text(report.summaryText)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onDismiss) {
                Text("CONTINUE")
                    .font(.headline).tracking(3)
                    .frame(maxWidth: 260)
                    .padding(.vertical, 16)
                    .background(Theme.levelUpGradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Theme.xpGold.opacity(0.5), radius: 16, y: 6)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)
        }
        .padding(32)
        .frame(maxWidth: 580)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Theme.xpGold.opacity(0.5), lineWidth: 2)
        )
        .shadow(color: Theme.xpGold.opacity(0.4), radius: 30)
    }

    private func statCell(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
                .monospacedDigit()
            Text(label)
                .font(.caption2).fontWeight(.heavy).tracking(1)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var dateRange: String {
        let fmt = Date.FormatStyle.dateTime.month(.abbreviated).day()
        return "\(report.weekStartDate.formatted(fmt)) – \(report.weekEndDate.formatted(fmt))"
    }

    private var gradeColor: Color {
        switch report.grade {
        case "S": return Theme.xpGold
        case "A": return Theme.xpGreen
        case "B": return Theme.secondaryAccent
        case "C": return Theme.primaryAccent
        default:  return .red
        }
    }

    private var xpChangeText: String {
        if report.xpChangeVsLastWeek > 0 { return "+\(Int(report.xpChangeVsLastWeek))%" }
        if report.xpChangeVsLastWeek < 0 { return "\(Int(report.xpChangeVsLastWeek))%" }
        return "—"
    }

    private var xpChangeColor: Color {
        report.xpChangeVsLastWeek >= 0 ? Theme.xpGreen : .red
    }
}
