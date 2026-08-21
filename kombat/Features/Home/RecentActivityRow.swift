//
//  RecentActivityRow.swift
//  kombat
//

import SwiftUI

struct RecentActivityRow: View {
    let session: LogEntry

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: session.category?.symbolName ?? "video.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.Colors.accent)
                .frame(width: 40, height: 40)
                .background(Theme.Colors.accent.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(session.title.isEmpty ? (session.category?.rawValue ?? "Training Session") : session.title)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text("\(Self.dateFormatter.string(from: session.sessionDate)) · \(session.durationText)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()

            if let score = session.formScore {
                ScoreBadge(score: score)
            }
        }
        .padding(Theme.Spacing.sm)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}
