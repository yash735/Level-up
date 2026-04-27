import Foundation
import SwiftData

enum ExportImportEngine {

    // MARK: - Export

    @MainActor
    static func exportAll(user: User, context: ModelContext) -> Data? {
        let repo = StatsRepository(context: context)
        let iso = ISO8601DateFormatter()

        var root: [String: Any] = [
            "version": 1,
            "exportDate": iso.string(from: .now)
        ]

        // User
        root["user"] = [
            "name": user.name,
            "fitnessXP": user.fitnessXP,
            "workXP": user.workXP,
            "learningXP": user.learningXP,
            "currentStreak": user.currentStreak,
            "longestStreak": user.longestStreak,
            "lastActiveDate": user.lastActiveDate.map { iso.string(from: $0) } as Any,
            "activeMultiplier": user.activeMultiplier as Any,
            "multiplierExpiryDate": user.multiplierExpiryDate.map { iso.string(from: $0) } as Any
        ] as [String: Any]

        // Gym sessions + exercises
        root["gymSessions"] = repo.allGymSessions().map { s in
            [
                "date": iso.string(from: s.date),
                "splitDay": s.splitDay,
                "intensity": s.intensityRaw,
                "xpEarned": s.xpEarned,
                "isRestDay": s.isRestDay,
                "notes": s.notes,
                "exercises": s.exercises.map { e in
                    ["name": e.name, "sets": e.sets, "reps": e.reps,
                     "weightKg": e.weightKg, "notes": e.notes] as [String: Any]
                }
            ] as [String: Any]
        }

        // Cardio
        root["cardioSessions"] = repo.allCardioSessions().map { c in
            ["date": iso.string(from: c.date), "type": c.type,
             "durationMinutes": c.durationMinutes, "intensity": c.intensityRaw,
             "distanceKm": c.distanceKm, "notes": c.notes,
             "xpEarned": c.xpEarned] as [String: Any]
        }

        // Food
        root["foodEntries"] = repo.allFoodEntries().map { f in
            ["date": iso.string(from: f.date), "mealType": f.mealType,
             "foodName": f.foodName, "calories": f.calories,
             "protein": f.protein, "carbs": f.carbs, "fats": f.fats,
             "xpEarned": f.xpEarned] as [String: Any]
        }

        // Weight
        root["weightEntries"] = repo.allWeightEntries().map { w in
            ["date": iso.string(from: w.date), "weightKg": w.weightKg,
             "notes": w.notes, "xpEarned": w.xpEarned] as [String: Any]
        }

        // Habits
        root["habitLogs"] = repo.allHabitLogs().map { h in
            ["date": iso.string(from: h.date), "sleep": h.sleep, "water": h.water,
             "steps": h.steps, "noJunk": h.noJunk, "morningWorkout": h.morningWorkout,
             "eveningStretch": h.eveningStretch, "bonusAwarded": h.bonusAwarded,
             "xpEarned": h.xpEarned] as [String: Any]
        }

        // Projects with milestones and entries
        root["projects"] = repo.allProjects().map { p in
            [
                "name": p.name,
                "description": p.projectDescription,
                "colorHex": p.colorHex,
                "iconName": p.iconName,
                "isArchived": p.isArchived,
                "orderIndex": p.orderIndex,
                "createdAt": iso.string(from: p.createdAt),
                "milestones": p.milestones.sorted(by: { $0.orderIndex < $1.orderIndex }).map { m in
                    ["title": m.title, "isCompleted": m.isCompleted,
                     "completedAt": m.completedAt.map { iso.string(from: $0) } as Any,
                     "xpAwarded": m.xpAwarded, "isAISuggested": m.isAISuggested,
                     "orderIndex": m.orderIndex] as [String: Any]
                },
                "entries": p.entries.sorted(by: { $0.date < $1.date }).map { e in
                    ["date": iso.string(from: e.date), "actionType": e.actionType,
                     "title": e.title, "detail": e.detail,
                     "hoursSpent": e.hoursSpent, "xpEarned": e.xpEarned] as [String: Any]
                }
            ] as [String: Any]
        }

        // Quick tasks (WorkEntries without a project)
        let allWorkDesc = FetchDescriptor<WorkEntry>(sortBy: [SortDescriptor(\.date)])
        let allWork = (try? context.fetch(allWorkDesc)) ?? []
        root["quickTasks"] = allWork.filter { $0.project == nil }.map { e in
            ["date": iso.string(from: e.date), "actionType": e.actionType,
             "title": e.title, "detail": e.detail,
             "hoursSpent": e.hoursSpent, "xpEarned": e.xpEarned] as [String: Any]
        }

        // Daily todos
        let todoDesc = FetchDescriptor<DailyTodoItem>(sortBy: [SortDescriptor(\.date)])
        let allTodos = (try? context.fetch(todoDesc)) ?? []
        root["dailyTodos"] = allTodos.map { item in
            ["date": iso.string(from: item.date),
             "title": item.title,
             "isCompleted": item.isCompleted,
             "orderIndex": item.orderIndex,
             "createdAt": iso.string(from: item.createdAt)] as [String: Any]
        }

        // Courses
        root["courses"] = repo.allCourses().map { c in
            ["name": c.name, "platform": c.platform, "category": c.category,
             "totalLessons": c.totalLessons, "completedLessons": c.completedLessons,
             "totalHours": c.totalHours, "xpEarned": c.xpEarned,
             "isCompleted": c.isCompleted, "startedAt": iso.string(from: c.startedAt),
             "completedAt": c.completedAt.map { iso.string(from: $0) } as Any] as [String: Any]
        }

        // Books
        root["books"] = repo.allBooks().map { b in
            ["title": b.title, "author": b.author, "category": b.category,
             "totalPages": b.totalPages, "pagesRead": b.pagesRead,
             "totalHours": b.totalHours, "xpEarned": b.xpEarned,
             "isFinished": b.isFinished, "startedAt": iso.string(from: b.startedAt),
             "finishedAt": b.finishedAt.map { iso.string(from: $0) } as Any] as [String: Any]
        }

        // Certifications
        root["certifications"] = repo.allCertifications().map { c in
            ["name": c.name, "issuingBody": c.issuingBody,
             "estimatedHours": c.estimatedHours, "studiedHours": c.studiedHours,
             "xpEarned": c.xpEarned, "isEarned": c.isEarned,
             "earnedAt": c.earnedAt.map { iso.string(from: $0) } as Any,
             "targetDate": c.targetDate.map { iso.string(from: $0) } as Any] as [String: Any]
        }

        // Learning logs
        let learnDesc = FetchDescriptor<LearningLog>(sortBy: [SortDescriptor(\.date)])
        let learningLogs = (try? context.fetch(learnDesc)) ?? []
        root["learningLogs"] = learningLogs.map { l in
            ["date": iso.string(from: l.date), "type": l.type, "name": l.name,
             "hoursStudied": l.hoursStudied, "xpEarned": l.xpEarned,
             "notes": l.notes] as [String: Any]
        }

        // Personal records
        let prDesc = FetchDescriptor<PersonalRecord>(sortBy: [SortDescriptor(\.date)])
        let personalRecords = (try? context.fetch(prDesc)) ?? []
        root["personalRecords"] = personalRecords.map { r in
            ["date": iso.string(from: r.date), "key": r.key, "track": r.track,
             "title": r.title, "value": r.value,
             "pendingCelebration": r.pendingCelebration] as [String: Any]
        }

        // Gym split state (singleton)
        let splitDesc = FetchDescriptor<GymSplitState>()
        if let split = (try? context.fetch(splitDesc))?.first {
            root["gymSplitState"] = [
                "currentDayIndex": split.currentDayIndex,
                "lastGymDate": split.lastGymDate.map { iso.string(from: $0) } as Any,
                "currentStreak": split.currentStreak,
                "longestStreak": split.longestStreak,
                "lastPerfectWeekKey": split.lastPerfectWeekKey,
                "lastMondayBonusKey": split.lastMondayBonusKey
            ] as [String: Any]
        }

        // Weekly reports
        let reportDesc = FetchDescriptor<WeeklyReport>(sortBy: [SortDescriptor(\.weekStartDate)])
        let reports = (try? context.fetch(reportDesc)) ?? []
        root["weeklyReports"] = reports.map { r in
            ["weekStartDate": iso.string(from: r.weekStartDate),
             "weekEndDate": iso.string(from: r.weekEndDate),
             "totalXP": r.totalXP, "fitnessXP": r.fitnessXP,
             "workXP": r.workXP, "learningXP": r.learningXP,
             "workoutsCompleted": r.workoutsCompleted,
             "gymSessionsCompleted": r.gymSessionsCompleted,
             "bvaActionsCount": r.bvaActionsCount,
             "paralaiLogsCount": r.paralaiLogsCount,
             "otherWorkHours": r.otherWorkHours,
             "studyHours": r.studyHours,
             "habitsCompletionRate": r.habitsCompletionRate,
             "xpChangeVsLastWeek": r.xpChangeVsLastWeek,
             "grade": r.grade, "summaryText": r.summaryText,
             "createdAt": iso.string(from: r.createdAt),
             "workEntriesCount": r.workEntriesCount as Any] as [String: Any]
        }

        // Weekly challenges
        let challengeDesc = FetchDescriptor<WeeklyChallenge>(sortBy: [SortDescriptor(\.weekStartDate)])
        let challenges = (try? context.fetch(challengeDesc)) ?? []
        root["weeklyChallenges"] = challenges.map { c in
            ["weekStartDate": iso.string(from: c.weekStartDate),
             "challengeType": c.challengeType, "title": c.title,
             "challengeDescription": c.challengeDescription,
             "targetValue": c.targetValue, "currentValue": c.currentValue,
             "xpReward": c.xpReward, "tier": c.tier,
             "isCompleted": c.isCompleted,
             "completedAt": c.completedAt.map { iso.string(from: $0) } as Any,
             "isFailed": c.isFailed, "stretchBonus": c.stretchBonus,
             "isMegaChallenge": c.isMegaChallenge] as [String: Any]
        }

        // Achievements
        let achieveDesc = FetchDescriptor<Achievement>()
        let achievements = (try? context.fetch(achieveDesc)) ?? []
        root["achievements"] = achievements.map { a in
            ["key": a.key, "title": a.title,
             "achievementDescription": a.achievementDescription,
             "track": a.track, "iconName": a.iconName,
             "isEarned": a.isEarned,
             "earnedAt": a.earnedAt.map { iso.string(from: $0) } as Any] as [String: Any]
        }

        // Unlocks
        let unlockDesc = FetchDescriptor<Unlock>()
        let unlocks = (try? context.fetch(unlockDesc)) ?? []
        root["unlocks"] = unlocks.map { u in
            ["track": u.track, "title": u.title, "detail": u.detail,
             "xpRequired": u.xpRequired, "levelRequired": u.levelRequired,
             "isUnlocked": u.isUnlocked, "iconName": u.iconName,
             "unlockedAt": u.unlockedAt.map { iso.string(from: $0) } as Any] as [String: Any]
        }

        // Login streak (singleton)
        let loginDesc = FetchDescriptor<LoginStreak>()
        if let ls = (try? context.fetch(loginDesc))?.first {
            root["loginStreak"] = [
                "lastBonusDate": ls.lastBonusDate.map { iso.string(from: $0) } as Any,
                "currentStreak": ls.currentStreak,
                "longestStreak": ls.longestStreak,
                "totalLoginDays": ls.totalLoginDays
            ] as [String: Any]
        }

        // Rank streak state (singleton)
        let rankDesc = FetchDescriptor<RankStreakState>()
        if let rs = (try? context.fetch(rankDesc))?.first {
            root["rankStreakState"] = [
                "currentSRankStreak": rs.currentSRankStreak,
                "currentARankStreak": rs.currentARankStreak,
                "lastWeekRank": rs.lastWeekRank,
                "xpMultiplierActive": rs.xpMultiplierActive,
                "xpMultiplierValue": rs.xpMultiplierValue,
                "xpMultiplierExpiryDate": rs.xpMultiplierExpiryDate.map { iso.string(from: $0) } as Any,
                "doubleXPWeeksRemaining": rs.doubleXPWeeksRemaining,
                "hasEarnedFirstSRank": rs.hasEarnedFirstSRank
            ] as [String: Any]
        }

        // Balanced day logs
        let balancedDesc = FetchDescriptor<BalancedDayLog>(sortBy: [SortDescriptor(\.date)])
        let balancedLogs = (try? context.fetch(balancedDesc)) ?? []
        root["balancedDayLogs"] = balancedLogs.map { b in
            ["date": iso.string(from: b.date), "fitnessXP": b.fitnessXP,
             "workXP": b.workXP, "learningXP": b.learningXP,
             "totalBonus": b.totalBonus,
             "streakAtAward": b.streakAtAward] as [String: Any]
        }

        // Founder week logs
        let founderDesc = FetchDescriptor<FounderWeekLog>(sortBy: [SortDescriptor(\.weekStartDate)])
        let founderLogs = (try? context.fetch(founderDesc)) ?? []
        root["founderWeekLogs"] = founderLogs.map { f in
            ["weekStartDate": iso.string(from: f.weekStartDate),
             "bvaDealClosed": f.bvaDealClosed,
             "paralaiMilestone": f.paralaiMilestone,
             "xpAwarded": f.xpAwarded,
             "achievedAt": iso.string(from: f.achievedAt)] as [String: Any]
        }

        // Baseline stats
        let baselineDesc = FetchDescriptor<BaselineStats>(sortBy: [SortDescriptor(\.weekOf)])
        let baselines = (try? context.fetch(baselineDesc)) ?? []
        root["baselineStats"] = baselines.map { b in
            ["weekOf": iso.string(from: b.weekOf),
             "avgWorkHours": b.avgWorkHours,
             "avgGymSessions": b.avgGymSessions,
             "avgStudyHours": b.avgStudyHours,
             "avgHabitsRate": b.avgHabitsRate,
             "avgBVAActions": b.avgBVAActions,
             "avgDeepWorkSessions": b.avgDeepWorkSessions] as [String: Any]
        }

        // Season carryover
        let seasonDesc = FetchDescriptor<SeasonCarryover>()
        let seasons = (try? context.fetch(seasonDesc)) ?? []
        root["seasonCarryovers"] = seasons.map { s in
            ["fromSeason": s.fromSeason, "toSeason": s.toSeason,
             "rewardType": s.rewardType, "xpMultiplier": s.xpMultiplier,
             "xpBonus": s.xpBonus, "isActive": s.isActive,
             "expiryDate": s.expiryDate.map { iso.string(from: $0) } as Any] as [String: Any]
        }

        return try? JSONSerialization.data(withJSONObject: root,
                                           options: [.prettyPrinted, .sortedKeys])
    }

