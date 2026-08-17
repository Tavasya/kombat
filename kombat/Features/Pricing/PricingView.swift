//
//  PricingView.swift
//  kombat
//

import SwiftUI

struct PricingView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: StoreManager

    private let features = [
        "Unlimited AI form scans",
        "Full technique breakdowns by strike type",
        "Unlimited scan history",
        "Progress trends over time"
    ]

    private var priceText: String {
        store.product?.displayPrice ?? "$19.99"
    }

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                VStack(spacing: Theme.Spacing.xs) {
                    Text("Unlock Kombat Premium")
                        .font(Theme.Typography.title)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("Try it free for 7 days, then \(priceText)/month.")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Theme.Spacing.xl)

                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    HStack {
                        Text("7-Day Free Trial")
                            .font(Theme.Typography.headline)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Spacer()
                        Text("THEN \(priceText)/MO")
                            .font(Theme.Typography.eyebrow)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Theme.Colors.accentGradient, in: Capsule())
                    }

                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        ForEach(features, id: \.self) { feature in
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

                    Text("Cancel anytime before your trial ends and you won't be charged.")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
                .padding(Theme.Spacing.md)
                .cardStyle(elevated: true)
                .padding(.horizontal, Theme.Spacing.lg)

                if let errorMessage = store.errorMessage {
                    VStack(spacing: Theme.Spacing.xs) {
                        Text(errorMessage)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.scoreLow)
                            .multilineTextAlignment(.center)

                        Button("Retry") {
                            Task { await store.loadProduct() }
                        }
                        .font(Theme.Typography.caption.weight(.semibold))
                        .foregroundStyle(Theme.Colors.accent)
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                }

                Spacer()

                VStack(spacing: Theme.Spacing.md) {
                    PrimaryButton(title: store.isLoading ? "Loading…" : "Start Free Trial") {
                        subscribeTapped()
                    }
                    .disabled(store.product == nil || store.isLoading)
                    .opacity(store.product == nil ? 0.5 : 1)

                    Button("Restore Purchases") {
                        Task { await store.restorePurchases() }
                    }
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.bottom, Theme.Spacing.lg)
            }
        }
    }

    private func subscribeTapped() {
        Task {
            await store.purchase()
        }
    }
}

#Preview {
    PricingView()
        .environmentObject(AppState())
        .environmentObject(StoreManager())
}
