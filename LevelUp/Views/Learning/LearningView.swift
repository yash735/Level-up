//
//  LearningView.swift
//  LEVEL UP — Phase 2
//
//  Container for the Learning track. Three tabs: Courses, Books,
//  Certifications.
//

import SwiftUI
import SwiftData

struct LearningView: View {

    let user: User

    @Query(sort: \Course.startedAt, order: .reverse)
    private var courses: [Course]

    @Query(sort: \Book.startedAt, order: .reverse)
    private var books: [Book]

    @Query private var certifications: [Certification]
    @Query(sort: \LearningLog.date, order: .reverse) private var learningLogs: [LearningLog]

    @AppStorage("weeklyStudyHoursTarget") private var weeklyStudyHoursTarget = 10

    enum Tab: String, CaseIterable, Identifiable {
        case courses, books, certs
        var id: String { rawValue }
        var title: String {
            switch self {
            case .courses: return "COURSES"
            case .books:   return "BOOKS"
            case .certs:   return "CERTS"
            }
        }
        var icon: String {
            switch self {
            case .courses: return "play.rectangle.fill"
            case .books:   return "book.fill"
            case .certs:   return "medal.fill"
            }
        }
    }

    @State private var selection: Tab = .courses

    private var vm: LearningViewModel {
        LearningViewModel(courses: courses, books: books, certifications: certifications)
    }

    private var studyHoursThisWeek: Double {
        let cal = Calendar.current
        let weekStart = cal.dateInterval(of: .weekOfYear, for: .now)?.start ?? cal.startOfDay(for: .now)
        return learningLogs
            .filter { $0.date >= weekStart }
            .reduce(0) { $0 + $1.hoursStudied }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                InternalTabBar(tabs: Tab.allCases,
                               selection: $selection,
                               title: { $0.title },
                               icon: { $0.icon },
                               tint: Theme.primaryAccent)

                Group {
                    switch selection {
                    case .courses: CoursesTabView(user: user, vm: vm)
                    case .books:   BooksTabView(user: user, vm: vm)
                    case .certs:   CertificationsTabView(user: user, vm: vm)
                    }
                }
            }
            .padding(32)
            .frame(maxWidth: 1100, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.background.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LEARNING")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .tracking(5)
                .foregroundStyle(Theme.primaryAccent)
                .shadow(color: Theme.primaryAccent.opacity(0.35), radius: 16, y: 2)
            HStack(spacing: 12) {
                Text("Level \(user.learningLevel)")
                    .font(.subheadline).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textPrimary)
                Text("·").foregroundStyle(Theme.textSecondary)
                Text("\(user.learningXP.formatted()) XP")
                    .font(.subheadline).monospacedDigit().fontWeight(.heavy)
                    .foregroundStyle(Theme.primaryAccent)
                Text("·").foregroundStyle(Theme.textSecondary)
                Text("\(vm.totalStudyHours, specifier: "%.1f") hrs total")
                    .font(.subheadline).monospacedDigit()
                    .foregroundStyle(Theme.textSecondary)
            }

            // Weekly study goal progress
            weeklyGoalBar
        }
    }

    private var weeklyGoalBar: some View {
        let progress = weeklyStudyHoursTarget > 0
            ? min(1.0, studyHoursThisWeek / Double(weeklyStudyHoursTarget))
            : 0
        let hit = studyHoursThisWeek >= Double(weeklyStudyHoursTarget)
        return HStack(spacing: 12) {
            Text("THIS WEEK")
                .font(.caption2).fontWeight(.heavy).tracking(1)
                .foregroundStyle(Theme.textSecondary)
            ProgressBar(progress: progress, color: hit ? Theme.xpGreen : Theme.primaryAccent)
                .frame(width: 180)
            Text(String(format: "%.1f / %d hrs", studyHoursThisWeek, weeklyStudyHoursTarget))
                .font(.caption).monospacedDigit().fontWeight(.semibold)
                .foregroundStyle(hit ? Theme.xpGreen : Theme.textPrimary)
            if hit {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.xpGreen)
                    .font(.caption)
            }
        }
    }
}
