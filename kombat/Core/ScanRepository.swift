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

    /// Moves the video into permanent storage and records the scan.
    func addScan(category: StrikeCategory, formScore: Int, durationSeconds: Int, videoTempURL: URL?) async {
        do {
            let userID = try await client.auth.session.user.id
            let fileName = videoTempURL.flatMap { try? ScanVideoStore.store(fileAt: $0) }
            let scan = ScanSession(
                id: UUID(),
                userID: userID,
                date: .now,
                category: category,
                formScore: formScore,
                durationSeconds: durationSeconds,
                videoFileName: fileName
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
            }
            scans.removeAll { $0.id == scan.id }
        } catch {
            errorMessage = "Couldn't delete that scan. Check your connection."
        }
    }
}
