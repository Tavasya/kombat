//
//  StatsView.swift
//  kombat
//

import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var scanRepository: ScanRepository
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

                if scanRepository.scans.isEmpty {
                    emptyState
                } else {
                    HeroScoreCard(
                        averageScore: scanRepository.averageScore,
                        delta: scanRepository.monthOverMonthDelta
                    )

                    if let focusCategory = scanRepository.focusCategory {
                        FocusAreaCard(category: focusCategory)
                    }

                    Picker("Range", selection: $selectedRange) {
                        ForEach(StatsRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)

                    FormScoreTrendChart(points: scanRepository.trendPoints(for: selectedRange))
                    SessionsCompletedChart(weeks: scanRepository.recentWeeklySessionCounts)

                    if !scanRepository.categoryAverages.isEmpty {
                        CategoryBreakdownChart(categories: scanRepository.categoryAverages)
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
    .environmentObject(ScanRepository())
}
