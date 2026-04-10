//
//  FoodTabView.swift
//  LEVEL UP — Phase 2
//
//  Nutrition logging, now AI-powered. The user types a natural-language
//  meal description ("3 eggs and toast with butter") and Claude returns
//  a JSON macro estimate. The user can confirm as-is or tweak numbers
//  before saving. Daily goals and the today-list live alongside unchanged.
//

import SwiftUI
import SwiftData

struct FoodTabView: View {

    let user: User
    let vm: FitnessViewModel

    @Environment(\.modelContext) private var context

    // Per-user daily goals. Defaults tuned for a 75kg lifter in a
    // slight surplus — user can adjust in the goals card.
    @AppStorage("goal_calories") private var goalCalories: Int = 2_800
    @AppStorage("goal_protein")  private var goalProtein: Double = 160
    @AppStorage("goal_carbs")    private var goalCarbs: Double = 300
    @AppStorage("goal_fats")     private var goalFats: Double = 80

    @State private var showingGoals = false

    // MARK: - Log flow state

    /// Drives the log card UI. `.idle` = blank prompt, `.analyzing` = spinner,
    /// `.estimated` = confirm/edit buttons, `.editing` = editable macro fields.
    private enum LogStage: Equatable {
        case idle
        case analyzing
        case estimated(MealEstimate)
        case editing(MealEstimate)
    }

    @State private var mealType: String = "Breakfast"
    @State private var prompt: String = ""
    @State private var stage: LogStage = .idle
    @State private var errorMessage: String?
    @State private var toast: String?

    // Scratch fields used while the user edits AI estimates.
    @State private var editDescription: String = ""
    @State private var editCalories: String = ""
    @State private var editProtein: String = ""
    @State private var editCarbs: String = ""
    @State private var editFats: String = ""

