//
//  CoursesTabView.swift
//  LEVEL UP — Phase 2
//
//  Add courses, log lessons / study time, mark complete. Completing a
//  course grants +400 XP; each study-hour logged grants +100 XP.
//

import SwiftUI
import SwiftData

struct CoursesTabView: View {

    let user: User
    let vm: LearningViewModel

    @Environment(\.modelContext) private var context

    // Add form
    @State private var showingAdd = false
    @State private var newName: String = ""
    @State private var newPlatform: String = "Udemy"
    @State private var newCategory: String = "Finance"
    @State private var newLessons: String = "10"

    private let platforms = ["Udemy", "Coursera", "YouTube", "CFA Institute", "Other"]
    private let categories = ["Finance", "Tech", "Business", "Marketing", "Other"]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            addRow
            inProgressCard
            completedCard
        }
        .sheet(isPresented: $showingAdd) { addSheet }
    }

    // MARK: - Add row

    private var addRow: some View {
        HStack {
            Button {
                resetForm()
                showingAdd = true
            } label: {
                Label("Add Course", systemImage: "plus.circle.fill")
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
    }

    // MARK: - In Progress

    private var inProgressCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("IN PROGRESS")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)
                if vm.coursesInProgress.isEmpty {
                    Text("No active courses.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    ForEach(vm.coursesInProgress) { course in
                        courseRow(course)
                    }
                }
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func courseRow(_ course: Course) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(course.name)
                        .font(.headline).fontWeight(.bold)
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(course.platform) · \(course.category)")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Text("\(course.completedLessons) / \(course.totalLessons)")
                    .font(.subheadline).monospacedDigit().fontWeight(.heavy)
                    .foregroundStyle(Theme.primaryAccent)
            }
            ProgressBar(progress: course.progress, color: Theme.primaryAccent)
            HStack(spacing: 8) {
                Button("+1 Lesson") { logLesson(course) }
                    .buttonStyle(.bordered)
                    .tint(Theme.primaryAccent)
                Button("+30 min") { logStudy(course, hours: 0.5) }
                    .buttonStyle(.bordered)
                    .tint(Theme.primaryAccent)
                Button("+1 hr") { logStudy(course, hours: 1) }
                    .buttonStyle(.bordered)
                    .tint(Theme.primaryAccent)
                Spacer()
                Button("Mark Complete") { complete(course) }
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

    // MARK: - Completed

    private var completedCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text("COMPLETED")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)
                if vm.completedCourses.isEmpty {
                    Text("None yet.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    ForEach(vm.completedCourses) { c in
                        HStack {
                            Image(systemName: "graduationcap.fill")
                                .foregroundStyle(Theme.xpGreen)
                            Text(c.name)
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text("+\(c.xpEarned) XP")
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

    // MARK: - Add sheet

    private var addSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("NEW COURSE")
                .font(.title2).fontWeight(.black).tracking(3)
                .foregroundStyle(Theme.textPrimary)

            field("Name", text: $newName)

            Picker("Platform", selection: $newPlatform) {
                ForEach(platforms, id: \.self) { Text($0) }
            }
            Picker("Category", selection: $newCategory) {
                ForEach(categories, id: \.self) { Text($0) }
            }
            field("Total lessons", text: $newLessons)

            HStack {
                Button("Cancel") { showingAdd = false }
                Spacer()
                Button("Add", action: addCourse)
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.primaryAccent)
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty
                              || Int(newLessons) == nil)
            }
        }
        .padding(32)
        .frame(minWidth: 380, minHeight: 380)
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
        newPlatform = "Udemy"
        newCategory = "Finance"
        newLessons = "10"
    }

    private func addCourse() {
        guard let lessons = Int(newLessons) else { return }
        let course = Course(name: newName.trimmingCharacters(in: .whitespaces),
                            platform: newPlatform,
                            category: newCategory,
                            totalLessons: lessons)
        context.insert(course)
        try? context.save()
        showingAdd = false
    }

    private func logLesson(_ course: Course) {
        course.completedLessons = min(course.totalLessons, course.completedLessons + 1)
        course.xpEarned += XPEngine.xpForStudy30Min
        user.award(XPEngine.xpForStudy30Min, to: .learning)
        PersonalRecordsEngine.evaluateStudySession(minutes: 30,
                                                   courseName: course.name,
                                                   in: context)
        try? context.save()
        evaluate()
    }

    private func logStudy(_ course: Course, hours: Double) {
        course.totalHours += hours
        let xp = hours >= 1 ? XPEngine.xpForStudy1Hour : XPEngine.xpForStudy30Min
        course.xpEarned += xp
        user.award(xp, to: .learning)
        PersonalRecordsEngine.evaluateStudySession(minutes: Int(hours * 60),
                                                   courseName: course.name,
                                                   in: context)
        try? context.save()
        evaluate()
    }

    private func complete(_ course: Course) {
        guard !course.isCompleted else { return }
        course.isCompleted = true
        course.completedAt = .now
        course.completedLessons = course.totalLessons
        course.xpEarned += XPEngine.xpForCourseComplete
        user.award(XPEngine.xpForCourseComplete, to: .learning)
        try? context.save()
        evaluate()
    }

    private func evaluate() {
        let newly = UnlockEngine.evaluateUnlocks(user: user, context: context)
        UnlockCenter.shared.present(newly)
    }
}
