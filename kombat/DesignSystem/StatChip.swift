//
//  StatChip.swift
//  kombat
//

import SwiftUI

struct StatChip: View {
    let value: String
    let label: String
    var systemImage: String? = nil

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Colors.accent)
            }
            Text(value)
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.Colors.textPrimary)
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.md)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}
