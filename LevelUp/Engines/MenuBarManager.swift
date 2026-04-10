//
//  MenuBarManager.swift
//  LEVEL UP — Phase 5
//
//  Persistent menu bar icon with left-click popover (quick log)
//  and right-click context menu (info + actions).
//  Uses AppKit's NSStatusItem for full click-type control.
//

import AppKit
import SwiftUI
import SwiftData

@MainActor
final class MenuBarManager: NSObject, ObservableObject {

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private let container: ModelContainer

    /// Which quick-log tab to open. Set by context menu before showing popover.
    @Published var defaultTab: QuickLogTab = {
        let raw = UserDefaults.standard.string(forKey: "menuBarDefaultTab") ?? "fitness"
        return QuickLogTab(rawValue: raw) ?? .fitness
    }()

    /// Fires after a successful log so the popover auto-closes.
    @Published var shouldAutoClose = false

    // Cached values for the context menu (refreshed on menu open).
    private var cachedTotalLevel = 1
    private var cachedTodayXP = 0
    private var cachedStreak = 0
    private var cachedMultiplier = 1.0
    private var cachedChallengeTitle = ""
    private var cachedChallengeProgress = ""

    init(container: ModelContainer) {
        self.container = container
        super.init()
        setupStatusItem()
        setupPopover()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }

        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        let image = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: "LEVEL UP")?
            .withSymbolConfiguration(config)
        button.image = image
        button.imagePosition = .imageLeading
        button.target = self
        button.action = #selector(statusItemClicked(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        updateBadge()
    }

    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 320, height: 480)
        popover?.behavior = .transient
        popover?.animates = true

        let content = QuickLogPopover(manager: self)
            .modelContainer(container)
            .environment(GameEventCenter.shared)
        popover?.contentViewController = NSHostingController(rootView: content)
    }

    // MARK: - Click handling

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    private func togglePopover() {
        guard let popover, let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            shouldAutoClose = false
            // Recreate content to get fresh SwiftData state
            let content = QuickLogPopover(manager: self)
                .modelContainer(container)
                .environment(GameEventCenter.shared)
            popover.contentViewController = NSHostingController(rootView: content)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    func closePopover() {
        popover?.performClose(nil)
    }

    /// Called after a successful quick-log. Triggers auto-close after delay.
    func logCompleted() {
        shouldAutoClose = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.closePopover()
            self?.shouldAutoClose = false
            self?.updateBadge()
        }
    }

    // MARK: - Badge

    func updateBadge() {
        guard let button = statusItem?.button else { return }
        // Default is ON — only hide if explicitly set to false
        if UserDefaults.standard.object(forKey: "menuBarShowBadge") != nil
            && !UserDefaults.standard.bool(forKey: "menuBarShowBadge") {
            button.title = ""
            return
        }
        let ctx = ModelContext(container)
        let desc = FetchDescriptor<User>()
        if let user = (try? ctx.fetch(desc))?.first {
            cachedTotalLevel = user.totalLevel
            button.title = " \(user.totalLevel)"
        }
    }

    /// Brief pulse animation on the menu bar icon when XP is earned.
    func pulseIcon() {
        guard UserDefaults.standard.object(forKey: "menuBarShowPulse") == nil
           || UserDefaults.standard.bool(forKey: "menuBarShowPulse") else { return }
        guard let button = statusItem?.button else { return }
        let anim = CABasicAnimation(keyPath: "transform.scale")
        anim.fromValue = 1.0
        anim.toValue = 1.3
        anim.duration = 0.15
        anim.autoreverses = true
        anim.repeatCount = 2
        button.layer?.add(anim, forKey: "pulse")
    }

    // MARK: - Context Menu

    private func showContextMenu() {
        refreshCachedValues()

        let menu = NSMenu()

        // Open main window
        let openItem = NSMenuItem(title: "Open LEVEL UP", action: #selector(openMainWindow), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)

        menu.addItem(.separator())

        // Info items
        let xpItem = NSMenuItem(title: "Today's XP: \(cachedTodayXP.formatted())", action: nil, keyEquivalent: "")
        xpItem.isEnabled = false
        menu.addItem(xpItem)

        let streakItem = NSMenuItem(title: "Current Streak: \(cachedStreak) days", action: nil, keyEquivalent: "")
        streakItem.isEnabled = false
        menu.addItem(streakItem)

        if cachedMultiplier > 1.0 {
            let multItem = NSMenuItem(title: "Active Multiplier: \(Int(cachedMultiplier))x", action: nil, keyEquivalent: "")
            multItem.isEnabled = false
            menu.addItem(multItem)
        }

        menu.addItem(.separator())

        // Quick log shortcuts
        let fitItem = NSMenuItem(title: "Quick Log Workout", action: #selector(quickLogFitness), keyEquivalent: "")
        fitItem.target = self
        menu.addItem(fitItem)

        let workItem = NSMenuItem(title: "Quick Log Work", action: #selector(quickLogWork), keyEquivalent: "")
        workItem.target = self
        menu.addItem(workItem)

        let studyItem = NSMenuItem(title: "Quick Log Study", action: #selector(quickLogLearning), keyEquivalent: "")
        studyItem.target = self
        menu.addItem(studyItem)

        menu.addItem(.separator())

        // Challenge info
        if !cachedChallengeTitle.isEmpty {
            let challItem = NSMenuItem(title: "Challenge: \(cachedChallengeTitle)", action: nil, keyEquivalent: "")
            challItem.isEnabled = false
            menu.addItem(challItem)

            let progItem = NSMenuItem(title: "Progress: \(cachedChallengeProgress)", action: nil, keyEquivalent: "")
            progItem.isEnabled = false
            menu.addItem(progItem)

            menu.addItem(.separator())
        }

        // Quit
        let quitItem = NSMenuItem(title: "Quit LEVEL UP", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        // Clear menu so left-click works again next time
        DispatchQueue.main.async { [weak self] in
            self?.statusItem?.menu = nil
        }
    }

    private func refreshCachedValues() {
        let ctx = ModelContext(container)

        // User
        let userDesc = FetchDescriptor<User>()
        if let user = (try? ctx.fetch(userDesc))?.first {
            cachedTotalLevel = user.totalLevel
            cachedStreak = user.currentStreak
            cachedMultiplier = user.resolvedMultiplier

            // Today's XP — sum logs from today
            let cal = Calendar.current
            let todayStart = cal.startOfDay(for: .now)
            let gymDesc = FetchDescriptor<GymSession>()
            let gyms = (try? ctx.fetch(gymDesc)) ?? []
            let gymXP = gyms.filter { cal.isDate($0.date, inSameDayAs: todayStart) && !$0.isRestDay }
                .reduce(0) { $0 + $1.xpEarned }
            let foodDesc = FetchDescriptor<FoodEntry>()
            let foods = (try? ctx.fetch(foodDesc)) ?? []
            let foodXP = foods.filter { cal.isDate($0.date, inSameDayAs: todayStart) }
                .reduce(0) { $0 + $1.xpEarned }
            let paralaiDesc = FetchDescriptor<ParaLAIEntry>()
            let paralai = (try? ctx.fetch(paralaiDesc)) ?? []
            let paralaiXP = paralai.filter { cal.isDate($0.date, inSameDayAs: todayStart) }
                .reduce(0) { $0 + $1.xpEarned }
            let otherDesc = FetchDescriptor<OtherWorkLog>()
            let other = (try? ctx.fetch(otherDesc)) ?? []
            let otherXP = other.filter { cal.isDate($0.date, inSameDayAs: todayStart) }
                .reduce(0) { $0 + $1.xpEarned }
            cachedTodayXP = gymXP + foodXP + paralaiXP + otherXP
        }

        // Active challenge
        let challDesc = FetchDescriptor<WeeklyChallenge>(
            sortBy: [SortDescriptor(\.weekStartDate, order: .reverse)]
        )
        let challenges = (try? ctx.fetch(challDesc)) ?? []
        if let active = challenges.first(where: { !$0.isCompleted && !$0.isFailed }) {
            cachedChallengeTitle = active.title
            cachedChallengeProgress = String(format: "%.0f/%.0f", active.currentValue, active.targetValue)
        } else {
            cachedChallengeTitle = ""
            cachedChallengeProgress = ""
        }
    }

    // MARK: - Actions

    @objc private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.title.contains("LEVEL UP") || $0.contentView is NSHostingView<AnyView> }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            // Open a new window
            for window in NSApp.windows {
                if window.level == .normal {
                    window.makeKeyAndOrderFront(nil)
                    break
                }
            }
        }
    }

    @objc private func quickLogFitness() {
        defaultTab = .fitness
        togglePopover()
    }

    @objc private func quickLogWork() {
        defaultTab = .work
        togglePopover()
    }

    @objc private func quickLogLearning() {
        defaultTab = .learning
        togglePopover()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
