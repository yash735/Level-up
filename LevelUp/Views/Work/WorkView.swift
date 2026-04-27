import SwiftUI
import SwiftData

struct WorkView: View {

    let user: User

    @Environment(\.modelContext) private var context
    @Query(sort: \Project.orderIndex) private var allProjects: [Project]

    @State private var selectedProjectID: UUID?
    @State private var showingQuickTasks = false
    @State private var addProjectToken: AddProjectToken?
    @State private var projectToDelete: Project?

    private struct AddProjectToken: Identifiable {
        let id = UUID()
    }

    private var projects: [Project] {
        allProjects.filter { !$0.isArchived }
    }

    private var selectedProject: Project? {
        if let id = selectedProjectID {
            return projects.first { $0.id == id }
        }
        return projects.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                projectTabBar

                if showingQuickTasks {
                    QuickTasksTabView(user: user)
                } else if let project = selectedProject {
                    ProjectTabView(user: user, project: project)
                        .id(project.id)
                } else {
                    emptyState
                }
            }
            .padding(32)
            .frame(maxWidth: 1100, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.background.ignoresSafeArea())
        .sheet(item: $addProjectToken) { _ in
            AddProjectSheet { project, generateMilestones in
                selectedProjectID = project.id
                if generateMilestones {
                    triggerAIGeneration(for: project)
                }
            }
        }
        .alert("Delete Project?",
               isPresented: Binding(
                   get: { projectToDelete != nil },
                   set: { if !$0 { projectToDelete = nil } }
               )
        ) {
            Button("Delete", role: .destructive) {
                if let project = projectToDelete {
                    deleteProject(project)
                }
            }
            Button("Cancel", role: .cancel) { projectToDelete = nil }
        } message: {
            if let project = projectToDelete {
                Text("This will permanently delete \"\(project.name)\" and all its entries and milestones.")
            }
        }
        .onChange(of: projects.count) {
            if selectedProjectID == nil, let first = projects.first {
                selectedProjectID = first.id
            }
        }
        .onAppear {
            if selectedProjectID == nil, let first = projects.first {
                selectedProjectID = first.id
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("WORK")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .tracking(5)
                .foregroundStyle(Theme.secondaryAccent)
                .shadow(color: Theme.secondaryAccent.opacity(0.35), radius: 16, y: 2)
            HStack(spacing: 12) {
                Text("Level \(user.workLevel)")
                    .font(.subheadline).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textPrimary)
                Text("\u{00B7}").foregroundStyle(Theme.textSecondary)
                Text("\(user.workXP.formatted()) XP")
                    .font(.subheadline).monospacedDigit().fontWeight(.heavy)
                    .foregroundStyle(Theme.secondaryAccent)
            }
        }
    }

    private var projectTabBar: some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.easeOut(duration: 0.15)) {
                    showingQuickTasks = true
                    selectedProjectID = nil
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checklist")
                        .font(.caption)
                    Text("QUICK TASKS")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .tracking(1)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .foregroundStyle(showingQuickTasks ? Theme.secondaryAccent : Theme.textSecondary)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(showingQuickTasks ? Theme.secondaryAccent.opacity(0.14) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(showingQuickTasks ? Theme.secondaryAccent.opacity(0.55) : Theme.cardBorder,
                                lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            ForEach(projects) { project in
                let isSelected = !showingQuickTasks && project.id == (selectedProjectID ?? projects.first?.id)
                let tint = Color(hex: project.colorHex) ?? Theme.secondaryAccent

                Button {
                    withAnimation(.easeOut(duration: 0.15)) {
                        showingQuickTasks = false
                        selectedProjectID = project.id
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: project.iconName)
                            .font(.caption)
                        Text(project.name.uppercased())
                            .font(.subheadline).fontWeight(.semibold).tracking(1)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .foregroundStyle(isSelected ? tint : Theme.textSecondary)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isSelected ? tint.opacity(0.14) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isSelected ? tint.opacity(0.55) : Theme.cardBorder,
                                    lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button {
                        archiveProject(project)
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                    Divider()
                    Button(role: .destructive) {
                        projectToDelete = project
                    } label: {
                        Label("Delete Project", systemImage: "trash")
                    }
                }
            }

            Button { addProjectToken = AddProjectToken() } label: {
                Image(systemName: "plus")
                    .font(.subheadline).fontWeight(.semibold)
                    .frame(width: 36, height: 36)
                    .foregroundStyle(Theme.textSecondary)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Theme.cardBorder, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)
        }
    }

    private var emptyState: some View {
        Card {
            VStack(spacing: 16) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 36))
                    .foregroundStyle(Theme.secondaryAccent.opacity(0.5))
                Text("Create your first project to start tracking work.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                Button { addProjectToken = AddProjectToken() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("New Project")
                    }
                    .font(.subheadline).fontWeight(.semibold)
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(Theme.secondaryAccent.opacity(0.15))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Theme.secondaryAccent.opacity(0.5), lineWidth: 1))
                    .foregroundStyle(Theme.secondaryAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(32)
            .frame(maxWidth: .infinity)
        }
    }

    private func archiveProject(_ project: Project) {
        project.isArchived = true
        try? context.save()
        if selectedProjectID == project.id {
            selectedProjectID = projects.first(where: { $0.id != project.id })?.id
        }
    }

    private func deleteProject(_ project: Project) {
        let wasSelected = selectedProjectID == project.id
        context.delete(project)
        try? context.save()
        if wasSelected {
            selectedProjectID = projects.first?.id
        }
    }

    private func triggerAIGeneration(for project: Project) {
        Task {
            do {
                let titles = try await AIClient.generateMilestones(
                    projectName: project.name,
                    description: project.projectDescription
                )
                for (i, t) in titles.enumerated() {
                    let m = ProjectMilestone(project: project,
                                             title: t,
                                             isAISuggested: true,
                                             orderIndex: i)
                    context.insert(m)
                }
                try? context.save()
            } catch {
                print("AI milestone generation failed: \(error.localizedDescription)")
            }
        }
    }
}
