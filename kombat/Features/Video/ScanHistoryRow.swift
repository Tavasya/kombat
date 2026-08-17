//
//  ScanHistoryRow.swift
//  kombat
//

import SwiftUI

struct ScanHistoryRow: View {
    let session: ScanSession

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: session.category.symbolName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.Colors.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.category.rawValue)
                    .font(Theme.Typography.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(Self.dateFormatter.string(from: session.date))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()

            if session.videoURL != nil {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.Colors.accent)
            }

            Text(session.durationText)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)

            ScoreBadge(score: session.formScore)
        }
        .padding(Theme.Spacing.sm)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}
