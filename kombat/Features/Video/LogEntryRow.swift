//
//  LogEntryRow.swift
//  kombat
//

import SwiftUI

struct LogEntryRow: View {
    let entry: LogEntry

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: entry.category?.symbolName ?? "video.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.Colors.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title.isEmpty ? (entry.category?.rawValue ?? "Training Session") : entry.title)
                    .font(Theme.Typography.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(Self.dateFormatter.string(from: entry.sessionDate))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()

            if entry.videoURL != nil {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.Colors.accent)
            }

            Text(entry.durationText)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)

            statusIndicator
        }
        .padding(Theme.Spacing.sm)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var statusIndicator: some View {
        switch entry.status {
        case .analyzed:
            if let score = entry.formScore {
                ScoreBadge(score: score)
            }
        case .analyzing:
            ProgressView()
        case .pending:
            statusPill(text: "Not analyzed", color: Theme.Colors.textTertiary)
        case .failed:
            statusPill(text: "Failed", color: Theme.Colors.scoreLow)
        }
    }

    private func statusPill(text: String, color: Color) -> some View {
        Text(text)
            .font(Theme.Typography.caption)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.15), in: Capsule())
    }
}