    // MARK: - Import

    @MainActor
    static func importAll(from data: Data, user: User, context: ModelContext) throws {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ImportError.invalidFormat
        }

        let iso = ISO8601DateFormatter()

        // Restore user XP
        if let u = root["user"] as? [String: Any] {
            user.fitnessXP = u["fitnessXP"] as? Int ?? user.fitnessXP
            user.workXP = u["workXP"] as? Int ?? user.workXP
            user.learningXP = u["learningXP"] as? Int ?? user.learningXP
            user.currentStreak = u["currentStreak"] as? Int ?? user.currentStreak
            user.longestStreak = u["longestStreak"] as? Int ?? user.longestStreak
            if let name = u["name"] as? String { user.name = name }
            if let dateStr = u["lastActiveDate"] as? String {
                user.lastActiveDate = iso.date(from: dateStr)
            }
            if let mult = u["activeMultiplier"] as? Double {
                user.activeMultiplier = mult
            }
            if let dateStr = u["multiplierExpiryDate"] as? String {
                user.multiplierExpiryDate = iso.date(from: dateStr)
            }
        }

        // Gym sessions
        if let items = root["gymSessions"] as? [[String: Any]] {
            for item in items {
                guard let dateStr = item["date"] as? String,
                      let date = iso.date(from: dateStr) else { continue }
                let s = GymSession(
                    date: date,
                    splitDay: item["splitDay"] as? String ?? "Upper",
                    intensity: XPEngine.FitnessIntensity(rawValue: item["intensity"] as? String ?? "medium") ?? .medium,
                    isRestDay: item["isRestDay"] as? Bool ?? false,
                    notes: item["notes"] as? String ?? ""
                )
                s.xpEarned = item["xpEarned"] as? Int ?? 0
                context.insert(s)

                if let exercises = item["exercises"] as? [[String: Any]] {
                    for ex in exercises {
                        let e = Exercise(
                            name: ex["name"] as? String ?? "",
                            sets: ex["sets"] as? Int ?? 0,
                            reps: ex["reps"] as? Int ?? 0,
                            weightKg: ex["weightKg"] as? Double ?? 0,
                            notes: ex["notes"] as? String ?? ""
                        )
                        s.exercises.append(e)
                        context.insert(e)
                    }
                }
            }
        }

