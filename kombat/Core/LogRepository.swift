//
//  LogRepository.swift
//  kombat
//

import Foundation
import Supabase

/// Loads and mutates the signed-in user's training log. Row-level security on
/// the server scopes every query to the current user automatically.
///
/// Logging and analysis are deliberately separate steps: `logEntry` just
/// records that a session happened (video, name, date) with `status ==
/// .pending`; `analyze` is a distinct, user-triggered action that runs pose
/// detection and scoring on an already-logged entry.
@MainActor
final class LogRepository: ObservableObject {
    @Published private(set) var entries: [LogEntry] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private var client: SupabaseClient { SupabaseService.client }

    func load() async {
        isLoading = entries.isEmpty
        defer { isLoading = false }
        do {
            entries = try await client.from("log_entries")
                .select()
                .order("session_date", ascending: false)
                .execute()
                .value
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't load your training log. Check your connection."
        }
    }

    /// Moves the video into permanent storage and records the entry as
    /// `.pending` — no analysis happens here. Returns the created entry so
    /// the caller can offer to analyze it right away if the user wants to.
    @discardableResult
    func logEntry(title: String, sessionDate: Date, durationSeconds: Int, videoTempURL: URL?) async -> LogEntry? {
        do {
            let userID = try await client.auth.session.user.id
            let fileName = videoTempURL.flatMap { try? LogVideoStore.store(fileAt: $0) }
            let entry = LogEntry(
                id: UUID(),
                userID: userID,
                createdAt: .now,
                sessionDate: sessionDate,
                title: title,
                status: .pending,
                category: nil,
                formScore: nil,
                durationSeconds: durationSeconds,
                videoFileName: fileName,
                breakdown: nil,
                coaching: nil
            )
            try await client.from("log_entries").insert(entry).execute()
            entries.insert(entry, at: 0)
            errorMessage = nil
            return entry
        } catch {
            errorMessage = "Couldn't save that session. Check your connection."
            return nil
        }
    }

