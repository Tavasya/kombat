//
//  FocusAreaCard.swift
//  kombat
//

import SwiftUI

struct FocusAreaCard: View {
    let category: ScanRepository.CategoryAverage

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "target")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.scoreColor(for: category.score))
                .frame(width: 44, height: 44)
                .background(Color.scoreColor(for: category.score).opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("Focus Area: \(category.name)")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text("Averaging \(category.score) — your lowest-scoring category. Prioritize this next session.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .padding(Theme.Spacing.md)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}
