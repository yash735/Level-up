# LEVEL UP

A native macOS app for gamifying real life. Solo-Leveling inspired. Built for one user — Yashodev — who wants to track XP across **Fitness**, **Work**, and **Learning** and watch his character sheet fill in.

This repo is **Phase 1**: the engine, data layer, dashboard, and onboarding. No logging screens yet.

---

## Stack

- **Swift 5 + SwiftUI**
- **SwiftData** (local persistence, no backend)
- **macOS 14+** target
- **MVVM**, no third-party dependencies
- **SF Pro** + **SF Symbols**

## Quick Start

1. Install **Xcode 15+** from the Mac App Store (Command Line Tools alone are not enough — SwiftData and SwiftUI previews require the full IDE).
2. Open `LevelUp.xcodeproj` in Xcode.
3. In the target settings, set **Signing & Capabilities → Team** to your Apple ID / team.
4. Press **⌘R** to build and run.
5. On first launch you'll see the welcome screen. Type your name (prefilled as Yashodev) and hit **Start Your Journey**. The User record and the full unlock catalog get seeded into SwiftData automatically.

> **Bundle ID:** `com.yashodev.LevelUp` — change in project settings if it collides with something else on your signing profile.

## Architecture

```
LevelUp/
├── LevelUpApp.swift            # @main — wires up ModelContainer
├── Theme/
│   ├── Theme.swift             # Colours, radii, gradients
│   └── Card.swift              # Reusable Card / SectionHeader / ProgressBar
├── Models/                     # SwiftData @Model types
│   ├── User.swift              # Single user record. Levels are derived.
│   ├── FitnessLog.swift        # Phase 2 target
│   ├── WorkLog.swift           # Phase 2 target
│   ├── LearningLog.swift       # Phase 2 target
│   └── Unlock.swift            # Rewards / badges / titles catalog
├── Engines/
│   ├── XPEngine.swift          # Level curve + every XP rule, central.
│   └── UnlockEngine.swift      # Seeds catalog + evaluates unlocks
├── ViewModels/
│   └── DashboardViewModel.swift
└── Views/
    ├── RootView.swift          # Welcome vs. main router
    ├── MainNavigationView.swift# Sidebar shell
    ├── Welcome/WelcomeView.swift
    ├── Dashboard/
    │   ├── DashboardView.swift
    │   ├── XPTrackCard.swift
    │   └── UnlockRow.swift
    ├── Placeholder/PlaceholderView.swift
    └── Settings/SettingsView.swift
```

**Single source of truth for XP:** all XP and level maths route through `XPEngine`. `User`'s `fitnessLevel` / `workLevel` / `learningLevel` / `totalLevel` are all computed from raw XP — you can never get a stale level number in the UI.

**Unlocks:** `UnlockEngine.seedCatalog` is the one place to add or tweak rewards. On first launch the catalog is seeded into SwiftData; `evaluateUnlocks(user:context:)` walks every still-locked record and flips the ones the user now qualifies for.

## Level Curve

| Levels | Step |
|---|---|
| 1 – 10 | Hand-authored: 0, 500, 1.2k, 2.5k, 4.5k, 7.5k, 12k, 18k, 26k, 36k |
| 11 – 20 | Previous **+ 15,000** per level |
| 21 – 35 | Previous **+ 25,000** per level |
| 36 – 50 | Previous **+ 40,000** per level |

Total Level is derived from the sum of all three tracks using the same curve.

## XP Rules (Phase 1 engine, Phase 2 UI)

**Fitness**
- Workout: 50 XP × intensity (easy 1.0 / medium 1.5 / hard 2.0)
- Nutrition log: 20 XP
- Weight log: 10 XP
- All daily habits: 30 XP
- Daily streak bonus: `streak × 5` XP

**Work**
- ParaLAI feature built: 100 XP
- ParaLAI bug fixed: 40 XP
- ParaLAI milestone shipped: **+300 XP**
- BVA deal added to pipeline: 50 XP
- BVA deal stage update: 75 XP
- BVA deal closed: **+500 XP**
- BVA meeting completed: 60 XP

**Learning**
- 30 min study: 40 XP
- 1 hour study: 100 XP
- Course completed: **+400 XP**
- Book finished: **+200 XP**
- Certification earned: **+600 XP**

## Settings

The Settings screen lets you:
- Rename yourself (default: Yashodev)
- Reset all data (wipes User + logs + unlocks, returns to welcome screen)
- See the app version

## Phase 2 Roadmap

Everything Phase 1 set the table for:

1. **Logging screens** behind the three sidebar items:
   - Fitness: workouts / nutrition / weight / habits with forms that award XP via `XPEngine`.
   - Work: ParaLAI feature/bug/milestone + BVA deal add/stage/close/meeting.
   - Learning: study session timer, book finished, course completed, certification earned.
2. **Streak tracking** — a daily heartbeat that advances `User.currentStreak` when anything is logged, resets on a missed day, and awards the daily streak bonus.
3. **Today summary wired to real logs** — replace the hard-coded `xpEarnedToday: 0` with a `sum(xpEarned)` over today's logs.
4. **History views** — per-track timeline of past logs.
5. **Unlock notifications** — pop a celebratory toast when `UnlockEngine.evaluateUnlocks` flips a new one.
6. **Export / backup** — JSON dump of the SwiftData store for safekeeping.
7. **Calendar heatmap** — GitHub-style consistency grid across all three tracks.

## Phase 3+ (speculative)

- iCloud sync (CloudKit) — if he ever wants this on iPhone/iPad.
- Apple Health integration for automatic workout logging.
- Widgets for current level / streak.
- Season system — reset after Level 50, start Season 2.
