# LEVEL UP

A native macOS app for gamifying real life. Solo-Leveling inspired. Built for one user — Yashodev — who tracks XP across **Fitness**, **Work**, and **Learning** and watches his character sheet fill in.

Phases 1 through 6 are complete and shipping.

---

## Stack

- **Swift 5 + SwiftUI**
- **SwiftData** (local persistence, no backend)
- **macOS 14+** target
- **MVVM**, no third-party dependencies
- **SF Pro** + **SF Symbols**
- **Anthropic Claude API** for AI-powered food macro analysis and project milestone generation

## Quick Start

1. Install **Xcode 15+** from the Mac App Store.
2. Open `LevelUp.xcodeproj` in Xcode.
3. In the target settings, set **Signing & Capabilities → Team** to your Apple ID / team.
4. Press **⌘R** to build and run.
5. On first launch, type your name and hit **Start Your Journey**.

**Shell alias (optional):** After building once, type `levelup` in any terminal to launch the app.

**AI features:** Place your Anthropic API key at `~/Library/Application Support/LevelUp/anthropic_key.txt` or set `ANTHROPIC_API_KEY` in the Xcode scheme environment variables. Used for food macro analysis and AI-generated project milestones.

> **Bundle ID:** `com.yashodev.LevelUp`

## Architecture

```
LevelUp/
├── LevelUpApp.swift              # @main — ModelContainer, menu bar, notifications, launch-at-login
├── Theme/
│   ├── Theme.swift               # Colours, radii, gradients, Color hex init (dark, electric, RPG)
│   ├── Card.swift                # Reusable Card / SectionHeader / ProgressBar
│   └── AnimationConstants.swift  # Timing + spring presets
├── Models/
│   ├── User.swift                # Single user record. Levels derived from XP.
│   ├── FitnessModels.swift       # GymSession, Exercise, CardioSession, FoodEntry, WeightEntry, HabitLog, GymSplitState
│   ├── ProjectModels.swift       # Project, ProjectMilestone, WorkEntry — unified work tracking
│   ├── LearningModels.swift      # Course, Book, Certification
│   ├── Phase45Models.swift       # RankStreakState, BalancedDayLog, FounderWeekLog, WeeklyChallenge, BaselineStats, SeasonCarryover, Achievement
│   ├── WeeklyReport.swift        # Graded weekly report (S/A/B/C/D)
│   ├── Unlock.swift              # Rewards / badges / titles catalog
│   ├── FitnessLog.swift, WorkLog.swift, LearningLog.swift  # Per-session logs
│   ├── Phase3Models.swift        # LoginStreak, PersonalRecord
│   ├── WorkModels.swift          # (Legacy schema shells — Deal, ParaLAIMilestone, ParaLAIEntry)
│   └── OtherWorkLog.swift        # (Legacy schema shell)
├── Engines/
│   ├── XPEngine.swift            # Level curve + all XP rules
│   ├── XPEngine+Phase2.swift     # Phase 2 XP extensions
│   ├── User+Award.swift          # Centralized XP mutation — multiplier, level-up detection, events
│   ├── UnlockEngine.swift        # Seeds catalog + evaluates unlocks
│   ├── UnlockCenter.swift        # FIFO unlock celebration bus
│   ├── GameEventCenter.swift     # @Observable event bus — XP gains, level-ups, banners
│   ├── GymSplitEngine.swift      # Upper/Lower/Push/Pull/Legs cycle + gym bonuses
│   ├── LoginStreakEngine.swift    # Daily login bonus (10 + streak×5, capped 150)
│   ├── PersonalRecordsEngine.swift # Detects new personal bests (lifts, work sessions, study)
│   ├── BonusEngine.swift         # XP multipliers, balanced days, builder weeks, achievements
│   ├── ChallengeManager.swift    # Weekly/monthly challenges with dynamic difficulty
│   ├── BaselineCalculator.swift  # Trailing 4-week averages for challenge scaling
│   ├── SeasonManager.swift       # Season carryover rewards
│   ├── WeeklyReportEngine.swift  # Monday auto-report generation + grading
│   ├── InsightEngine.swift       # Data-driven correlation insights
│   ├── StatsRepository.swift     # Centralized FetchDescriptor queries for Stats
│   ├── MenuBarManager.swift      # NSStatusItem — left-click popover, right-click menu
│   ├── NotificationManager.swift # UNUserNotificationCenter — reminders, alerts
│   ├── LoginItemManager.swift    # SMAppService launch-at-login
│   ├── AIClient.swift            # Anthropic Claude API — meal analysis + milestone generation
│   └── APIConfig.swift           # API key resolution (env var / file)
├── ViewModels/
│   ├── DashboardViewModel.swift  # Unlocks, today summary
│   ├── FitnessViewModel.swift    # Gym, food, weight, habit aggregation
│   ├── WorkViewModel.swift       # Project entries, milestones, weekly hours
│   └── LearningViewModel.swift   # Courses, books, certifications
└── Views/
    ├── RootView.swift            # Welcome vs. main router
    ├── MainNavigationView.swift  # Sidebar: Dashboard / Fitness / Work / Learning / Stats / Settings
    ├── Welcome/WelcomeView.swift
    ├── Dashboard/
    │   ├── DashboardView.swift   # Hero badge, track cards with metrics, challenges, records
    │   ├── XPTrackCard.swift     # Level + XP bar + 3 densified metrics per track
    │   └── UnlockRow.swift
    ├── Fitness/
    │   ├── FitnessView.swift     # 4 tabs: Workout, Food, Weight, Habits
    │   ├── WorkoutTabView.swift  # Gym split logging with exercises
    │   ├── FoodTabView.swift     # AI-powered meal analysis + macro tracking
    │   ├── WeightTabView.swift   # Weight trend tracking
    │   └── HabitsTabView.swift   # 6 daily habits
    ├── Work/
    │   ├── WorkView.swift        # Dynamic project tabs + add project
    │   ├── ProjectTabView.swift  # Stats, milestones, log form, recent entries per project
    │   └── AddProjectSheet.swift # Create project — name, description, icon, color, AI milestones
    ├── Learning/
    │   ├── LearningView.swift    # 3 tabs + weekly study goal progress
    │   ├── CoursesTabView.swift  # Course progress + study time
    │   ├── BooksTabView.swift    # Pages read + completion
    │   └── CertificationsTabView.swift # Cert study hours + earning
    ├── Stats/StatsView.swift     # Analytics dashboard
    ├── MenuBar/QuickLogPopover.swift # 320px quick-log popover (fitness/work/learning)
    ├── Overlays/
    │   ├── XPGainOverlay.swift   # Floating +XP numbers
    │   ├── LevelUpOverlay.swift  # Full-screen level-up celebration
    │   ├── BannerOverlays.swift  # Generic banners (gold/green/red/purple)
    │   ├── PerfectWeekOverlay.swift
    │   ├── WeeklyReportOverlay.swift
    │   └── WeeklyReportRoot.swift
    ├── Shared/
    │   ├── ConfettiView.swift
    │   ├── InternalTabBar.swift
    │   ├── StreakFlameView.swift
    │   └── UnlockCelebrationView.swift
    └── Settings/SettingsView.swift # Name, notifications, menu bar, launch, danger zone
```

