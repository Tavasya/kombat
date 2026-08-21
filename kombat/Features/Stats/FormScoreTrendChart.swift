//
//  FormScoreTrendChart.swift
//  kombat
//

import SwiftUI
import Charts

struct FormScoreTrendChart: View {
    let points: [StatPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "Form Score Trend")

            Chart(points) { point in
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Score", point.score)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.Colors.accent.opacity(0.35), Theme.Colors.accent.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Score", point.score)
                )
                .foregroundStyle(Theme.Colors.accent)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .interpolationMethod(.catmullRom)
            }
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(preset: .aligned, values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine().foregroundStyle(Theme.Colors.cardBorder)
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
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
            .frame(height: 180)
        }
        .padding(Theme.Spacing.md)
        .cardStyle()
    }
}