        // Cardio
        if let items = root["cardioSessions"] as? [[String: Any]] {
            for item in items {
                guard let dateStr = item["date"] as? String,
                      let date = iso.date(from: dateStr) else { continue }
                let c = CardioSession(
                    date: date,
                    type: item["type"] as? String ?? "Run",
                    durationMinutes: item["durationMinutes"] as? Int ?? 0,
                    intensity: XPEngine.FitnessIntensity(rawValue: item["intensity"] as? String ?? "medium") ?? .medium,
                    distanceKm: item["distanceKm"] as? Double ?? 0,
                    notes: item["notes"] as? String ?? ""
                )
                c.xpEarned = item["xpEarned"] as? Int ?? 0
                context.insert(c)
            }
        }

        // Food
        if let items = root["foodEntries"] as? [[String: Any]] {
            for item in items {
                guard let dateStr = item["date"] as? String,
                      let date = iso.date(from: dateStr) else { continue }
                let f = FoodEntry(
                    date: date,
                    mealType: item["mealType"] as? String ?? "Lunch",
                    foodName: item["foodName"] as? String ?? "",
                    calories: item["calories"] as? Int ?? 0,
                    protein: item["protein"] as? Double ?? 0,
                    carbs: item["carbs"] as? Double ?? 0,
                    fats: item["fats"] as? Double ?? 0
                )
                f.xpEarned = item["xpEarned"] as? Int ?? 0
                context.insert(f)
            }
        }