## Phases

### Phase 1 — Engine & Dashboard
XP engine with 50-level curve, SwiftData models, unlock catalog, dashboard with total level badge, track cards, unlock progression, onboarding.

### Phase 2 — Full Logging
Fitness: gym split system (Upper/Lower/Push/Pull/Legs), exercise tracking, AI food macro analysis via Claude API, weight trending, 6 daily habits. Work: BVA deal pipeline, ParaLAI feature/bug/milestone logging, category-based project work. Learning: course progress, book tracking, certification study hours.

### Phase 3 — Gamification
Daily login streak with scaling bonus, personal records detection (heaviest lift, longest work session, longest study session), XP gain animations, level-up celebrations, unlock toasts, confetti.

### Phase 4 — Stats & Analytics
Weekly report engine with S/A/B/C/D grading, stats dashboard, insight engine with data-driven correlations, per-category XP rates for project work.

### Phase 4.5 — Bonuses & Challenges
XP multipliers (2× for S-rank streaks), balanced day bonus (+50 XP/track when all 3 logged), builder week (+1000 XP for completing milestones across 2+ projects in one week), weekly/monthly challenges with dynamic difficulty, achievement catalog, season carryover system.

### Phase 5 — Mac Polish
Persistent menu bar icon with quick-log popover (left-click) and context menu (right-click), native macOS notifications (morning/evening/gym/study reminders, streak/challenge/level-up alerts), launch-at-login via SMAppService, app stays alive in menu bar when window closes, Settings expanded with notification scheduling, menu bar toggles, launch preferences.

### Phase 6 — Unified Work Tracker
Replaced hardcoded BVA/ParaLAI work tabs with a unified project-based system. Create any project (BVA, ParaLAI, or anything new) — each becomes its own tab. AI-generated milestones per project via Claude API. Action-type-based XP rates (Deep Work 1.5× multiplier). Weekly "deep work" challenge replaces old BVA challenge. Builder Week replaces Founder Week. Menu bar quick-log updated with project picker.

## XP Rules

**Fitness**
| Action | XP |
|---|---|
| Workout (easy/medium/hard) | 50 / 75 / 100 |
| Cardio (easy/medium/hard) | 40 / 60 / 80 |
| Nutrition log | 20 |
| Weight log | 10 |
| All 6 daily habits | 30 |
| Streak bonus | streak × 5 |
| Perfect gym week (5/5) | 200 |
| 30-day gym streak | 500 |

**Work**
| Action | XP |
|---|---|
| Deep Work | 80/hr × 1.5 multiplier |
| Research | 70/hr |
| Meeting | 60/hr |
| Call | 50/hr |
| Content | 50/hr |
| Admin | 40/hr |
| Other | 60/hr |
| 3+ hour session bonus | +50 |
| Project milestone completed | 300 |

**Learning**
| Action | XP |
|---|---|
| 30 min study | 40 |
| 1 hour study | 100 |
| Course completed | 400 |
| Book finished | 200 |
| Certification earned | 600 |

**Bonuses**
| Bonus | XP |
|---|---|
| Balanced day (all 3 tracks) | +50 per track |
| 7-day balanced streak | +500 |
| Builder week (milestones across 2+ projects) | +1000 |
| S-rank streak (2+ weeks) | 2× multiplier |
| A-rank streak (2+ weeks) | +200 |
| Game Plan complete | +100 |

## Level Curve

| Levels | Step |
|---|---|
| 1 – 10 | Hand-authored: 0, 500, 1.2k, 2.5k, 4.5k, 7.5k, 12k, 18k, 26k, 36k |
| 11 – 20 | Previous **+ 15,000** per level |
| 21 – 35 | Previous **+ 25,000** per level |
| 36 – 50 | Previous **+ 40,000** per level |

Total Level is derived from the sum of all three tracks using the same curve.
