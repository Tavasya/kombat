//
//  LogEntry.swift
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

/// One row of the Supabase `log_entries` table. A logged training session —
/// video, name, and date — exists independently of analysis; the entry only
/// gets a category/score/breakdown once its `status` reaches `.analyzed`.
/// Log metadata lives in the cloud; the video file itself stays on the
/// device that captured it.
struct LogEntry: Identifiable, Codable, Equatable {
    enum Status: String, Codable {
        case pending
        case analyzing
        case analyzed
        case failed
    }

    let id: UUID
    let userID: UUID
    let createdAt: Date
    /// The date the user says this session happened — editable at log time,
    /// distinct from `createdAt` which is just when the row was inserted.
    var sessionDate: Date
    var title: String
    var status: Status
    /// Set once analysis completes; nil for a freshly logged, unanalyzed entry.
    var category: StrikeCategory?
    var formScore: Int?
    let durationSeconds: Int
    /// File name in `LogVideoStore` on the capturing device; the bytes never upload.
    let videoFileName: String?
    /// Per-rule scoring evidence; nil until analyzed.
    var breakdown: AnalysisBreakdown?
    /// LLM coaching prose derived from the breakdown; nil until generated.
    var coaching: AnalysisCoaching?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case createdAt = "created_at"
        case sessionDate = "session_date"
        case title
        case status
        case category
        case formScore = "form_score"
        case durationSeconds = "duration_seconds"
        case videoFileName = "video_file_name"
        case breakdown
        case coaching
    }

    /// Playable URL if this device still has the file (entries from other
    /// devices, or after the file was cleaned up, aren't playable).
    var videoURL: URL? {
        guard let videoFileName else { return nil }
        let url = LogVideoStore.url(for: videoFileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    var durationText: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