        // Weight
        if let items = root["weightEntries"] as? [[String: Any]] {
            for item in items {
                guard let dateStr = item["date"] as? String,
                      let date = iso.date(from: dateStr) else { continue }
                let w = WeightEntry(
                    date: date,
                    weightKg: item["weightKg"] as? Double ?? 0,
                    notes: item["notes"] as? String ?? ""
                )
                w.xpEarned = item["xpEarned"] as? Int ?? 0
                context.insert(w)
            }
        }

        // Habits
        if let items = root["habitLogs"] as? [[String: Any]] {
            for item in items {
                guard let dateStr = item["date"] as? String,
                      let date = iso.date(from: dateStr) else { continue }
                let h = HabitLog(date: date)
                h.sleep = item["sleep"] as? Bool ?? false
                h.water = item["water"] as? Bool ?? false
                h.steps = item["steps"] as? Bool ?? false
                h.noJunk = item["noJunk"] as? Bool ?? false
                h.morningWorkout = item["morningWorkout"] as? Bool ?? false
                h.eveningStretch = item["eveningStretch"] as? Bool ?? false
                h.bonusAwarded = item["bonusAwarded"] as? Bool ?? false
                h.xpEarned = item["xpEarned"] as? Int ?? 0
                context.insert(h)
            }
        }

