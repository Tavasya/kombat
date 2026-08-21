//
//  AnalysisBreakdown.swift
//  kombat
//

import Foundation

/// The evidence behind a log entry's form score: per-rule averages and the
/// specific timestamped moments where form broke down. Stored on the entry's
/// row in Supabase, stamped with the engine version that produced it.
struct AnalysisBreakdown: Codable, Equatable {
    let engineVersion: Int
    let repCount: Int
    /// Set when there was nothing to score (no person / no punches detected).
    let note: String?
    let ruleScores: [RuleScore]
    let findings: [Finding]
    /// What was thrown, per auto-classified technique. Optional because
    /// engine-v1 rows predate classification.
    let techniques: [TechniqueCount]?
    /// Per-category assessment (Striking, Blocking, Footwork, Positioning,
    /// Head Movement). Optional because pre-v3 rows predate categories.
    let categories: [CategoryReport]?

    struct CategoryReport: Codable, Equatable, Identifiable {
        let name: String
        let score: Int
        /// The measurements behind the score, ready to feed an LLM or display.
        let metrics: [MetricValue]
        /// Set when this category couldn't be measured reliably (e.g. feet
        /// out of frame) — the honest alternative to a made-up score.
        let dataNote: String?
        var id: String { name }
    }

    struct MetricValue: Codable, Equatable, Identifiable {
        let name: String
        let value: String
        let score: Int
        var id: String { name }
    }

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
        /// Which category this belongs to; optional on pre-v3 rows.
        let category: String?
    }
}
