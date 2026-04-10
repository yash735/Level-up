//
//  FitnessModels.swift
//  LEVEL UP — Phase 2
//
//  Every SwiftData model used by the Fitness track lives here. Grouped in
//  one file because they all belong to the same feature area.
//

import Foundation
import SwiftData

// MARK: - GymSession

@Model
final class GymSession {
    var id: UUID
    var date: Date
    /// One of the five split days, or "Rest" for rest days.
    var splitDay: String
    /// Stored as raw string for SwiftData compatibility.
    var intensityRaw: String
    var xpEarned: Int
    var isRestDay: Bool
    var notes: String
    /// Exercises logged inside this session.
    @Relationship(deleteRule: .cascade) var exercises: [Exercise]

    init(date: Date = .now,
         splitDay: String,
         intensity: XPEngine.FitnessIntensity = .medium,
         xpEarned: Int = 0,
         isRestDay: Bool = false,
         notes: String = "") {
        self.id = UUID()
        self.date = date
        self.splitDay = splitDay
        self.intensityRaw = intensity.rawValue
        self.xpEarned = xpEarned
        self.isRestDay = isRestDay
        self.notes = notes
        self.exercises = []
    }

    var intensity: XPEngine.FitnessIntensity {
        XPEngine.FitnessIntensity(rawValue: intensityRaw) ?? .medium
    }
}

// MARK: - Exercise

@Model
final class Exercise {
    var id: UUID
    var name: String
    var sets: Int
    var reps: Int
    var weightKg: Double
    var notes: String

    init(name: String, sets: Int, reps: Int, weightKg: Double, notes: String = "") {
        self.id = UUID()
        self.name = name
        self.sets = sets
        self.reps = reps
        self.weightKg = weightKg
        self.notes = notes
    }
}

// MARK: - CardioSession

/// Non-gym cardio / movement sessions: runs, swims, yoga, etc.
@Model
final class CardioSession {
    var id: UUID
    var date: Date
    /// Run / Swim / Cycle / HIIT / Yoga / Walk / Other
    var type: String
    var durationMinutes: Int
    var intensityRaw: String
    var distanceKm: Double
    var notes: String
    var xpEarned: Int

    init(date: Date = .now,
         type: String,
         durationMinutes: Int,
         intensity: XPEngine.FitnessIntensity,
         distanceKm: Double = 0,
         notes: String = "",
         xpEarned: Int = 0) {
        self.id = UUID()
        self.date = date
        self.type = type
        self.durationMinutes = durationMinutes
        self.intensityRaw = intensity.rawValue
        self.distanceKm = distanceKm
        self.notes = notes
        self.xpEarned = xpEarned
    }

    var intensity: XPEngine.FitnessIntensity {
        XPEngine.FitnessIntensity(rawValue: intensityRaw) ?? .medium
    }
}

// MARK: - FoodEntry

@Model
final class FoodEntry {
    var id: UUID
    var date: Date
    /// Breakfast / Lunch / Dinner / Snack
    var mealType: String
    var foodName: String
    var calories: Int
    var protein: Double
    var carbs: Double
    var fats: Double
    var xpEarned: Int

    init(date: Date = .now,
         mealType: String,
         foodName: String,
         calories: Int,
         protein: Double,
         carbs: Double,
         fats: Double,
         xpEarned: Int = 20) {
        self.id = UUID()
        self.date = date
        self.mealType = mealType
        self.foodName = foodName
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
        self.xpEarned = xpEarned
    }
}

// MARK: - WeightEntry

@Model
final class WeightEntry {
    var id: UUID
    var date: Date
    var weightKg: Double
    var notes: String
    var xpEarned: Int

    init(date: Date = .now, weightKg: Double, notes: String = "", xpEarned: Int = 10) {
        self.id = UUID()
        self.date = date
        self.weightKg = weightKg
        self.notes = notes
        self.xpEarned = xpEarned
    }
}

// MARK: - HabitLog

/// One record per calendar day. Each of the six daily habits is a Bool.
@Model
final class HabitLog {
    var id: UUID
    /// Normalised to the start of the day.
    var date: Date
    var sleep: Bool
    var water: Bool
    var steps: Bool
    var noJunk: Bool
    var morningWorkout: Bool
    var eveningStretch: Bool
    /// True once the "all complete" 30 XP bonus has been granted for this day.
    var bonusAwarded: Bool
    var xpEarned: Int

    init(date: Date) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.sleep = false
        self.water = false
        self.steps = false
        self.noJunk = false
        self.morningWorkout = false
        self.eveningStretch = false
        self.bonusAwarded = false
        self.xpEarned = 0
    }

    var allCompleted: Bool {
        sleep && water && steps && noJunk && morningWorkout && eveningStretch
    }
}

// MARK: - GymSplitState

/// Singleton record (only one row ever) that tracks where the user is in
/// the Upper→Lower→Push→Pull→Legs cycle plus streak bookkeeping.
@Model
final class GymSplitState {
    var id: UUID
    /// 0 = Upper, 1 = Lower, 2 = Push, 3 = Pull, 4 = Legs.
    var currentDayIndex: Int
    var lastGymDate: Date?
    var currentStreak: Int
    var longestStreak: Int
    /// ISO "yyyy-Www" key of the last week we awarded the Perfect Week bonus.
    var lastPerfectWeekKey: String
    /// ISO "yyyy-Www" key of the last week we awarded the Monday bonus.
    var lastMondayBonusKey: String

    init() {
        self.id = UUID()
        self.currentDayIndex = 0
        self.lastGymDate = nil
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastPerfectWeekKey = ""
        self.lastMondayBonusKey = ""
    }
}