        // Projects + milestones + entries
        if let items = root["projects"] as? [[String: Any]] {
            for item in items {
                let p = Project(
                    name: item["name"] as? String ?? "Untitled",
                    projectDescription: item["description"] as? String ?? "",
                    colorHex: item["colorHex"] as? String ?? "#FF9500",
                    iconName: item["iconName"] as? String ?? "folder.fill",
                    orderIndex: item["orderIndex"] as? Int ?? 0
                )
                p.isArchived = item["isArchived"] as? Bool ?? false
                if let createdStr = item["createdAt"] as? String,
                   let created = iso.date(from: createdStr) {
                    p.createdAt = created
                }
                context.insert(p)

                if let milestones = item["milestones"] as? [[String: Any]] {
                    for m in milestones {
                        let ms = ProjectMilestone(
                            project: p,
                            title: m["title"] as? String ?? "",
                            isAISuggested: m["isAISuggested"] as? Bool ?? false,
                            orderIndex: m["orderIndex"] as? Int ?? 0
                        )
                        ms.isCompleted = m["isCompleted"] as? Bool ?? false
                        ms.xpAwarded = m["xpAwarded"] as? Bool ?? false
                        if let compStr = m["completedAt"] as? String {
                            ms.completedAt = iso.date(from: compStr)
                        }
                        context.insert(ms)
                    }
                }

                if let entries = item["entries"] as? [[String: Any]] {
                    for e in entries {
                        guard let dateStr = e["date"] as? String,
                              let date = iso.date(from: dateStr) else { continue }
                        let we = WorkEntry(
                            project: p,
                            date: date,
                            actionType: e["actionType"] as? String ?? "Other",
                            title: e["title"] as? String ?? "",
                            detail: e["detail"] as? String ?? "",
                            hoursSpent: e["hoursSpent"] as? Double ?? 0,
                            xpEarned: e["xpEarned"] as? Int ?? 0
                        )
                        context.insert(we)
                    }
                }
            }
        }

        // Quick tasks (WorkEntries without a project)
        if let items = root["quickTasks"] as? [[String: Any]] {
            for item in items {
                guard let dateStr = item["date"] as? String,
                      let date = iso.date(from: dateStr) else { continue }
                let we = WorkEntry(
                    date: date,
                    actionType: item["actionType"] as? String ?? "Other",
                    title: item["title"] as? String ?? "",
                    detail: item["detail"] as? String ?? "",
                    hoursSpent: item["hoursSpent"] as? Double ?? 0,
                    xpEarned: item["xpEarned"] as? Int ?? 0
                )
                context.insert(we)
            }
        }

        // Daily todos
        if let arr = root["dailyTodos"] as? [[String: Any]] {
            for dict in arr {
                let item = DailyTodoItem(title: dict["title"] as? String ?? "")
                if let ds = dict["date"] as? String, let d = iso.date(from: ds) {
                    item.date = d
                }
                item.isCompleted = dict["isCompleted"] as? Bool ?? false
                item.orderIndex = dict["orderIndex"] as? Int ?? 0
                if let cs = dict["createdAt"] as? String, let c = iso.date(from: cs) {
                    item.createdAt = c
                }
                context.insert(item)
            }
        }

