//
//  ScanSession.swift
//  kombat
//

import Foundation

enum StrikeCategory: String, Codable, CaseIterable {
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

/// One row of the Supabase `scans` table. Scan metadata lives in the cloud;
/// the video file itself stays on the device that captured it.
struct ScanSession: Identifiable, Codable, Equatable {
    let id: UUID
    let userID: UUID
    let date: Date
    let category: StrikeCategory
    let formScore: Int
    let durationSeconds: Int
    /// File name in `ScanVideoStore` on the capturing device; the bytes never upload.
    let videoFileName: String?
    /// Per-rule scoring evidence; nil for scans made before the scoring engine.
    let breakdown: ScanBreakdown?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case date = "created_at"
        case category
        case formScore = "form_score"
        case durationSeconds = "duration_seconds"
        case videoFileName = "video_file_name"
        case breakdown
    }

    /// Playable URL if this device still has the file (scans from other
    /// devices, or after the file was cleaned up, aren't playable).
    var videoURL: URL? {
        guard let videoFileName else { return nil }
        let url = ScanVideoStore.url(for: videoFileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    var durationText: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
