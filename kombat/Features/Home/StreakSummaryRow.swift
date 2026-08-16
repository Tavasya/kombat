//
//  StreakSummaryRow.swift
//  kombat
//

import SwiftUI

struct StreakSummaryRow: View {
    let summary: UserSummary

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            StatChip(value: "\(summary.streakDays)", label: "Day Streak", systemImage: "flame.fill")
            StatChip(value: "\(summary.totalSessions)", label: "Sessions", systemImage: "list.bullet")
            StatChip(value: "\(summary.averageScore)", label: "Avg Score", systemImage: "chart.line.uptrend.xyaxis")
        }
    }
}