        // Courses
        if let items = root["courses"] as? [[String: Any]] {
            for item in items {
                let c = Course(
                    name: item["name"] as? String ?? "",
                    platform: item["platform"] as? String ?? "",
                    category: item["category"] as? String ?? "",
                    totalLessons: item["totalLessons"] as? Int ?? 0
                )
                c.completedLessons = item["completedLessons"] as? Int ?? 0
                c.totalHours = item["totalHours"] as? Double ?? 0
                c.xpEarned = item["xpEarned"] as? Int ?? 0
                c.isCompleted = item["isCompleted"] as? Bool ?? false
                if let startStr = item["startedAt"] as? String {
                    c.startedAt = iso.date(from: startStr) ?? .now
                }
                if let compStr = item["completedAt"] as? String {
                    c.completedAt = iso.date(from: compStr)
                }
                context.insert(c)
            }
        }

        // Books
        if let items = root["books"] as? [[String: Any]] {
            for item in items {
                let b = Book(
                    title: item["title"] as? String ?? "",
                    author: item["author"] as? String ?? "",
                    category: item["category"] as? String ?? "",
                    totalPages: item["totalPages"] as? Int ?? 0
                )
                b.pagesRead = item["pagesRead"] as? Int ?? 0
                b.totalHours = item["totalHours"] as? Double ?? 0
                b.xpEarned = item["xpEarned"] as? Int ?? 0
                b.isFinished = item["isFinished"] as? Bool ?? false
                if let startStr = item["startedAt"] as? String {
                    b.startedAt = iso.date(from: startStr) ?? .now
                }
                if let finStr = item["finishedAt"] as? String {
                    b.finishedAt = iso.date(from: finStr)
                }
                context.insert(b)
            }
        }

        // Certifications
        if let items = root["certifications"] as? [[String: Any]] {
            for item in items {
                let c = Certification(
                    name: item["name"] as? String ?? "",
                    issuingBody: item["issuingBody"] as? String ?? "",
                    estimatedHours: item["estimatedHours"] as? Double ?? 0
                )
                c.studiedHours = item["studiedHours"] as? Double ?? 0
                c.xpEarned = item["xpEarned"] as? Int ?? 0
                c.isEarned = item["isEarned"] as? Bool ?? false
                if let earnedStr = item["earnedAt"] as? String {
                    c.earnedAt = iso.date(from: earnedStr)
                }
                if let targetStr = item["targetDate"] as? String {
                    c.targetDate = iso.date(from: targetStr)
                }
                context.insert(c)
            }
        }

        // Learning logs
        if let items = root["learningLogs"] as? [[String: Any]] {
            for item in items {
                guard let dateStr = item["date"] as? String,
                      let date = iso.date(from: dateStr) else { continue }
                let l = LearningLog(
                    type: item["type"] as? String ?? "",
                    name: item["name"] as? String ?? "",
                    hoursStudied: item["hoursStudied"] as? Double ?? 0,
                    xpEarned: item["xpEarned"] as? Int ?? 0,
                    notes: item["notes"] as? String ?? "",
                    date: date
                )
                context.insert(l)
            }
        }

        // Personal records
        if let items = root["personalRecords"] as? [[String: Any]] {
            for item in items {
                guard let dateStr = item["date"] as? String,
                      let date = iso.date(from: dateStr) else { continue }
                let r = PersonalRecord(
                    key: item["key"] as? String ?? "",
                    track: item["track"] as? String ?? "",
                    title: item["title"] as? String ?? "",
                    value: item["value"] as? String ?? "",
                    date: date
                )
                r.pendingCelebration = item["pendingCelebration"] as? Bool ?? false
                context.insert(r)
            }
        }

        // Gym split state (singleton — replace existing)
        if let item = root["gymSplitState"] as? [String: Any] {
            let existingDesc = FetchDescriptor<GymSplitState>()
            let existing = (try? context.fetch(existingDesc)) ?? []
            for old in existing { context.delete(old) }

            let s = GymSplitState()
            s.currentDayIndex = item["currentDayIndex"] as? Int ?? 0
            if let dateStr = item["lastGymDate"] as? String {
                s.lastGymDate = iso.date(from: dateStr)
            }
            s.currentStreak = item["currentStreak"] as? Int ?? 0
            s.longestStreak = item["longestStreak"] as? Int ?? 0
            s.lastPerfectWeekKey = item["lastPerfectWeekKey"] as? String ?? ""
            s.lastMondayBonusKey = item["lastMondayBonusKey"] as? String ?? ""
            context.insert(s)
        }

