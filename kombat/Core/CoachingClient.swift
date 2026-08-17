//
//  CoachingClient.swift
//  kombat
//

import Foundation
import Supabase

/// Calls the `coach-feedback` Edge Function to turn the engine's measured
/// metrics into coaching prose. Never sends video or pose data — just the
/// category scores, their supporting metrics, and flagged findings.
enum CoachingClient {
    static func generate(from breakdown: ScanBreakdown) async throws -> ScanCoaching {
        guard let categories = breakdown.categories, !categories.isEmpty else {
            throw CoachingError.noCategories
        }

        struct RequestBody: Encodable {
            let repCount: Int
            let categories: [ScanBreakdown.CategoryReport]
            let findings: [ScanBreakdown.Finding]
        }

        let body = RequestBody(repCount: breakdown.repCount, categories: categories, findings: breakdown.findings)
        let data = try JSONEncoder().encode(body)

        return try await SupabaseService.client.functions.invoke(
            "coach-feedback",
            options: FunctionInvokeOptions(body: data),
            decode: { data, _ in try JSONDecoder().decode(ScanCoaching.self, from: data) }
        )
    }

    enum CoachingError: LocalizedError {
        case noCategories
        var errorDescription: String? { "No measured categories to coach from." }
    }
}