    /// Runs pose detection and scoring on an already-logged entry, then
    /// kicks off coaching generation. Safe to call again on a `.failed` entry.
    func analyze(_ entry: LogEntry) async {
        guard entry.status != .analyzing, let url = entry.videoURL else { return }
        setStatus(.analyzing, for: entry.id)

        let frames = (try? await PoseAnalyzer.analyze(videoURL: url)) ?? []
        if let name = entry.videoFileName, !frames.isEmpty {
            PoseCache.save(frames, for: name)
        }
        let result = FormScorer.score(frames: frames)

        struct AnalysisUpdate: Encodable {
            let category: String
            let formScore: Int
            let breakdown: AnalysisBreakdown
            let status: String

            enum CodingKeys: String, CodingKey {
                case category
                case formScore = "form_score"
                case breakdown
                case status
            }
        }

        do {
            let update = AnalysisUpdate(
                category: result.category.rawValue,
                formScore: result.score,
                breakdown: result.breakdown,
                status: LogEntry.Status.analyzed.rawValue
            )
            try await client.from("log_entries").update(update).eq("id", value: entry.id).execute()
            if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                entries[index].status = .analyzed
                entries[index].category = result.category
                entries[index].formScore = result.score
                entries[index].breakdown = result.breakdown
            }
            await generateCoaching(for: entry.id, breakdown: result.breakdown)
        } catch {
            setStatus(.failed, for: entry.id)
            errorMessage = "Couldn't save the analysis. Check your connection."
        }
    }

    private func setStatus(_ status: LogEntry.Status, for id: UUID) {
        Task { try? await client.from("log_entries").update(["status": status.rawValue]).eq("id", value: id).execute() }
        if let index = entries.firstIndex(where: { $0.id == id }) {
            entries[index].status = status
        }
    }

    /// Best-effort: a failed coaching call never blocks or invalidates the entry.
    private func generateCoaching(for id: UUID, breakdown: AnalysisBreakdown) async {
        guard let coaching = try? await CoachingClient.generate(from: breakdown) else { return }
        do {
            try await client.from("log_entries").update(["coaching": coaching]).eq("id", value: id).execute()
            if let index = entries.firstIndex(where: { $0.id == id }) {
                entries[index].coaching = coaching
            }
        } catch {
            // Entry already saved; coaching just didn't persist. Not user-facing.
        }
    }

    /// Removes the entry's row and, if this device holds the video, the file too.
    func delete(_ entry: LogEntry) async {
        do {
            try await client.from("log_entries").delete().eq("id", value: entry.id).execute()
            if let name = entry.videoFileName {
                LogVideoStore.deleteVideo(named: name)
                PoseCache.delete(for: name)
            }
            entries.removeAll { $0.id == entry.id }
        } catch {
            errorMessage = "Couldn't delete that entry. Check your connection."
        }
    }

    /// Consecutive days (through today or, if today has no entry yet, through
    /// yesterday) with at least one logged session. Derived fresh from
    /// `entries` rather than stored, so it can never drift out of sync.
    var streakDays: Int {
        guard !entries.isEmpty else { return 0 }
        let calendar = Calendar.current
        let activeDays = Set(entries.map { calendar.startOfDay(for: $0.sessionDate) })
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

    /// Analyzed entries only — unanalyzed sessions have no score to average.
    private var scoredEntries: [LogEntry] { entries.filter { $0.formScore != nil } }

    var averageScore: Int {
        guard !scoredEntries.isEmpty else { return 0 }
        return scoredEntries.reduce(0) { $0 + ($1.formScore ?? 0) } / scoredEntries.count
    }

    /// Whether each day of the current calendar week (Sun...Sat, per the
    /// device's locale) has at least one logged session.
    var weekdayActivity: [Bool] {
        let calendar = Calendar.current
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: .now)?.start else {
            return Array(repeating: false, count: 7)
        }
        let activeDays = Set(entries.map { calendar.startOfDay(for: $0.sessionDate) })
        return (0..<7).map { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart) else { return false }
            return activeDays.contains(calendar.startOfDay(for: day))
        }
    }

    var sessionsThisWeek: Int {
        guard let weekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: .now) else { return 0 }
        return entries.filter { weekInterval.contains($0.sessionDate) }.count
    }

    var sessionsThisMonth: Int {
        guard let monthInterval = Calendar.current.dateInterval(of: .month, for: .now) else { return 0 }
        return entries.filter { monthInterval.contains($0.sessionDate) }.count
    }

    // MARK: - Stats

    func trendPoints(for range: StatsRange) -> [StatPoint] {
        let calendar = Calendar.current
        let cutoff: Date?
        switch range {
        case .week: cutoff = calendar.dateInterval(of: .weekOfYear, for: .now)?.start
        case .month: cutoff = calendar.dateInterval(of: .month, for: .now)?.start
        case .allTime: cutoff = nil
        }
        return scoredEntries
            .filter { cutoff == nil || $0.sessionDate >= cutoff! }
            .sorted { $0.sessionDate < $1.sessionDate }
            .map { StatPoint(date: $0.sessionDate, score: Double($0.formScore ?? 0)) }
    }

    /// Session counts for the trailing 6 calendar weeks, oldest first.
    var recentWeeklySessionCounts: [WeeklySessionCount] {
        let calendar = Calendar.current
        let weekCount = 6
        guard let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: .now)?.start else { return [] }

        return (0..<weekCount).reversed().compactMap { offset -> WeeklySessionCount? in
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -offset, to: currentWeekStart),
                  let interval = calendar.dateInterval(of: .weekOfYear, for: weekStart) else { return nil }
            let count = entries.filter { interval.contains($0.sessionDate) }.count
            return WeeklySessionCount(weekLabel: offset == 0 ? "This Wk" : "-\(offset)wk", count: count)
        }
    }

    struct CategoryAverage: Identifiable {
        let name: String
        let score: Int
        var id: String { name }
    }

    /// Average score per real scoring-engine category (Striking, Blocking,
    /// Footwork, Positioning, Head Movement), weakest first. Entries without
    /// a breakdown (unanalyzed, or pre-scoring-engine) don't contribute.
    var categoryAverages: [CategoryAverage] {
        var totals: [String: (sum: Int, count: Int)] = [:]
        for entry in entries {
            guard let categories = entry.breakdown?.categories else { continue }
            for category in categories {
                var bucket = totals[category.name] ?? (0, 0)
                bucket.sum += category.score
                bucket.count += 1
                totals[category.name] = bucket
            }
        }
        return totals
            .map { CategoryAverage(name: $0.key, score: $0.value.sum / max($0.value.count, 1)) }
            .sorted { $0.score < $1.score }
    }

    /// The single category most worth training next.
    var focusCategory: CategoryAverage? {
        categoryAverages.first
    }

    /// This month's average score minus last month's, when both have data.
    var monthOverMonthDelta: Int? {
        let calendar = Calendar.current
        guard let thisMonth = calendar.dateInterval(of: .month, for: .now),
              let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: .now),
              let lastMonth = calendar.dateInterval(of: .month, for: lastMonthDate) else { return nil }

        let thisMonthEntries = scoredEntries.filter { thisMonth.contains($0.sessionDate) }
        let lastMonthEntries = scoredEntries.filter { lastMonth.contains($0.sessionDate) }
        guard !thisMonthEntries.isEmpty, !lastMonthEntries.isEmpty else { return nil }

        let thisAvg = thisMonthEntries.reduce(0) { $0 + ($1.formScore ?? 0) } / thisMonthEntries.count
        let lastAvg = lastMonthEntries.reduce(0) { $0 + ($1.formScore ?? 0) } / lastMonthEntries.count
        return thisAvg - lastAvg
    }
}

enum StatsRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case allTime = "All Time"
}
