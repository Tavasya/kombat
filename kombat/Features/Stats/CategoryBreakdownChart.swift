//
//  CategoryBreakdownChart.swift
//  kombat
//

import SwiftUI
import Charts

struct CategoryBreakdownChart: View {
    let categories: [LogRepository.CategoryAverage]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "Category Breakdown")

            Chart(categories) { category in
                BarMark(
                    x: .value("Score", category.score),
                    y: .value("Category", category.name)
                )
                .foregroundStyle(Color.scoreColor(for: category.score))
                .cornerRadius(6)
                .annotation(position: .trailing) {
                    Text("\(category.score)")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .chartXScale(domain: 0...100)
            .chartXAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(Theme.Colors.cardBorder)
                    AxisValueLabel()
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .frame(height: CGFloat(categories.count) * 40 + 20)
        }
        .padding(Theme.Spacing.md)
        .cardStyle()
    }
}
