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
        VStack(alignment: .leading, spacing: 6) {
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
                Text("\(vm.totalStudyHours, specifier: "%.1f") hrs")
                    .font(.subheadline).monospacedDigit()
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }
}
