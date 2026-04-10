//
//  UnlockCenter.swift
//  LEVEL UP — Phase 2
//
//  Cross-view celebration event bus. Log screens call
//  `UnlockCenter.shared.present(newly)` with whatever UnlockEngine
//  returned from evaluateUnlocks, and the root overlay
//  (UnlockCelebrationView) listens on `pending` and queues them up so
//  each unlock gets its own full-screen moment.
//

import Foundation
import SwiftUI

@Observable
final class UnlockCenter {
    static let shared = UnlockCenter()

    /// FIFO queue. The root overlay pops the head, displays it, and
    /// removes it on dismiss.
    var pending: [Unlock] = []

    /// The unlock currently being celebrated (nil when nothing to show).
    var current: Unlock?

    private init() {}

    /// Enqueue a batch. Safe to call with an empty array.
    func present(_ newly: [Unlock]) {
        guard !newly.isEmpty else { return }
        pending.append(contentsOf: newly)
        advanceIfIdle()
    }

    /// Called by the overlay when its current celebration is dismissed.
    func dismissCurrent() {
        current = nil
        advanceIfIdle()
    }

    private func advanceIfIdle() {
        guard current == nil, !pending.isEmpty else { return }
        current = pending.removeFirst()
    }
}
