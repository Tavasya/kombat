//
//  OnboardingPageView.swift
//  kombat
//

import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image(systemName: page.symbolName)
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(Theme.Colors.accentGradient)
                .frame(width: 120, height: 120)
                .background(Theme.Colors.surface, in: Circle())
                .accessibilityHidden(true)

            VStack(spacing: Theme.Spacing.sm) {
                Text(page.title)
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.lg)
            }

            Spacer()
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}
