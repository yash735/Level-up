//
//  WeeklyReportRoot.swift
//  LEVEL UP — Phase 4
//
//  Thin root-level view that checks for pending weekly reports on
//  appear and shows the WeeklyReportOverlay when one is generated.
//

import SwiftUI
import SwiftData

struct WeeklyReportRoot: View {

    @Environment(\.modelContext) private var context
    @Query private var users: [User]

    @State private var pendingReport: WeeklyReport?

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onAppear(perform: checkForReport)
            .overlay {
                if let report = pendingReport {
                    WeeklyReportOverlay(report: report) {
                        withAnimation { pendingReport = nil }
                    }
                }
            }
    }

    private func checkForReport() {
        guard let user = users.first else { return }
        if let report = WeeklyReportEngine.generateIfNeeded(user: user, in: context) {
            pendingReport = report
        }
    }
}
