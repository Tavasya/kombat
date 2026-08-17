//
//  ScanCoaching.swift
//  kombat
//

import Foundation

/// LLM-generated coaching prose, one entry per category. Derived entirely
/// from the engine's measured metrics — the model never sees video or poses.
struct ScanCoaching: Codable, Equatable {
    let categories: [CategoryNote]

    struct CategoryNote: Codable, Equatable, Identifiable {
        let name: String
        let assessment: String
        var id: String { name }
    }
}
