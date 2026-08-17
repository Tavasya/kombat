//
//  ScanBreakdown.swift
//  kombat
//

import Foundation

/// The evidence behind a scan's form score: per-rule averages and the
/// specific timestamped moments where form broke down. Stored on the scan
/// row in Supabase, stamped with the engine version that produced it.
struct ScanBreakdown: Codable, Equatable {
    let engineVersion: Int
    let repCount: Int
    /// Set when there was nothing to score (no person / no punches detected).
    let note: String?
    let ruleScores: [RuleScore]
    let findings: [Finding]
    /// What was thrown, per auto-classified technique. Optional because
    /// engine-v1 rows predate classification.
    let techniques: [TechniqueCount]?

    struct TechniqueCount: Codable, Equatable, Identifiable {
        let technique: String
        let count: Int
        let averageScore: Int
        var id: String { technique }
    }

    struct RuleScore: Codable, Equatable, Identifiable {
        let rule: String
        let score: Int
        var id: String { rule }
    }

    struct Finding: Codable, Equatable, Identifiable {
        let id: UUID
        /// Seconds into the video; the player seeks here when tapped.
        let time: Double
        let rule: String
        let message: String
        let score: Int
    }
}
