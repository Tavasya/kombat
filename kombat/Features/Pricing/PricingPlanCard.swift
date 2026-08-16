//
//  PricingPlanCard.swift
//  kombat
//

import SwiftUI

struct PricingPlanCard: View {
    let plan: PricingPlan
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(plan.name)
                            .font(Theme.Typography.headline)
                            .foregroundStyle(Theme.Colors.textPrimary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(plan.priceText)
                                .font(Theme.Typography.title)
                                .foregroundStyle(Theme.Colors.textPrimary)
                            if let period = plan.billingPeriodText {
                                Text(period)
                                    .font(Theme.Typography.caption)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                        }
                    }

                    Spacer()

                    if plan.isRecommended {
                        Text("BEST VALUE")
                            .font(Theme.Typography.eyebrow)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Theme.Colors.accentGradient, in: Capsule())
                    }

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(isSelected ? Theme.Colors.accent : Theme.Colors.textTertiary)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    ForEach(plan.features, id: \.self) { feature in
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Theme.Colors.accent)
                            Text(feature)
                                .font(Theme.Typography.subheadline)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                }
                .padding(.top, Theme.Spacing.xs)
            }
            .padding(Theme.Spacing.md)
            .cardStyle(elevated: isSelected)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .strokeBorder(isSelected ? Theme.Colors.accent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