        // Weekly reports
        if let items = root["weeklyReports"] as? [[String: Any]] {
            for item in items {
                guard let startStr = item["weekStartDate"] as? String,
                      let start = iso.date(from: startStr),
                      let endStr = item["weekEndDate"] as? String,
                      let end = iso.date(from: endStr) else { continue }
                let r = WeeklyReport(
                    weekStartDate: start,
                    weekEndDate: end,
                    totalXP: item["totalXP"] as? Int ?? 0,
                    fitnessXP: item["fitnessXP"] as? Int ?? 0,
                    workXP: item["workXP"] as? Int ?? 0,
                    learningXP: item["learningXP"] as? Int ?? 0,
                    workoutsCompleted: item["workoutsCompleted"] as? Int ?? 0,
                    gymSessionsCompleted: item["gymSessionsCompleted"] as? Int ?? 0,
                    bvaActionsCount: item["bvaActionsCount"] as? Int ?? 0,
                    paralaiLogsCount: item["paralaiLogsCount"] as? Int ?? 0,
                    otherWorkHours: item["otherWorkHours"] as? Double ?? 0,
                    studyHours: item["studyHours"] as? Double ?? 0,
                    habitsCompletionRate: item["habitsCompletionRate"] as? Double ?? 0,
                    xpChangeVsLastWeek: item["xpChangeVsLastWeek"] as? Double ?? 0,
                    grade: item["grade"] as? String ?? "C",
                    summaryText: item["summaryText"] as? String ?? "",
                    workEntriesCount: item["workEntriesCount"] as? Int
                )
                if let createdStr = item["createdAt"] as? String,
                   let created = iso.date(from: createdStr) {
                    r.createdAt = created
                }
                context.insert(r)
            }
        }

        // Weekly challenges
        if let items = root["weeklyChallenges"] as? [[String: Any]] {
            for item in items {
                guard let startStr = item["weekStartDate"] as? String,
                      let start = iso.date(from: startStr) else { continue }
                let c = WeeklyChallenge(
                    weekStartDate: start,
                    challengeType: item["challengeType"] as? String ?? "",
                    title: item["title"] as? String ?? "",
                    description: item["challengeDescription"] as? String ?? "",
                    targetValue: item["targetValue"] as? Double ?? 0,
                    xpReward: item["xpReward"] as? Int ?? 0,
                    tier: item["tier"] as? Int ?? 1,
                    isMegaChallenge: item["isMegaChallenge"] as? Bool ?? false
                )
                c.currentValue = item["currentValue"] as? Double ?? 0
                c.isCompleted = item["isCompleted"] as? Bool ?? false
                if let compStr = item["completedAt"] as? String {
                    c.completedAt = iso.date(from: compStr)
                }
                c.isFailed = item["isFailed"] as? Bool ?? false
                c.stretchBonus = item["stretchBonus"] as? Int ?? 0
                context.insert(c)
            }
        }

        // Achievements
        if let items = root["achievements"] as? [[String: Any]] {
            for item in items {
                let a = Achievement(
                    key: item["key"] as? String ?? "",
                    title: item["title"] as? String ?? "",
                    description: item["achievementDescription"] as? String ?? "",
                    track: item["track"] as? String ?? "combined",
                    iconName: item["iconName"] as? String ?? "star.fill"
                )
                a.isEarned = item["isEarned"] as? Bool ?? false
                if let earnedStr = item["earnedAt"] as? String {
                    a.earnedAt = iso.date(from: earnedStr)
                }
                context.insert(a)
            }
        }

        // Unlocks
        if let items = root["unlocks"] as? [[String: Any]] {
            for item in items {
                let u = Unlock(
                    track: item["track"] as? String ?? "combined",
                    title: item["title"] as? String ?? "",
                    detail: item["detail"] as? String ?? "",
                    levelRequired: item["levelRequired"] as? Int ?? 1,
                    iconName: item["iconName"] as? String ?? "star.fill"
                )
                u.isUnlocked = item["isUnlocked"] as? Bool ?? false
                if let dateStr = item["unlockedAt"] as? String {
                    u.unlockedAt = iso.date(from: dateStr)
                }
                context.insert(u)
            }
        }

        // Login streak (singleton — replace existing)
        if let item = root["loginStreak"] as? [String: Any] {
            let existingDesc = FetchDescriptor<LoginStreak>()
            let existing = (try? context.fetch(existingDesc)) ?? []
            for old in existing { context.delete(old) }

            let ls = LoginStreak()
            if let dateStr = item["lastBonusDate"] as? String {
                ls.lastBonusDate = iso.date(from: dateStr)
            }
            ls.currentStreak = item["currentStreak"] as? Int ?? 0
            ls.longestStreak = item["longestStreak"] as? Int ?? 0
            ls.totalLoginDays = item["totalLoginDays"] as? Int ?? 0
            context.insert(ls)
        }

