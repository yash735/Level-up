//
//  InsightEngine.swift
//  LEVEL UP — Phase 4
//
//  Computes data-driven correlation insights from actual SwiftData
//  records. Each insight is a plain string with a supporting number
//  and optional trend direction.
//

import Foundation

struct Insight: Identifiable {
    let id = UUID()
    let text: String
    let stat: String
    let trend: Trend

    enum Trend {
        case up, down, neutral
    }
}

enum InsightEngine {

    static func generate(
        gymSessions: [GymSession],
        cardioSessions: [CardioSession],
        foodEntries: [FoodEntry],
        habitLogs: [HabitLog],
        deals: [Deal],
        paralaiEntries: [ParaLAIEntry],
        otherWorkLogs: [OtherWorkLog],
        courses: [Course],
        books: [Book],
        user: User
    ) -> [Insight] {
        var insights: [Insight] = []
        let cal = Calendar.current
        let now = Date.now

        // 1. Average workouts per week
        let allWorkouts = gymSessions.filter { !$0.isRestDay }
        if let earliest = allWorkouts.first?.date {
            let weeks = max(1, cal.dateComponents([.weekOfYear], from: earliest, to: now).weekOfYear ?? 1)
            let avg = Double(allWorkouts.count) / Double(weeks)
            insights.append(.init(
                text: "You average \(String(format: "%.1f", avg)) workouts per week",
                stat: String(format: "%.1f/wk", avg),
                trend: avg >= 3 ? .up : (avg >= 2 ? .neutral : .down)
            ))
        }

        // 2. Best gym day of week
        if !allWorkouts.isEmpty {
            var dayCount: [Int: Int] = [:]
            for s in allWorkouts {
                let wd = cal.component(.weekday, from: s.date)
                dayCount[wd, default: 0] += 1
            }
            if let best = dayCount.max(by: { $0.value < $1.value }) {
                let dayName = cal.weekdaySymbols[best.key - 1]
                insights.append(.init(
                    text: "Your best gym day is \(dayName)s",
                    stat: "\(best.value) sessions",
                    trend: .neutral
                ))
            }
        }

        // 3. Gym consistency this month
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: now))!
        let daysInMonth = cal.range(of: .day, in: .month, for: now)?.count ?? 30
        let daysSoFar = cal.component(.day, from: now)
        let expectedSessions = Int(Double(daysSoFar) / 7.0 * 5.0)
        let actualThisMonth = allWorkouts.filter { $0.date >= monthStart }.count
        if expectedSessions > 0 {
            let pct = min(100, Int(Double(actualThisMonth) / Double(max(1, expectedSessions)) * 100))
            insights.append(.init(
                text: "Your gym consistency is \(pct)% this month",
                stat: "\(actualThisMonth)/\(expectedSessions)",
                trend: pct >= 80 ? .up : (pct >= 50 ? .neutral : .down)
            ))
        }

        // 4. Best study day
        if !paralaiEntries.isEmpty || !otherWorkLogs.isEmpty {
            var dayXP: [Int: Int] = [:]
            for e in paralaiEntries {
                let wd = cal.component(.weekday, from: e.date)
                dayXP[wd, default: 0] += e.xpEarned
            }
            for o in otherWorkLogs {
                let wd = cal.component(.weekday, from: o.date)
                dayXP[wd, default: 0] += o.xpEarned
            }
            if let best = dayXP.max(by: { $0.value < $1.value }) {
                let dayName = cal.weekdaySymbols[best.key - 1]
                insights.append(.init(
                    text: "You log the most work XP on \(dayName)s",
                    stat: "\(best.value) XP total",
                    trend: .neutral
                ))
            }
        }

        // 5. Workout-study correlation
        if !allWorkouts.isEmpty {
            var workoutDays = Set<String>()
            var noWorkoutDays = Set<String>()
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"

            for s in allWorkouts {
                workoutDays.insert(fmt.string(from: s.date))
            }

            // Check work XP on workout days vs non-workout days
            var xpOnWorkoutDays = 0
            var xpOnOtherDays = 0
            var wdCount = 0
            var odCount = 0

            for entry in paralaiEntries + otherWorkLogs.map({
                // Quick adapter — just need date and xpEarned
                let e = ParaLAIEntry(date: $0.date, actionType: "other",
                                     title: "", detail: "",
                                     hoursSpent: 0, xpEarned: $0.xpEarned)
                return e
            }) {
                let key = fmt.string(from: entry.date)
                if workoutDays.contains(key) {
                    xpOnWorkoutDays += entry.xpEarned
                    wdCount += 1
                } else {
                    xpOnOtherDays += entry.xpEarned
                    odCount += 1
                }
            }

            let avgWD = wdCount > 0 ? Double(xpOnWorkoutDays) / Double(wdCount) : 0
            let avgOD = odCount > 0 ? Double(xpOnOtherDays) / Double(odCount) : 0
            if avgOD > 0 && avgWD > avgOD {
                let pct = Int(((avgWD - avgOD) / avgOD) * 100)
                if pct > 10 {
                    insights.append(.init(
                        text: "You earn \(pct)% more Work XP on days you work out",
                        stat: "+\(pct)%",
                        trend: .up
                    ))
                }
            }
        }

        return Array(insights.prefix(5))
    }
}
