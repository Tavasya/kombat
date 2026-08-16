//
//  LandingView.swift
//  kombat
//

import SwiftUI

struct LandingView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.xl) {
                Spacer()

                VStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "figure.martial.arts")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(Theme.Colors.accentGradient)
                        .accessibilityHidden(true)

                    Text("KOMBAT")
                        .font(Theme.Typography.largeTitle)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .tracking(2)

                    Text("Scan your strikes. Perfect your form.")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                VStack(spacing: Theme.Spacing.md) {
                    PrimaryButton(title: "Get Started") {
                        appState.beginOnboarding()
                    }

                    TextLinkButton(title: "Already have an account? Log In") {
                        appState.skipToAuth()
                    }
                }
                .padding(.bottom, Theme.Spacing.lg)
            }
            .padding(.horizontal, Theme.Spacing.xl)
        }
    }
}

#Preview {
    LandingView()
        .environmentObject(AppState())
}
