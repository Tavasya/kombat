//
//  StatsView.swift
//  kombat
//

import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var logRepository: LogRepository
    @State private var selectedRange: StatsRange = .month

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

                if logRepository.entries.isEmpty {
                    emptyState
                } else {
                    HeroScoreCard(
                        averageScore: logRepository.averageScore,
                        delta: logRepository.monthOverMonthDelta
                    )

                    if let focusCategory = logRepository.focusCategory {
                        FocusAreaCard(category: focusCategory)
                    }

                    Picker("Range", selection: $selectedRange) {
                        ForEach(StatsRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)

                    FormScoreTrendChart(points: logRepository.trendPoints(for: selectedRange))
                    SessionsCompletedChart(weeks: logRepository.recentWeeklySessionCounts)

                    if !logRepository.categoryAverages.isEmpty {
                        CategoryBreakdownChart(categories: logRepository.categoryAverages)
                    }
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.background.ignoresSafeArea())
        .navigationTitle("Stats")
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundStyle(Theme.Colors.textTertiary)
            Text("No stats yet")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.textPrimary)
            Text("Record or upload your first scan to start tracking your progress.")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Theme.Spacing.xxl)
        .padding(.horizontal, Theme.Spacing.lg)
    }
}

#Preview {
    NavigationStack {
        StatsView()
    }
    .environmentObject(LogRepository())
}
