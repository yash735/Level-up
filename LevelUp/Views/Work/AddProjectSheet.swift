import SwiftUI
import SwiftData

struct AddProjectSheet: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var onCreated: ((Project, Bool) -> Void)?

    @FocusState private var nameFieldFocused: Bool
    @State private var name = ""
    @State private var descriptionText = ""
    @State private var selectedIcon = "folder.fill"
    @State private var selectedColorHex = "#FF9500"

    private let icons = [
        "folder.fill", "briefcase.fill", "hammer.fill", "shippingbox.fill",
        "building.2.fill", "chart.bar.fill", "lightbulb.fill", "gear.fill",
        "laptopcomputer", "paintbrush.fill", "book.fill", "dollarsign.circle.fill"
    ]

    private let presetColors: [(String, String)] = [
        ("Orange", "#FF9500"),
        ("Blue", "#007AFF"),
        ("Green", "#34C759"),
        ("Purple", "#AF52DE"),
        ("Red", "#FF3B30"),
        ("Teal", "#5AC8FA"),
        ("Pink", "#FF2D55"),
        ("Yellow", "#FFCC00"),
    ]

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("NEW PROJECT")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .tracking(3)
                .foregroundStyle(selectedColor)

            VStack(alignment: .leading, spacing: 4) {
                Text("NAME")
                    .font(.caption2).fontWeight(.heavy).tracking(1)
                    .foregroundStyle(Theme.textSecondary)
                TextField("Project name", text: $name)
                    .focused($nameFieldFocused)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(10)
                    .background(Theme.background)
                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Theme.cardBorder, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("DESCRIPTION")
                    .font(.caption2).fontWeight(.heavy).tracking(1)
                    .foregroundStyle(Theme.textSecondary)
                Text("Used by AI to suggest milestones")
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary.opacity(0.7))
                TextField("What is this project about?", text: $descriptionText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(3...5)
                    .padding(10)
                    .background(Theme.background)
                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Theme.cardBorder, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("ICON")
                    .font(.caption2).fontWeight(.heavy).tracking(1)
                    .foregroundStyle(Theme.textSecondary)
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(44), spacing: 10), count: 6), spacing: 10) {
                    ForEach(icons, id: \.self) { icon in
                        Button { selectedIcon = icon } label: {
                            Image(systemName: icon)
                                .font(.system(size: 16))
                                .frame(width: 40, height: 40)
                                .foregroundStyle(selectedIcon == icon ? selectedColor : Theme.textSecondary)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(selectedIcon == icon ? selectedColor.opacity(0.14) : Theme.background)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(selectedIcon == icon ? selectedColor.opacity(0.6) : Theme.cardBorder,
                                                lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("COLOR")
                    .font(.caption2).fontWeight(.heavy).tracking(1)
                    .foregroundStyle(Theme.textSecondary)
                HStack(spacing: 12) {
                    ForEach(presetColors, id: \.1) { (_, hex) in
                        Button { selectedColorHex = hex } label: {
                            Circle()
                                .fill(Color(hex: hex) ?? .gray)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(selectedColorHex == hex ? 0.9 : 0),
                                                lineWidth: 2)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Theme.cardBorder, lineWidth: selectedColorHex == hex ? 0 : 1)
                                )
                                .scaleEffect(selectedColorHex == hex ? 1.15 : 1.0)
                                .animation(.easeOut(duration: 0.15), value: selectedColorHex)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Spacer()

            HStack(spacing: 12) {
                Button("Cancel") { dismiss() }
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(Theme.textSecondary)
                    .buttonStyle(.plain)

                Spacer()

                Button { create(generateMilestones: false) } label: {
                    Text("Create")
                        .font(.subheadline).fontWeight(.semibold)
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(selectedColor.opacity(0.15))
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(selectedColor.opacity(0.5), lineWidth: 1))
                        .foregroundStyle(selectedColor)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!isValid)

                Button { create(generateMilestones: true) } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("Create & Generate Milestones")
                    }
                    .font(.subheadline).fontWeight(.semibold)
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(selectedColor.opacity(0.2))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(selectedColor.opacity(0.6), lineWidth: 1))
                    .foregroundStyle(selectedColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!isValid)
            }
        }
        .padding(28)
        .frame(width: 520, height: 580)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .stroke(selectedColor.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            name = ""
            descriptionText = ""
            selectedIcon = "folder.fill"
            selectedColorHex = "#FF9500"
            nameFieldFocused = true
        }
    }

    private var selectedColor: Color {
        Color(hex: selectedColorHex) ?? Theme.secondaryAccent
    }

    private func create(generateMilestones: Bool) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let existingCount = (try? context.fetchCount(FetchDescriptor<Project>())) ?? 0
        let project = Project(name: trimmed,
                              projectDescription: descriptionText,
                              colorHex: selectedColorHex,
                              iconName: selectedIcon,
                              orderIndex: existingCount)
        context.insert(project)
        try? context.save()

        onCreated?(project, generateMilestones)
        dismiss()
    }
}
