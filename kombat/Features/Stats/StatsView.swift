//
//  StatsView.swift
//  kombat
//

import SwiftUI

struct StatsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Your Progress")
                        .font(Theme.Typography.title)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("See how your form has improved over time.")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                FormScoreTrendChart(points: MockData.statPoints)
                SessionsCompletedChart(weeks: MockData.weeklySessions)
                CategoryBreakdownChart(categories: MockData.categoryScores)
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.background.ignoresSafeArea())
        .navigationTitle("Stats")
    }
}

#Preview {
    NavigationStack {
        StatsView()
    }
}
