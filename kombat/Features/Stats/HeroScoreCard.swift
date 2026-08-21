//
//  HeroScoreCard.swift
//  kombat
//

import SwiftUI

struct HeroScoreCard: View {
    let averageScore: Int
    let delta: Int?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Average Form Score")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Text("\(averageScore)")
                    .font(Theme.Typography.largeTitle)
                    .foregroundStyle(Theme.Colors.textPrimary)
            }

            Spacer()

            if let delta, delta != 0 {
                let isUp = delta > 0
                HStack(spacing: 4) {
                    Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                    Text("\(abs(delta)) this month")
                }
                .font(Theme.Typography.caption.weight(.semibold))
                .foregroundStyle(isUp ? Theme.Colors.scoreGood : Theme.Colors.scoreLow)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background((isUp ? Theme.Colors.scoreGood : Theme.Colors.scoreLow).opacity(0.15), in: Capsule())
            }
        }
        .padding(Theme.Spacing.md)
        .cardStyle(elevated: true)
    }
}
