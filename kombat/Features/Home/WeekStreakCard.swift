//
//  WeekStreakCard.swift
//  kombat
//

import SwiftUI

struct WeekStreakCard: View {
    /// Sun...Sat activity for the current week.
    let weekdayActivity: [Bool]
    let streakDays: Int

    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    private var todayIndex: Int {
        Calendar.current.component(.weekday, from: .now) - 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("This Week")
                    .font(Theme.Typography.sectionTitle)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(Theme.Colors.accent)
                    Text("\(streakDays)")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
            }

            HStack(spacing: Theme.Spacing.sm) {
                ForEach(0..<7, id: \.self) { index in
                    dayPill(index)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("This week's streak: \(streakDays) days")
    }

    @ViewBuilder
    private func dayPill(_ index: Int) -> some View {
        let isActive = weekdayActivity[index]
        let isToday = index == todayIndex

        VStack(spacing: 6) {
            ZStack {
                Capsule()
                    .fill(isActive ? AnyShapeStyle(Theme.Colors.accentGradient) : AnyShapeStyle(Theme.Colors.surfaceElevated))
                    .frame(height: 48)
                    .overlay(
                        Capsule()
                            .strokeBorder(isToday && !isActive ? Theme.Colors.accent : .clear, lineWidth: 2)
                    )

                if isActive {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
            }

            Text(dayLabels[index])
                .font(Theme.Typography.caption)
                .foregroundStyle(isToday ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    VStack {
        WeekStreakCard(weekdayActivity: [false, false, true, true, false, false, false], streakDays: 2)
    }
    .padding()
    .background(Theme.Colors.background)
}