        // Rank streak state (singleton — replace existing)
        if let item = root["rankStreakState"] as? [String: Any] {
            let existingDesc = FetchDescriptor<RankStreakState>()
            let existing = (try? context.fetch(existingDesc)) ?? []
            for old in existing { context.delete(old) }

            let rs = RankStreakState()
            rs.currentSRankStreak = item["currentSRankStreak"] as? Int ?? 0
            rs.currentARankStreak = item["currentARankStreak"] as? Int ?? 0
            rs.lastWeekRank = item["lastWeekRank"] as? String ?? ""
            rs.xpMultiplierActive = item["xpMultiplierActive"] as? Bool ?? false
            rs.xpMultiplierValue = item["xpMultiplierValue"] as? Double ?? 1.0
            if let dateStr = item["xpMultiplierExpiryDate"] as? String {
                rs.xpMultiplierExpiryDate = iso.date(from: dateStr)
            }
            rs.doubleXPWeeksRemaining = item["doubleXPWeeksRemaining"] as? Int ?? 0
            rs.hasEarnedFirstSRank = item["hasEarnedFirstSRank"] as? Bool ?? false
            context.insert(rs)
        }

        // Balanced day logs
        if let items = root["balancedDayLogs"] as? [[String: Any]] {
            for item in items {
                guard let dateStr = item["date"] as? String,
                      let date = iso.date(from: dateStr) else { continue }
                let b = BalancedDayLog(
                    date: date,
                    fitnessXP: item["fitnessXP"] as? Int ?? 50,
                    workXP: item["workXP"] as? Int ?? 50,
                    learningXP: item["learningXP"] as? Int ?? 50,
                    totalBonus: item["totalBonus"] as? Int ?? 150,
                    streakAtAward: item["streakAtAward"] as? Int ?? 1
                )
                context.insert(b)
            }
        }

        // Founder week logs
        if let items = root["founderWeekLogs"] as? [[String: Any]] {
            for item in items {
                guard let startStr = item["weekStartDate"] as? String,
                      let start = iso.date(from: startStr) else { continue }
                let f = FounderWeekLog(
                    weekStartDate: start,
                    bvaDealClosed: item["bvaDealClosed"] as? Bool ?? true,
                    paralaiMilestone: item["paralaiMilestone"] as? Bool ?? true,
                    xpAwarded: item["xpAwarded"] as? Int ?? 1000
                )
                if let achievedStr = item["achievedAt"] as? String,
                   let achieved = iso.date(from: achievedStr) {
                    f.achievedAt = achieved
                }
                context.insert(f)
            }
        }

        // Baseline stats
        if let items = root["baselineStats"] as? [[String: Any]] {
            for item in items {
                guard let weekStr = item["weekOf"] as? String,
                      let weekOf = iso.date(from: weekStr) else { continue }
                let b = BaselineStats(
                    weekOf: weekOf,
                    avgWorkHours: item["avgWorkHours"] as? Double ?? 0,
                    avgGymSessions: item["avgGymSessions"] as? Double ?? 0,
                    avgStudyHours: item["avgStudyHours"] as? Double ?? 0,
                    avgHabitsRate: item["avgHabitsRate"] as? Double ?? 0,
                    avgBVAActions: item["avgBVAActions"] as? Double ?? 0,
                    avgDeepWorkSessions: item["avgDeepWorkSessions"] as? Double ?? 0
                )
                context.insert(b)
            }
        }

        // Season carryover
        if let items = root["seasonCarryovers"] as? [[String: Any]] {
            for item in items {
                let s = SeasonCarryover(
                    fromSeason: item["fromSeason"] as? Int ?? 0,
                    toSeason: item["toSeason"] as? Int ?? 0,
                    rewardType: item["rewardType"] as? String ?? "",
                    xpMultiplier: item["xpMultiplier"] as? Double ?? 1.0,
                    xpBonus: item["xpBonus"] as? Int ?? 0
                )
                s.isActive = item["isActive"] as? Bool ?? true
                if let dateStr = item["expiryDate"] as? String {
                    s.expiryDate = iso.date(from: dateStr)
                }
                context.insert(s)
            }
        }

        try context.save()
    }

    enum ImportError: LocalizedError {
        case invalidFormat
        var errorDescription: String? { "Invalid backup file format." }
    }
}
