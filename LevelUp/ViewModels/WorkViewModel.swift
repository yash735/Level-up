//
//  WorkViewModel.swift
//  LEVEL UP — Phase 2
//
//  Struct view-model rebuilt per render. Aggregates deal pipeline,
//  ParaLAI milestones, and recent ParaLAI entries.
//

import Foundation

struct WorkViewModel {

    let deals: [Deal]
    let milestones: [ParaLAIMilestone]
    let entries: [ParaLAIEntry]

    // MARK: - BVA

    /// All deals sorted by updatedAt descending.
    var dealsByRecent: [Deal] {
        deals.sorted { $0.updatedAt > $1.updatedAt }
    }

    /// Open (non-closed) deals, shown at the top of the pipeline.
    var openDeals: [Deal] {
        dealsByRecent.filter { !$0.isClosed }
    }

    var closedDeals: [Deal] {
        dealsByRecent.filter { $0.isClosed }
    }

    /// Total value of active pipeline in $ millions.
    var pipelineValueMillion: Double {
        openDeals.reduce(0) { $0 + $1.dealSizeMillion }
    }

    /// Total value of closed-won deals.
    var wonValueMillion: Double {
        deals.filter { $0.isClosedWon }.reduce(0) { $0 + $1.dealSizeMillion }
    }

    /// Deals whose nextActionDue has passed.
    var overdueDeals: [Deal] { openDeals.filter { $0.isOverdue } }

    /// Number of deals in each canonical stage.
    func count(inStage stage: String) -> Int {
        deals.filter { $0.stage == stage && !$0.isClosed }.count
    }

    // MARK: - ParaLAI

    /// Milestones ordered by display index.
    var orderedMilestones: [ParaLAIMilestone] {
        milestones.sorted { $0.orderIndex < $1.orderIndex }
    }

    var completedMilestoneCount: Int {
        milestones.filter { $0.isCompleted }.count
    }

    var totalMilestoneCount: Int { max(milestones.count, 1) }

    var milestoneProgress: Double {
        Double(completedMilestoneCount) / Double(totalMilestoneCount)
    }

    /// 6 most recent ParaLAI entries.
    var recentEntries: [ParaLAIEntry] {
        entries.sorted { $0.date > $1.date }.prefix(6).map { $0 }
    }

    /// Total hours logged against ParaLAI.
    var totalParaLAIHours: Double {
        entries.reduce(0) { $0 + $1.hoursSpent }
    }
}
