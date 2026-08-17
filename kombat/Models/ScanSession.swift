//
//  ScanSession.swift
//  kombat
//

import Foundation

enum StrikeCategory: String, CaseIterable {
    case jabCross = "Jab/Cross"
    case roundKick = "Round Kick"
    case footwork = "Footwork"
    case combo = "Combo"

    var symbolName: String {
        switch self {
        case .jabCross: return "figure.boxing"
        case .roundKick: return "figure.martial.arts"
        case .footwork: return "shoeprints.fill"
        case .combo: return "bolt.fill"
        }
    }
}

struct ScanSession: Identifiable {
    let id = UUID()
    let date: Date
    let category: StrikeCategory
    let formScore: Int
    let durationSeconds: Int
    /// Present only for scans captured this session; mock history has no video.
    var videoURL: URL? = nil

    var durationText: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
