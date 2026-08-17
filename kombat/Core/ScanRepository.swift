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
            if let breakdown {
                await generateCoaching(for: scan, breakdown: breakdown)
            }
        } catch {
            errorMessage = "Couldn't save your scan. Check your connection."
        }
    }

    /// Best-effort: a failed coaching call never blocks or invalidates the scan.
    private func generateCoaching(for scan: ScanSession, breakdown: ScanBreakdown) async {
        guard let coaching = try? await CoachingClient.generate(from: breakdown) else { return }
        do {
            try await client.from("scans").update(["coaching": coaching]).eq("id", value: scan.id).execute()
            if let index = scans.firstIndex(where: { $0.id == scan.id }) {
                scans[index].coaching = coaching
            }
        } catch {
            // Scan already saved; coaching just didn't persist. Not user-facing.
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

    /// Whether each day of the current calendar week (Sun...Sat, per the
    /// device's locale) has at least one scan.
    var weekdayActivity: [Bool] {
        let calendar = Calendar.current
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: .now)?.start else {
            return Array(repeating: false, count: 7)
        }
        let activeDays = Set(scans.map { calendar.startOfDay(for: $0.date) })
        return (0..<7).map { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart) else { return false }
            return activeDays.contains(calendar.startOfDay(for: day))
        }
    }

    var sessionsThisWeek: Int {
        guard let weekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: .now) else { return 0 }
        return scans.filter { weekInterval.contains($0.date) }.count
    }

    var sessionsThisMonth: Int {
        guard let monthInterval = Calendar.current.dateInterval(of: .month, for: .now) else { return 0 }
        return scans.filter { monthInterval.contains($0.date) }.count
    }
}
