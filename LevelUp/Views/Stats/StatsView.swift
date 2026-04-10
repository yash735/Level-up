//
//  StatsView.swift
//  LEVEL UP — Phase 4
//
//  Full analytics dashboard. Segmented into Overview, Fitness,
//  Work, Learning, and Combined sections. Uses Swift Charts for
//  all standard visualisations, SwiftUI Canvas for heatmaps
//  and the radar chart.
//

import SwiftUI
import SwiftData
import Charts

// MARK: - Chart helper types

private struct WeekBucket: Identifiable {
    let id = UUID()
    let weekStart: Date
    var gymCount: Int = 0
    var cardioCount: Int = 0
}

private struct DayBucket: Identifiable {
    let id = UUID()
    let date: Date
    var calories: Int = 0
}

private struct DayXP: Identifiable {
    let id = UUID()
    let date: Date
    let fitness: Int
    let work: Int
    let learning: Int
}

struct StatsView: View {

    let user: User

    @Environment(\.modelContext) private var context

    // Segment + time range
    enum Segment: String, CaseIterable, Identifiable {
        case overview, fitness, work, learning, combined
        var id: String { rawValue }
        var title: String { rawValue.capitalized }
    }

    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "7 Days"
        case month = "30 Days"
        case quarter = "90 Days"
        case all = "All Time"
        var id: String { rawValue }

