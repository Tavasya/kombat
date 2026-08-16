//
//  PricingView.swift
//  kombat
//

import SwiftUI

struct PricingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedPlanID: String = "free"

    private var plans: [PricingPlan] { MockData.pricingPlans }

    private var ctaTitle: String {
        guard let plan = plans.first(where: { $0.id == selectedPlanID }) else {
            return "Continue"
        }
        return "Continue with \(plan.name)"
    }

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                VStack(spacing: Theme.Spacing.xs) {
                    Text("Choose Your Plan")
                        .font(Theme.Typography.title)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("Unlock unlimited scans and detailed form breakdowns.")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Theme.Spacing.xl)
                .padding(.horizontal, Theme.Spacing.lg)

                ScrollView {
                    VStack(spacing: Theme.Spacing.md) {
                        ForEach(plans) { plan in
                            PricingPlanCard(
                                plan: plan,
                                isSelected: plan.id == selectedPlanID,
                                action: { withAnimation { selectedPlanID = plan.id } }
                            )
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.sm)
                }

                PrimaryButton(title: ctaTitle) {
                    appState.selectPricingPlan(selectedPlanID)
                }
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.bottom, Theme.Spacing.lg)
            }
        }
    }
}

#Preview {
    PricingView()
        .environmentObject(AppState())
}
