//
//  SessionsCompletedChart.swift
//  kombat
//

import SwiftUI
import Charts

struct SessionsCompletedChart: View {
    let weeks: [WeeklySessionCount]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "Sessions Completed")

            Chart(weeks) { week in
                BarMark(
                    x: .value("Week", week.weekLabel),
                    y: .value("Sessions", week.count)
                )
                .foregroundStyle(Theme.Colors.accentGradient)
                .cornerRadius(6)
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(Theme.Colors.cardBorder)
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
