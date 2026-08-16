//
//  CategoryBreakdownChart.swift
//  kombat
//

import SwiftUI
import Charts

struct CategoryBreakdownChart: View {
    let categories: [CategoryScore]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "Category Breakdown")

            Chart(categories) { category in
                BarMark(
                    x: .value("Score", category.averageScore),
                    y: .value("Category", category.category.rawValue)
                )
                .foregroundStyle(Color.scoreColor(for: Int(category.averageScore)))
                .cornerRadius(6)
                .annotation(position: .trailing) {
                    Text("\(Int(category.averageScore))")
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
            .frame(height: 160)
        }
        .padding(Theme.Spacing.md)
        .cardStyle()
    }
}