    private let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack"]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            macroCard
            logCard
            mealsCard
        }
        .sheet(isPresented: $showingGoals) { goalsSheet }
    }

    // MARK: - Macro card

    private var macroCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("TODAY'S MACROS")
                        .font(.caption).fontWeight(.heavy).tracking(2)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Button("Edit Goals") { showingGoals = true }
                        .font(.caption).fontWeight(.semibold)
                        .buttonStyle(.plain)
                        .foregroundStyle(Theme.primaryAccent)
                }

                macroRow(label: "Calories",
                         current: Double(vm.todaysCalories),
                         goal: Double(goalCalories),
                         unit: "kcal",
                         color: Theme.xpGreen)
                macroRow(label: "Protein",
                         current: vm.todaysProtein,
                         goal: goalProtein,
                         unit: "g",
                         color: Theme.primaryAccent)
                macroRow(label: "Carbs",
                         current: vm.todaysCarbs,
                         goal: goalCarbs,
                         unit: "g",
                         color: Theme.secondaryAccent)
                macroRow(label: "Fats",
                         current: vm.todaysFats,
                         goal: goalFats,
                         unit: "g",
                         color: .orange)
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func macroRow(label: String, current: Double, goal: Double, unit: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label.uppercased())
                    .font(.caption).fontWeight(.heavy).tracking(1)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("\(Int(current)) / \(Int(goal)) \(unit)")
                    .font(.caption).monospacedDigit()
                    .foregroundStyle(Theme.textPrimary)
            }
            ProgressBar(progress: goal > 0 ? current / goal : 0, color: color)
        }
    }

    // MARK: - Log card

    private var logCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("LOG MEAL")
                        .font(.caption).fontWeight(.heavy).tracking(2)
                        .foregroundStyle(Theme.xpGreen)
                    Spacer()
                    Label("AI", systemImage: "sparkles")
                        .font(.caption2).fontWeight(.heavy).tracking(1)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Theme.primaryAccent.opacity(0.15))
                        .foregroundStyle(Theme.primaryAccent)
                        .clipShape(Capsule())
                }

                Picker("Meal", selection: $mealType) {
                    ForEach(mealTypes, id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)

                logCardStageBody

                if let toast {
                    Text(toast)
                        .font(.caption).fontWeight(.semibold)
                        .foregroundStyle(Theme.xpGreen)
                }
                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var logCardStageBody: some View {
        switch stage {
        case .idle:
            idleBody
        case .analyzing:
            analyzingBody
        case .estimated(let est):
            estimatedBody(est)
        case .editing(let est):
            editingBody(original: est)
        }
    }

    // MARK: stage: idle

    private var idleBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("What did you eat? (e.g. 3 eggs and toast with butter)",
                      text: $prompt, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.plain)
                .padding(10)
                .background(Theme.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Theme.cardBorder, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            HStack {
                Button {
                    analyze()
                } label: {
                    Label("Analyze Food", systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.primaryAccent)
                .disabled(prompt.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    // MARK: stage: analyzing

    private var analyzingBody: some View {
        HStack(spacing: 12) {
            ProgressView().controlSize(.small)
            Text("Analyzing with Claude…")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Button("Cancel") { resetForm() }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.vertical, 6)
    }

    // MARK: stage: estimated

    private func estimatedBody(_ est: MealEstimate) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(est.description.isEmpty ? prompt : est.description)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(Theme.textPrimary)

            HStack(spacing: 12) {
                macroPill("CAL", "\(est.calories)", Theme.xpGreen)
                macroPill("P",   "\(est.protein)g", Theme.primaryAccent)
                macroPill("C",   "\(est.carbs)g",   Theme.secondaryAccent)
                macroPill("F",   "\(est.fats)g",    .orange)
                Spacer()
            }

            HStack(spacing: 10) {
                Button {
                    save(est)
                } label: {
                    Label("Looks right, log it", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.xpGreen)
                .foregroundStyle(Color.black)

                Button {
                    startEditing(est)
                } label: {
                    Label("Edit before logging", systemImage: "slider.horizontal.3")
                }
                .buttonStyle(.bordered)
                .tint(Theme.primaryAccent)

                Spacer()

                Button("Start over") { resetForm() }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func macroPill(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2).fontWeight(.heavy).tracking(1)
                .foregroundStyle(Theme.textSecondary)
            Text(value)
                .font(.subheadline).fontWeight(.heavy).monospacedDigit()
                .foregroundStyle(color)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(color.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(color.opacity(0.4), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: stage: editing

    private func editingBody(original: MealEstimate) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Description", text: $editDescription)
                .textFieldStyle(.plain)
                .padding(10)
                .background(Theme.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Theme.cardBorder, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            HStack(spacing: 8) {
                numField("Calories", text: $editCalories)
                numField("Protein g", text: $editProtein)
                numField("Carbs g", text: $editCarbs)
                numField("Fats g", text: $editFats)
            }

            HStack(spacing: 10) {
                Button {
                    saveEdited()
                } label: {
                    Label("Log Meal", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.xpGreen)
                .foregroundStyle(Color.black)
                .disabled(editDescription.trimmingCharacters(in: .whitespaces).isEmpty
                          || Int(editCalories) == nil)

                Button("Back") {
                    stage = .estimated(original)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.textSecondary)

                Spacer()

                Button("Start over") { resetForm() }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func numField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .textFieldStyle(.plain)
            .padding(10)
            .background(Theme.background)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Theme.cardBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Meals list

    private var mealsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("TODAY'S MEALS")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)
                if vm.todaysFood.isEmpty {
                    Text("Nothing logged yet.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    ForEach(vm.todaysFood) { entry in
                        HStack(spacing: 12) {
                            Text(entry.mealType.prefix(1).uppercased())
                                .font(.caption).fontWeight(.heavy)
                                .frame(width: 28, height: 28)
                                .background(Theme.xpGreen.opacity(0.15))
                                .clipShape(Circle())
                                .foregroundStyle(Theme.xpGreen)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.foodName)
                                    .font(.subheadline).fontWeight(.semibold)
                                    .foregroundStyle(Theme.textPrimary)
                                Text("\(entry.calories) kcal · P\(Int(entry.protein)) C\(Int(entry.carbs)) F\(Int(entry.fats))")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            Text("+\(entry.xpEarned) XP")
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

    // MARK: - Goals sheet

    private var goalsSheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("DAILY GOALS")
                .font(.title2).fontWeight(.black).tracking(3)
                .foregroundStyle(Theme.textPrimary)

            goalField("Calories", value: Binding(
                get: { String(goalCalories) },
                set: { goalCalories = Int($0) ?? goalCalories }
            ))
            goalField("Protein (g)", value: Binding(
                get: { String(Int(goalProtein)) },
                set: { goalProtein = Double($0) ?? goalProtein }
            ))
            goalField("Carbs (g)", value: Binding(
                get: { String(Int(goalCarbs)) },
                set: { goalCarbs = Double($0) ?? goalCarbs }
            ))
            goalField("Fats (g)", value: Binding(
                get: { String(Int(goalFats)) },
                set: { goalFats = Double($0) ?? goalFats }
            ))

            Button("Done") { showingGoals = false }
                .buttonStyle(.borderedProminent)
                .tint(Theme.primaryAccent)
        }
        .padding(32)
        .frame(minWidth: 360, minHeight: 360)
        .background(Theme.background)
    }

    private func goalField(_ label: String, value: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(Theme.textSecondary)
            TextField(label, text: value)
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

    private func analyze() {
        let description = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !description.isEmpty else { return }
        errorMessage = nil
        stage = .analyzing
        Task {
            do {
                let estimate = try await AIClient.analyzeMeal(description)
                await MainActor.run {
                    stage = .estimated(estimate)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    stage = .idle
                }
            }
        }
    }

    private func startEditing(_ est: MealEstimate) {
        editDescription = est.description.isEmpty ? prompt : est.description
        editCalories = String(est.calories)
        editProtein = String(est.protein)
        editCarbs = String(est.carbs)
        editFats = String(est.fats)
        stage = .editing(est)
    }

    private func save(_ est: MealEstimate) {
        let name = est.description.isEmpty
            ? prompt.trimmingCharacters(in: .whitespacesAndNewlines)
            : est.description
        persist(foodName: name,
                calories: est.calories,
                protein: Double(est.protein),
                carbs: Double(est.carbs),
                fats: Double(est.fats))
    }

    private func saveEdited() {
        guard let cals = Int(editCalories) else { return }
        persist(foodName: editDescription.trimmingCharacters(in: .whitespaces),
                calories: cals,
                protein: Double(editProtein) ?? 0,
                carbs: Double(editCarbs) ?? 0,
                fats: Double(editFats) ?? 0)
    }

    private func persist(foodName: String, calories: Int, protein: Double, carbs: Double, fats: Double) {
        let entry = FoodEntry(date: .now,
                              mealType: mealType,
                              foodName: foodName,
                              calories: calories,
                              protein: protein,
                              carbs: carbs,
                              fats: fats,
                              xpEarned: XPEngine.xpForNutritionLog)
        context.insert(entry)
        user.award(XPEngine.xpForNutritionLog, to: .fitness)
        try? context.save()

        let newly = UnlockEngine.evaluateUnlocks(user: user, context: context)
        UnlockCenter.shared.present(newly)

        toast = "+\(XPEngine.xpForNutritionLog) XP"
        resetForm()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { toast = nil }
    }

    private func resetForm() {
        prompt = ""
        stage = .idle
        errorMessage = nil
        editDescription = ""
        editCalories = ""
        editProtein = ""
        editCarbs = ""
        editFats = ""
    }
}