        var startDate: Date {
            let cal = Calendar.current
            switch self {
            case .week:    return cal.date(byAdding: .day, value: -7, to: .now) ?? .distantPast
            case .month:   return cal.date(byAdding: .day, value: -30, to: .now) ?? .distantPast
            case .quarter: return cal.date(byAdding: .day, value: -90, to: .now) ?? .distantPast
            case .all:     return .distantPast
            }
        }
    }

    @State private var segment: Segment = .overview
    @State private var timeRange: TimeRange = .month

    // All data loaded once per render
    @Query(sort: \GymSession.date) private var gymSessions: [GymSession]
    @Query(sort: \CardioSession.date) private var cardioSessions: [CardioSession]
    @Query(sort: \FoodEntry.date) private var foodEntries: [FoodEntry]
    @Query(sort: \WeightEntry.date) private var weightEntries: [WeightEntry]
    @Query(sort: \HabitLog.date) private var habitLogs: [HabitLog]
    @Query(sort: \Deal.updatedAt, order: .reverse) private var deals: [Deal]
    @Query(sort: \ParaLAIEntry.date) private var paralaiEntries: [ParaLAIEntry]
    @Query(sort: \ParaLAIMilestone.orderIndex) private var milestones: [ParaLAIMilestone]
    @Query(sort: \OtherWorkLog.date) private var otherWorkLogs: [OtherWorkLog]
    @Query(sort: \Course.name) private var courses: [Course]
    @Query(sort: \Book.title) private var books: [Book]
    @Query(sort: \Certification.name) private var certifications: [Certification]
    @Query private var unlocks: [Unlock]
    @Query(sort: \PersonalRecord.date, order: .reverse) private var records: [PersonalRecord]
    @Query(sort: \WeeklyReport.weekStartDate, order: .reverse) private var weeklyReports: [WeeklyReport]

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                controls

                switch segment {
                case .overview: overviewSection
                case .fitness:  fitnessSection
                case .work:     workSection
                case .learning: learningSection
                case .combined: combinedSection
                }
            }
            .padding(32)
            .frame(maxWidth: 1100, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.background.ignoresSafeArea())
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("STATS")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .tracking(5)
                .foregroundStyle(Theme.heroGradient)
                .shadow(color: Theme.primaryAccent.opacity(0.35), radius: 16, y: 2)
            Text("Your life, quantified.")
                .font(.subheadline).foregroundStyle(Theme.textSecondary)
        }
    }

    private var controls: some View {
        HStack(spacing: 16) {
            // Segment picker
            HStack(spacing: 4) {
                ForEach(Segment.allCases) { seg in
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) { segment = seg }
                    } label: {
                        Text(seg.title)
                            .font(.caption).fontWeight(.semibold).tracking(0.5)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .foregroundStyle(segment == seg ? Theme.primaryAccent : Theme.textSecondary)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(segment == seg ? Theme.primaryAccent.opacity(0.14) : .clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(segment == seg ? Theme.primaryAccent.opacity(0.5) : Theme.cardBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            // Time range
            Picker("", selection: $timeRange) {
                ForEach(TimeRange.allCases) { Text($0.rawValue).tag($0) }
            }
            .labelsHidden()
            .frame(width: 120)

            // Export
            Button(action: exportData) {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export")
                }
                .font(.caption).fontWeight(.semibold)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .foregroundStyle(Theme.textSecondary)
                .background(Theme.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Theme.cardBorder, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    // ============================================================
    // MARK: - OVERVIEW
    // ============================================================

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            SectionHeader(title: "Overview")

            let totalWorkouts = gymSessions.filter { !$0.isRestDay }.count + cardioSessions.count
            let earned = unlocks.filter { $0.isUnlocked }.count
            let totalUnlocks = unlocks.count
            let totalStudyHours = courses.reduce(0.0) { $0 + $1.totalHours }
                + certifications.reduce(0.0) { $0 + $1.studiedHours }
            let daysActive: Int = {
                guard let earliest = user.createdAt as Date? else { return 0 }
                return max(1, Calendar.current.dateComponents([.day], from: earliest, to: .now).day ?? 1)
            }()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()),
                                GridItem(.flexible())], spacing: 14) {
                overviewCard("TOTAL XP", user.totalXP.formatted(), Theme.xpGreen)
                overviewCard("DAYS ACTIVE", "\(daysActive)", Theme.secondaryAccent)
                overviewCard("UNLOCKS", "\(earned)/\(totalUnlocks)", Theme.primaryAccent)
                overviewCard("LONGEST STREAK", "\(user.longestStreak)", Theme.flameHot)
                overviewCard("TOTAL WORKOUTS", "\(totalWorkouts)", Theme.xpGreen)
                overviewCard("TOTAL DEALS", "\(deals.count)", Theme.secondaryAccent)
                overviewCard("STUDY HOURS", String(format: "%.0f", totalStudyHours), Theme.primaryAccent)
                overviewCard("WEEKLY REPORTS", "\(weeklyReports.count)", Theme.textSecondary)
                overviewCard("PERSONAL RECORDS", "\(records.count)", Theme.xpGold)
            }

            // Weekly report history
            if !weeklyReports.isEmpty {
                SectionHeader(title: "Recent Weekly Reports")
                ForEach(weeklyReports.prefix(4)) { report in
                    weeklyReportRow(report)
                }
            }
        }
    }

    private func overviewCard(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.caption2).fontWeight(.heavy).tracking(1)
                .foregroundStyle(Theme.textSecondary)
            Text(value)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Theme.cardBackground)
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(Theme.cardBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func weeklyReportRow(_ report: WeeklyReport) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(gradeColor(report.grade).opacity(0.15))
                    .frame(width: 44, height: 44)
                Text(report.grade)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(gradeColor(report.grade))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(report.summaryText)
                    .font(.caption).foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                let fmt = Date.FormatStyle.dateTime.month(.abbreviated).day()
                Text("\(report.weekStartDate.formatted(fmt)) – \(report.weekEndDate.formatted(fmt))")
                    .font(.caption2).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Text("\(report.totalXP) XP")
                .font(.caption).fontWeight(.heavy).monospacedDigit()
                .foregroundStyle(Theme.xpGreen)
        }
        .padding(12)
        .background(Theme.cardBackground)
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(Theme.cardBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func gradeColor(_ grade: String) -> Color {
        switch grade {
        case "S": return Theme.xpGold
        case "A": return Theme.xpGreen
        case "B": return Theme.secondaryAccent
        case "C": return Theme.primaryAccent
        default: return .red
        }
    }

    // ============================================================
    // MARK: - FITNESS
    // ============================================================

    private var fitnessSection: some View {
        let start = timeRange.startDate
        let end = Date.now
        let filteredGym = gymSessions.filter { $0.date >= start && $0.date < end && !$0.isRestDay }
        let filteredCardio = cardioSessions.filter { $0.date >= start && $0.date < end }
        let filteredWeight = weightEntries.filter { $0.date >= start && $0.date < end }
        let filteredFood = foodEntries.filter { $0.date >= start && $0.date < end }
        let filteredHabits = habitLogs.filter { $0.date >= start && $0.date < end }

        return VStack(alignment: .leading, spacing: 24) {
            // Weight chart
            if !filteredWeight.isEmpty {
                weightChart(filteredWeight)
            }

            // Workout frequency
            if !filteredGym.isEmpty || !filteredCardio.isEmpty {
                workoutFrequencyChart(gym: filteredGym, cardio: filteredCardio)
            }

            // Split consistency
            if !filteredGym.isEmpty {
                splitConsistencyView(filteredGym)
            }

            // Nutrition
            if !filteredFood.isEmpty {
                nutritionChart(filteredFood)
            }

            // Habit heatmap
            if !filteredHabits.isEmpty {
                habitHeatmap(filteredHabits)
            }

            // Fitness PRs
            fitnessPersonalRecords

            // Empty state
            if filteredGym.isEmpty && filteredCardio.isEmpty && filteredWeight.isEmpty {
                emptyState("Start logging workouts to see your fitness trends", icon: "figure.run")
            }
        }
    }

    // -- Weight chart
    @ViewBuilder
    private func weightChart(_ entries: [WeightEntry]) -> some View {
        let sorted = entries.sorted { $0.date < $1.date }
        let first = sorted.first!.weightKg
        let last = sorted.last!.weightKg
        let delta = last - first

        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("WEIGHT TREND")
                        .font(.caption).fontWeight(.heavy).tracking(2)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text(String(format: "%@%.1f kg", delta >= 0 ? "+" : "", delta))
                        .font(.caption).fontWeight(.heavy)
                        .foregroundStyle(delta <= 0 ? Theme.xpGreen : Theme.flameHot)
                }

                Chart(sorted) { entry in
                    LineMark(x: .value("Date", entry.date),
                             y: .value("Weight", entry.weightKg))
                        .foregroundStyle(Theme.secondaryAccent)
                        .interpolationMethod(.catmullRom)
                    AreaMark(x: .value("Date", entry.date),
                             y: .value("Weight", entry.weightKg))
                        .foregroundStyle(Theme.secondaryAccent.opacity(0.1))
                        .interpolationMethod(.catmullRom)
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .chartXAxis { AxisMarks(values: .automatic) { _ in AxisValueLabel().foregroundStyle(Theme.textSecondary) } }
                .chartYAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(Theme.textSecondary) } }
                .frame(height: 200)
            }
            .padding(Theme.cardPadding)
        }
    }

    // -- Workout frequency chart
    private func buildWorkoutBuckets(gym: [GymSession], cardio: [CardioSession]) -> [WeekBucket] {
        let cal = Calendar.current
        var buckets: [String: WeekBucket] = [:]
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-'W'ww"

        for s in gym {
            let key = fmt.string(from: s.date)
            let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: s.date)) ?? s.date
            buckets[key, default: WeekBucket(weekStart: weekStart)].gymCount += 1
        }
        for c in cardio {
            let key = fmt.string(from: c.date)
            let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: c.date)) ?? c.date
            buckets[key, default: WeekBucket(weekStart: weekStart)].cardioCount += 1
        }
        return Array(buckets.values.sorted { $0.weekStart < $1.weekStart }.suffix(12))
    }

    @ViewBuilder
    private func workoutFrequencyChart(gym: [GymSession], cardio: [CardioSession]) -> some View {
        let sorted = buildWorkoutBuckets(gym: gym, cardio: cardio)

        Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("WORKOUT FREQUENCY")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)

                Chart(Array(sorted)) { bucket in
                    BarMark(x: .value("Week", bucket.weekStart, unit: .weekOfYear),
                            y: .value("Gym", bucket.gymCount))
                        .foregroundStyle(Theme.primaryAccent)
                    BarMark(x: .value("Week", bucket.weekStart, unit: .weekOfYear),
                            y: .value("Cardio", bucket.cardioCount))
                        .foregroundStyle(Theme.xpGreen)
                }
                .chartXAxis { AxisMarks(values: .automatic) { _ in AxisValueLabel().foregroundStyle(Theme.textSecondary) } }
                .chartYAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(Theme.textSecondary) } }
                .frame(height: 200)

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Circle().fill(Theme.primaryAccent).frame(width: 8, height: 8)
                        Text("Gym").font(.caption2).foregroundStyle(Theme.textSecondary)
                    }
                    HStack(spacing: 4) {
                        Circle().fill(Theme.xpGreen).frame(width: 8, height: 8)
                        Text("Cardio").font(.caption2).foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .padding(Theme.cardPadding)
        }
    }

    // -- Split consistency
    @ViewBuilder
    private func splitConsistencyView(_ sessions: [GymSession]) -> some View {
        let splits = ["Upper", "Lower", "Push", "Pull", "Legs"]
        let counts = splits.map { split in
            sessions.filter { $0.splitDay == split }.count
        }
        let maxCount = max(1, counts.max() ?? 1)

        Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("GYM SPLIT CONSISTENCY")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)

                HStack(spacing: 16) {
                    ForEach(Array(zip(splits, counts)), id: \.0) { split, count in
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .stroke(Theme.cardBorder, lineWidth: 4)
                                    .frame(width: 56, height: 56)
                                Circle()
                                    .trim(from: 0, to: Double(count) / Double(maxCount))
                                    .stroke(Theme.primaryAccent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                    .frame(width: 56, height: 56)
                                    .rotationEffect(.degrees(-90))
                                Text("\(count)")
                                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                                    .foregroundStyle(Theme.textPrimary)
                            }
                            Text(split)
                                .font(.caption2).fontWeight(.heavy)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(Theme.cardPadding)
        }
    }

    // -- Nutrition chart
    private func buildNutritionBuckets(_ entries: [FoodEntry]) -> [DayBucket] {
        let cal = Calendar.current
        var buckets: [String: DayBucket] = [:]
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"

        for e in entries {
            let key = fmt.string(from: e.date)
            let day = cal.startOfDay(for: e.date)
            buckets[key, default: DayBucket(date: day)].calories += e.calories
        }
        return buckets.values.sorted { $0.date < $1.date }
    }

    @ViewBuilder
    private func nutritionChart(_ entries: [FoodEntry]) -> some View {
        let sorted = buildNutritionBuckets(entries)

        Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("DAILY CALORIES")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)

                Chart(sorted) { bucket in
                    BarMark(x: .value("Day", bucket.date, unit: .day),
                            y: .value("Calories", bucket.calories))
                        .foregroundStyle(Theme.xpGreen.opacity(0.7))
                }
                .chartXAxis { AxisMarks(values: .automatic) { _ in AxisValueLabel().foregroundStyle(Theme.textSecondary) } }
                .chartYAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(Theme.textSecondary) } }
                .frame(height: 180)
            }
            .padding(Theme.cardPadding)
        }
    }

    // -- Habit heatmap
    private func buildHabitDayMap(_ logs: [HabitLog]) -> [String: Int] {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        var dayMap: [String: Int] = [:]
        for log in logs {
            let count = [log.sleep, log.water, log.steps, log.noJunk,
                         log.morningWorkout, log.eveningStretch].filter { $0 }.count
            dayMap[fmt.string(from: log.date)] = count
        }
        return dayMap
    }

    private func habitHeatmap(_ logs: [HabitLog]) -> some View {
        let cal = Calendar.current
        let dayMap = buildHabitDayMap(logs)
        let weeks = 26
        let today = cal.startOfDay(for: .now)
        let startOffset = -(weeks * 7 - 1)
        let startDate = cal.date(byAdding: .day, value: startOffset, to: today)!
        let heatmapFmt = DateFormatter()
        heatmapFmt.dateFormat = "yyyy-MM-dd"

        return Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("HABIT COMPLETION HEATMAP")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)

                Canvas { ctx, size in
                    let cols = weeks
                    let rows = 7
                    let cellSize = min(size.width / CGFloat(cols) - 2,
                                       size.height / CGFloat(rows) - 2)
                    let gap: CGFloat = 2

                    for col in 0..<cols {
                        for row in 0..<rows {
                            let dayOffset = col * 7 + row
                            guard let date = cal.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
                            let key = heatmapFmt.string(from: date)
                            let count = dayMap[key] ?? 0
                            let color = habitColor(count)

                            let x = CGFloat(col) * (cellSize + gap)
                            let y = CGFloat(row) * (cellSize + gap)
                            let rect = CGRect(x: x, y: y, width: cellSize, height: cellSize)
                            let path = Path(roundedRect: rect, cornerRadius: 2)
                            ctx.fill(path, with: .color(color))
                        }
                    }
                }
                .frame(height: 110)

                HStack(spacing: 12) {
                    Text("Less").font(.caption2).foregroundStyle(Theme.textSecondary)
                    ForEach([0, 2, 4, 6], id: \.self) { count in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(habitColor(count))
                            .frame(width: 12, height: 12)
                    }
                    Text("More").font(.caption2).foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(Theme.cardPadding)
        }
    }

    private func habitColor(_ count: Int) -> Color {
        switch count {
        case 0:    return Theme.cardBackground
        case 1...2: return Theme.xpGreen.opacity(0.2)
        case 3...4: return Theme.xpGreen.opacity(0.5)
        case 5:    return Theme.xpGreen.opacity(0.75)
        default:   return Theme.xpGreen
        }
    }

    // -- Fitness PRs
    private var fitnessPersonalRecords: some View {
        let fitnessPRs = records.filter { $0.track == "Fitness" }.prefix(6)
        return Group {
            if !fitnessPRs.isEmpty {
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("FITNESS PERSONAL RECORDS")
                            .font(.caption).fontWeight(.heavy).tracking(2)
                            .foregroundStyle(Theme.textSecondary)
                        ForEach(Array(fitnessPRs)) { pr in
                            HStack(spacing: 12) {
                                Image(systemName: "trophy.fill")
                                    .foregroundStyle(Theme.xpGold)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(pr.title).font(.subheadline).fontWeight(.semibold)
                                        .foregroundStyle(Theme.textPrimary)
                                    Text(pr.value).font(.caption).monospacedDigit()
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                Spacer()
                                Text(pr.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption2).foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }
                    .padding(Theme.cardPadding)
                }
            }
        }
    }

    // ============================================================
    // MARK: - WORK
    // ============================================================

    private var workSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // BVA Pipeline
            if !deals.isEmpty {
                bvaPipelineChart
                bvaDealVelocity
            }

            // ParaLAI Progress
            if !milestones.isEmpty {
                paralaiProgress
            }

            // Other Work
            if !otherWorkLogs.isEmpty {
                otherWorkAnalytics
            }

            // Work PRs
            workPersonalRecords

            if deals.isEmpty && paralaiEntries.isEmpty && otherWorkLogs.isEmpty {
                emptyState("Start logging work to see your productivity trends", icon: "briefcase.fill")
            }
        }
    }

    // -- BVA Pipeline
    private var bvaPipelineChart: some View {
        let stages = ["Prospecting", "Initial Contact", "Due Diligence",
                      "Term Sheet", "Closing", "Closed Won"]
        let stageCounts = stages.map { stage in
            deals.filter { $0.stage == stage }.count
        }
        let stageValues = stages.map { stage in
            deals.filter { $0.stage == stage }.reduce(0.0) { $0 + $1.dealSizeMillion }
        }

        return Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("BVA PIPELINE")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)

                ForEach(Array(zip(stages, zip(stageCounts, stageValues))), id: \.0) { stage, data in
                    let (count, value) = data
                    HStack(spacing: 12) {
                        Text(stage)
                            .font(.caption).fontWeight(.semibold)
                            .foregroundStyle(Theme.textPrimary)
                            .frame(width: 120, alignment: .leading)
                        GeometryReader { geo in
                            let maxCount = max(1, stageCounts.max() ?? 1)
                            let width = geo.size.width * CGFloat(count) / CGFloat(maxCount)
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Theme.secondaryAccent.opacity(0.6))
                                .frame(width: max(4, width))
                        }
                        .frame(height: 20)
                        Text("\(count) · $\(String(format: "%.1fM", value))")
                            .font(.caption2).monospacedDigit()
                            .foregroundStyle(Theme.textSecondary)
                            .frame(width: 100, alignment: .trailing)
                    }
                }
            }
            .padding(Theme.cardPadding)
        }
    }

    // -- Deal velocity
    private var bvaDealVelocity: some View {
        let wonDeals = deals.filter { $0.isClosedWon }
        let lostDeals = deals.filter { $0.isClosedLost }
        let winRate = (wonDeals.count + lostDeals.count) > 0
            ? Double(wonDeals.count) / Double(wonDeals.count + lostDeals.count) * 100
            : 0

        return Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("DEAL METRICS")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)
                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("\(deals.count)").font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(Theme.secondaryAccent)
                        Text("TOTAL DEALS").font(.caption2).fontWeight(.heavy).tracking(1)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    VStack(spacing: 4) {
                        Text("\(wonDeals.count)").font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(Theme.xpGreen)
                        Text("WON").font(.caption2).fontWeight(.heavy).tracking(1)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    VStack(spacing: 4) {
                        Text(String(format: "%.0f%%", winRate))
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(winRate >= 50 ? Theme.xpGreen : Theme.flameHot)
                        Text("WIN RATE").font(.caption2).fontWeight(.heavy).tracking(1)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    VStack(spacing: 4) {
                        Text(String(format: "$%.1fM", wonDeals.reduce(0.0) { $0 + $1.dealSizeMillion }))
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(Theme.xpGold)
                        Text("WON VALUE").font(.caption2).fontWeight(.heavy).tracking(1)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(Theme.cardPadding)
        }
    }

    // -- ParaLAI progress
    private var paralaiProgress: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("PARALAI MILESTONES")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)

                HStack(spacing: 0) {
                    ForEach(milestones.sorted { $0.orderIndex < $1.orderIndex }) { m in
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(m.isCompleted ? Theme.primaryAccent : Theme.cardBorder)
                                    .frame(width: 24, height: 24)
                                if m.isCompleted {
                                    Image(systemName: "checkmark")
                                        .font(.caption2).bold()
                                        .foregroundStyle(.white)
                                }
                            }
                            Text("M\(m.orderIndex + 1)")
                                .font(.caption2).fontWeight(.heavy)
                                .foregroundStyle(m.isCompleted ? Theme.primaryAccent : Theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                let completed = milestones.filter { $0.isCompleted }.count
                Text("\(completed)/\(milestones.count) milestones completed")
                    .font(.caption).foregroundStyle(Theme.textSecondary)
            }
            .padding(Theme.cardPadding)
        }
    }

    // -- Other work analytics
    private var otherWorkAnalytics: some View {
        let start = timeRange.startDate
        let filtered = otherWorkLogs.filter { $0.date >= start }

        // Top projects by hours
        var projectHours: [String: Double] = [:]
        for log in filtered {
            projectHours[log.projectName, default: 0] += log.hoursSpent
        }
        let sortedProjects = projectHours.sorted { $0.value > $1.value }.prefix(8)
        let maxHours = sortedProjects.first?.value ?? 1

        // Action type breakdown
        var typeCounts: [String: Int] = [:]
        for log in filtered { typeCounts[log.actionType, default: 0] += 1 }

        return VStack(alignment: .leading, spacing: 16) {
            Card {
                VStack(alignment: .leading, spacing: 14) {
                    Text("TOP PROJECTS BY HOURS")
                        .font(.caption).fontWeight(.heavy).tracking(2)
                        .foregroundStyle(Theme.textSecondary)

                    ForEach(Array(sortedProjects), id: \.key) { project, hours in
                        HStack(spacing: 12) {
                            Text(project)
                                .font(.caption).fontWeight(.semibold)
                                .foregroundStyle(Theme.textPrimary)
                                .frame(width: 160, alignment: .leading)
                                .lineLimit(1)
                            GeometryReader { geo in
                                let w = geo.size.width * CGFloat(hours / maxHours)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Theme.secondaryAccent.opacity(0.6))
                                    .frame(width: max(4, w))
                            }
                            .frame(height: 16)
                            Text(String(format: "%.1fh", hours))
                                .font(.caption2).monospacedDigit()
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
                .padding(Theme.cardPadding)
            }

            Card {
                VStack(alignment: .leading, spacing: 14) {
                    Text("ACTION TYPE BREAKDOWN")
                        .font(.caption).fontWeight(.heavy).tracking(2)
                        .foregroundStyle(Theme.textSecondary)

                    let total = max(1, typeCounts.values.reduce(0, +))
                    ForEach(typeCounts.sorted { $0.value > $1.value }, id: \.key) { type, count in
                        HStack {
                            Text(type).font(.caption).foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text("\(count) · \(Int(Double(count) / Double(total) * 100))%")
                                .font(.caption).monospacedDigit()
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
                .padding(Theme.cardPadding)
            }
        }
    }

    // -- Work PRs
    private var workPersonalRecords: some View {
        let workPRs = records.filter { $0.track == "Work" }.prefix(6)
        return Group {
            if !workPRs.isEmpty {
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("WORK PERSONAL RECORDS")
                            .font(.caption).fontWeight(.heavy).tracking(2)
                            .foregroundStyle(Theme.textSecondary)
                        ForEach(Array(workPRs)) { pr in
                            HStack(spacing: 12) {
                                Image(systemName: "trophy.fill").foregroundStyle(Theme.xpGold)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(pr.title).font(.subheadline).fontWeight(.semibold)
                                        .foregroundStyle(Theme.textPrimary)
                                    Text(pr.value).font(.caption).monospacedDigit()
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding(Theme.cardPadding)
                }
            }
        }
    }

    // ============================================================
    // MARK: - LEARNING
    // ============================================================

    private var learningSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Knowledge stack
            knowledgeStack

            // Course timeline
            if !courses.isEmpty { courseTimeline }

            // Learning breakdown
            learningBreakdown

            // Learning PRs
            learningPersonalRecords

            if courses.isEmpty && books.isEmpty && certifications.isEmpty {
                emptyState("Start logging study sessions to see learning trends", icon: "book.fill")
            }
        }
    }

    private var knowledgeStack: some View {
        var categoryHours: [String: Double] = [:]
        for c in courses { categoryHours[c.category, default: 0] += c.totalHours }
        for b in books { categoryHours[b.category, default: 0] += b.totalHours }
        for c in certifications {
            let cat = c.issuingBody.isEmpty ? "Other" : c.issuingBody
            categoryHours[cat, default: 0] += c.studiedHours
        }
        let sorted = categoryHours.sorted { $0.value > $1.value }
        let maxH = sorted.first?.value ?? 1

        return Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("KNOWLEDGE STACK")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)

                if sorted.isEmpty {
                    Text("No study hours logged yet.")
                        .font(.subheadline).foregroundStyle(Theme.textSecondary)
                } else {
                    ForEach(sorted, id: \.key) { category, hours in
                        HStack(spacing: 12) {
                            Text(category)
                                .font(.caption).fontWeight(.semibold)
                                .foregroundStyle(Theme.textPrimary)
                                .frame(width: 120, alignment: .leading)
                            GeometryReader { geo in
                                let w = geo.size.width * CGFloat(hours / maxH)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Theme.primaryAccent.opacity(0.6))
                                    .frame(width: max(4, w))
                            }
                            .frame(height: 16)
                            Text(String(format: "%.0fh", hours))
                                .font(.caption2).monospacedDigit()
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
            }
            .padding(Theme.cardPadding)
        }
    }

    private var courseTimeline: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("COURSES")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)

                let completed = courses.filter { $0.isCompleted }.count
                let inProgress = courses.filter { !$0.isCompleted }.count
                HStack(spacing: 24) {
                    VStack(spacing: 2) {
                        Text("\(completed)").font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundStyle(Theme.primaryAccent)
                        Text("COMPLETED").font(.caption2).fontWeight(.heavy).tracking(1)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    VStack(spacing: 2) {
                        Text("\(inProgress)").font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundStyle(Theme.secondaryAccent)
                        Text("IN PROGRESS").font(.caption2).fontWeight(.heavy).tracking(1)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                ForEach(courses.sorted { $0.startedAt > $1.startedAt }.prefix(6)) { course in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(course.isCompleted ? Theme.primaryAccent : Theme.secondaryAccent)
                            .frame(width: 10, height: 10)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(course.name).font(.subheadline).fontWeight(.semibold)
                                .foregroundStyle(Theme.textPrimary)
                            Text("\(course.platform) · \(course.completedLessons)/\(course.totalLessons) lessons")
                                .font(.caption).foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        ProgressView(value: course.progress)
                            .frame(width: 60)
                            .tint(course.isCompleted ? Theme.primaryAccent : Theme.secondaryAccent)
                    }
                }
            }
            .padding(Theme.cardPadding)
        }
    }

    private var learningBreakdown: some View {
        let courseHours = courses.reduce(0.0) { $0 + $1.totalHours }
        let bookHours = books.reduce(0.0) { $0 + $1.totalHours }
        let certHours = certifications.reduce(0.0) { $0 + $1.studiedHours }
        let total = max(1, courseHours + bookHours + certHours)

        return Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("LEARNING BREAKDOWN")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)

                HStack(spacing: 24) {
                    breakdownItem("Courses", courseHours, total, Theme.primaryAccent)
                    breakdownItem("Books", bookHours, total, Theme.secondaryAccent)
                    breakdownItem("Certs", certHours, total, Theme.xpGold)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(Theme.cardPadding)
        }
    }

    private func breakdownItem(_ label: String, _ hours: Double, _ total: Double, _ color: Color) -> some View {
        VStack(spacing: 6) {
            Text(String(format: "%.0f%%", hours / total * 100))
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
            Text(String(format: "%.0fh", hours))
                .font(.caption).monospacedDigit().foregroundStyle(Theme.textPrimary)
            Text(label).font(.caption2).fontWeight(.heavy).tracking(1)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var learningPersonalRecords: some View {
        let learningPRs = records.filter { $0.track == "Learning" }.prefix(6)
        return Group {
            if !learningPRs.isEmpty {
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("LEARNING PERSONAL RECORDS")
                            .font(.caption).fontWeight(.heavy).tracking(2)
                            .foregroundStyle(Theme.textSecondary)
                        ForEach(Array(learningPRs)) { pr in
                            HStack(spacing: 12) {
                                Image(systemName: "trophy.fill").foregroundStyle(Theme.xpGold)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(pr.title).font(.subheadline).fontWeight(.semibold)
                                        .foregroundStyle(Theme.textPrimary)
                                    Text(pr.value).font(.caption).monospacedDigit()
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding(Theme.cardPadding)
                }
            }
        }
    }

    // ============================================================
    // MARK: - COMBINED
    // ============================================================

    private var combinedSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            lifeBalanceRadar
            xpTimeline
            insightsSection
        }
    }

    // -- Radar chart (Canvas)
    private var lifeBalanceRadar: some View {
        let maxLevel = Double(max(1, [user.fitnessLevel, user.workLevel, user.learningLevel].max() ?? 1))
        let values = [
            Double(user.fitnessLevel) / maxLevel,
            Double(user.workLevel) / maxLevel,
            Double(user.learningLevel) / maxLevel
        ]
        let labels = ["Fitness", "Work", "Learning"]
        let colors = [Theme.xpGreen, Theme.secondaryAccent, Theme.primaryAccent]

        return Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("LIFE BALANCE")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)

                Canvas { ctx, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let radius = min(size.width, size.height) / 2 - 30
                    let n = 3
                    let angleStep = (2 * .pi) / Double(n)

                    // Grid rings
                    for ring in 1...4 {
                        let r = radius * Double(ring) / 4
                        var path = Path()
                        for i in 0..<n {
                            let angle = angleStep * Double(i) - .pi / 2
                            let pt = CGPoint(x: center.x + cos(angle) * r,
                                             y: center.y + sin(angle) * r)
                            if i == 0 { path.move(to: pt) }
                            else { path.addLine(to: pt) }
                        }
                        path.closeSubpath()
                        ctx.stroke(path, with: .color(Theme.cardBorder), lineWidth: 1)
                    }

                    // Data shape
                    var dataPath = Path()
                    for i in 0..<n {
                        let angle = angleStep * Double(i) - .pi / 2
                        let r = radius * values[i]
                        let pt = CGPoint(x: center.x + cos(angle) * r,
                                         y: center.y + sin(angle) * r)
                        if i == 0 { dataPath.move(to: pt) }
                        else { dataPath.addLine(to: pt) }
                    }
                    dataPath.closeSubpath()
                    ctx.fill(dataPath, with: .color(Theme.primaryAccent.opacity(0.2)))
                    ctx.stroke(dataPath, with: .color(Theme.primaryAccent), lineWidth: 2)

                    // Labels
                    for i in 0..<n {
                        let angle = angleStep * Double(i) - .pi / 2
                        let labelR = radius + 20
                        let pt = CGPoint(x: center.x + cos(angle) * labelR,
                                         y: center.y + sin(angle) * labelR)
                        ctx.draw(Text(labels[i])
                            .font(.caption2).fontWeight(.heavy)
                            .foregroundColor(colors[i]),
                                 at: pt)
                    }
                }
                .frame(height: 260)

                HStack(spacing: 24) {
                    ForEach(Array(zip(labels, zip(colors, [user.fitnessLevel, user.workLevel, user.learningLevel]))), id: \.0) { label, data in
                        let (color, level) = data
                        VStack(spacing: 2) {
                            Text("Lv \(level)")
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                                .foregroundStyle(color)
                            Text(label).font(.caption2).fontWeight(.heavy)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(Theme.cardPadding)
        }
    }

    // -- XP Timeline
    private var xpTimeline: some View {
        let cal = Calendar.current
        let start = timeRange.startDate
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"

        var dayMap: [String: (f: Int, w: Int, l: Int)] = [:]

        for s in gymSessions.filter({ $0.date >= start && !$0.isRestDay }) {
            let key = fmt.string(from: s.date)
            dayMap[key, default: (0,0,0)].f += s.xpEarned
        }
        for c in cardioSessions.filter({ $0.date >= start }) {
            let key = fmt.string(from: c.date)
            dayMap[key, default: (0,0,0)].f += c.xpEarned
        }
        for f in foodEntries.filter({ $0.date >= start }) {
            let key = fmt.string(from: f.date)
            dayMap[key, default: (0,0,0)].f += f.xpEarned
        }
        for e in paralaiEntries.filter({ $0.date >= start }) {
            let key = fmt.string(from: e.date)
            dayMap[key, default: (0,0,0)].w += e.xpEarned
        }
        for o in otherWorkLogs.filter({ $0.date >= start }) {
            let key = fmt.string(from: o.date)
            dayMap[key, default: (0,0,0)].w += o.xpEarned
        }

        let sorted = dayMap.map { key, val in
            DayXP(date: fmt.date(from: key) ?? .now, fitness: val.f, work: val.w, learning: val.l)
        }.sorted { $0.date < $1.date }

        return Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("XP TIMELINE")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)

                if sorted.isEmpty {
                    Text("No XP data in this range.")
                        .font(.subheadline).foregroundStyle(Theme.textSecondary)
                } else {
                    Chart(sorted) { day in
                        BarMark(x: .value("Date", day.date, unit: .day),
                                y: .value("Fitness", day.fitness))
                            .foregroundStyle(Theme.xpGreen)
                        BarMark(x: .value("Date", day.date, unit: .day),
                                y: .value("Work", day.work))
                            .foregroundStyle(Theme.secondaryAccent)
                        BarMark(x: .value("Date", day.date, unit: .day),
                                y: .value("Learning", day.learning))
                            .foregroundStyle(Theme.primaryAccent)
                    }
                    .chartXAxis { AxisMarks(values: .automatic) { _ in AxisValueLabel().foregroundStyle(Theme.textSecondary) } }
                    .chartYAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(Theme.textSecondary) } }
                    .frame(height: 200)

                    HStack(spacing: 16) {
                        HStack(spacing: 4) { Circle().fill(Theme.xpGreen).frame(width: 8, height: 8); Text("Fitness").font(.caption2).foregroundStyle(Theme.textSecondary) }
                        HStack(spacing: 4) { Circle().fill(Theme.secondaryAccent).frame(width: 8, height: 8); Text("Work").font(.caption2).foregroundStyle(Theme.textSecondary) }
                        HStack(spacing: 4) { Circle().fill(Theme.primaryAccent).frame(width: 8, height: 8); Text("Learning").font(.caption2).foregroundStyle(Theme.textSecondary) }
                    }
                }
            }
            .padding(Theme.cardPadding)
        }
    }

    // -- Insights
    private var insightsSection: some View {
        let insights = InsightEngine.generate(
            gymSessions: gymSessions,
            cardioSessions: cardioSessions,
            foodEntries: foodEntries,
            habitLogs: habitLogs,
            deals: deals,
            paralaiEntries: paralaiEntries,
            otherWorkLogs: otherWorkLogs,
            courses: courses,
            books: books,
            user: user
        )

        return VStack(alignment: .leading, spacing: 12) {
            if !insights.isEmpty {
                SectionHeader(title: "Insights")
                ForEach(insights) { insight in
                    Card {
                        HStack(spacing: 14) {
                            Image(systemName: trendIcon(insight.trend))
                                .font(.title3)
                                .foregroundStyle(trendColor(insight.trend))
                                .frame(width: 40, height: 40)
                                .background(trendColor(insight.trend).opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(insight.text)
                                    .font(.subheadline).fontWeight(.semibold)
                                    .foregroundStyle(Theme.textPrimary)
                                Text(insight.stat)
                                    .font(.caption).monospacedDigit()
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(Theme.cardPadding)
                    }
                }
            }
        }
    }

    private func trendIcon(_ trend: Insight.Trend) -> String {
        switch trend {
        case .up:      return "arrow.up.right"
        case .down:    return "arrow.down.right"
        case .neutral: return "arrow.right"
        }
    }

    private func trendColor(_ trend: Insight.Trend) -> Color {
        switch trend {
        case .up:      return Theme.xpGreen
        case .down:    return .red
        case .neutral: return Theme.secondaryAccent
        }
    }

    // ============================================================
    // MARK: - Helpers
    // ============================================================

    private func emptyState(_ message: String, icon: String) -> some View {
        Card {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Theme.textSecondary)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.cardPadding)
        }
    }

    // MARK: - Export

    private func exportData() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "levelup-export.json"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            let repo = StatsRepository(context: context)
            let data = buildExportJSON(repo: repo)
            try? data.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func buildExportJSON(repo: StatsRepository) -> String {
        var dict: [String: Any] = [:]
        dict["exportDate"] = ISO8601DateFormatter().string(from: .now)
        dict["user"] = ["name": user.name, "totalXP": user.totalXP,
                        "fitnessXP": user.fitnessXP, "workXP": user.workXP,
                        "learningXP": user.learningXP]

        // Fitness
        let gym = repo.allGymSessions().map { s in
            ["date": ISO8601DateFormatter().string(from: s.date),
             "splitDay": s.splitDay, "intensity": s.intensityRaw,
             "xpEarned": s.xpEarned] as [String: Any]
        }
        dict["gymSessions"] = gym

        let weight = repo.allWeightEntries().map { w in
            ["date": ISO8601DateFormatter().string(from: w.date),
             "weightKg": w.weightKg] as [String: Any]
        }
        dict["weightEntries"] = weight

        // Work
        let otherWork = repo.allOtherWorkLogs().map { o in
            ["date": ISO8601DateFormatter().string(from: o.date),
             "project": o.projectName, "type": o.actionType,
             "title": o.title, "hours": o.hoursSpent,
             "xp": o.xpEarned] as [String: Any]
        }
        dict["otherWorkLogs"] = otherWork

        // Serialize
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict,
                                                         options: [.prettyPrinted, .sortedKeys]) else {
            return "{}"
        }
        return String(data: jsonData, encoding: .utf8) ?? "{}"
    }
}
