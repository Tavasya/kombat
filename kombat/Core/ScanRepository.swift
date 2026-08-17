//
//  ScanRepository.swift
//  kombat
//

import Foundation
import Supabase

/// Loads and mutates the signed-in user's scans. Row-level security on the
/// server scopes every query to the current user automatically.
@MainActor
final class ScanRepository: ObservableObject {
    @Published private(set) var scans: [ScanSession] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private var client: SupabaseClient { SupabaseService.client }

    func load() async {
        isLoading = scans.isEmpty
        defer { isLoading = false }
        do {
            scans = try await client.from("scans")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't load your scans. Check your connection."
        }
    }

    /// Moves the video into permanent storage, caches its analyzed poses so
    /// playback never re-analyzes, and records the scan.
    func addScan(
        category: StrikeCategory,
        formScore: Int,
        durationSeconds: Int,
        breakdown: ScanBreakdown?,
        videoTempURL: URL?,
        poseFrames: [PoseFrame]
    ) async {
        do {
            let userID = try await client.auth.session.user.id
            let fileName = videoTempURL.flatMap { try? ScanVideoStore.store(fileAt: $0) }
            if let fileName, !poseFrames.isEmpty {
                PoseCache.save(poseFrames, for: fileName)
            }
            let scan = ScanSession(
                id: UUID(),
                userID: userID,
                date: .now,
                category: category,
                formScore: formScore,
                durationSeconds: durationSeconds,
                videoFileName: fileName,
                breakdown: breakdown
            )
            try await client.from("scans").insert(scan).execute()
            scans.insert(scan, at: 0)
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't save your scan. Check your connection."
        }
    }

    /// Removes the scan row and, if this device holds the video, the file too.
    func delete(_ scan: ScanSession) async {
        do {
            try await client.from("scans").delete().eq("id", value: scan.id).execute()
            if let name = scan.videoFileName {
                ScanVideoStore.deleteVideo(named: name)
                PoseCache.delete(for: name)
            }
            scans.removeAll { $0.id == scan.id }
        } catch {
            errorMessage = "Couldn't delete that scan. Check your connection."
        }
    }

    /// Consecutive days (through today or, if today has no scan yet, through
    /// yesterday) with at least one scan. Derived fresh from `scans` rather
    /// than stored, so it can never drift out of sync with the actual history.
    var streakDays: Int {
        guard !scans.isEmpty else { return 0 }
        let calendar = Calendar.current
        let activeDays = Set(scans.map { calendar.startOfDay(for: $0.date) })
        let today = calendar.startOfDay(for: .now)

        var streak = 0
        var cursor = activeDays.contains(today) ? today : calendar.date(byAdding: .day, value: -1, to: today)!
        while activeDays.contains(cursor) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previousDay
        }
        return streak
    }

    var averageScore: Int {
        guard !scans.isEmpty else { return 0 }
        return scans.reduce(0) { $0 + $1.formScore } / scans.count
    }
}
