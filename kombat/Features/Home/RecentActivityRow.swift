//
//  RecentActivityRow.swift
//  kombat
//

import SwiftUI

struct RecentActivityRow: View {
    let session: ScanSession

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: session.category.symbolName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.Colors.accent)
                .frame(width: 40, height: 40)
                .background(Theme.Colors.accent.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(session.category.rawValue)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text("\(Self.dateFormatter.string(from: session.date)) · \(session.durationText)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()

            ScoreBadge(score: session.formScore)
        }
        .padding(Theme.Spacing.sm)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}
