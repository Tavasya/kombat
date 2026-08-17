//
//  TermsOfUseView.swift
//  kombat
//

import SwiftUI

struct TermsOfUseView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("Last updated: \(Date.now.formatted(date: .long, time: .omitted))")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)

                legalSection(
                    title: "Subscription",
                    body: "Kombat Premium is a $19.99/month auto-renewing subscription with a 7-day free trial. Payment is charged to your Apple ID account at confirmation of purchase. Your subscription automatically renews unless canceled at least 24 hours before the end of the current period. You can manage or cancel your subscription anytime from Settings or your Apple ID account settings."
                )
                legalSection(
                    title: "Acceptable Use",
                    body: "You agree to use Kombat only for its intended purpose of training form analysis, and not to misuse, disrupt, or attempt to reverse-engineer the service."
                )
                legalSection(
                    title: "Content",
                    body: "You retain ownership of any video you record or upload. By using the app, you grant us permission to process that video on your behalf solely to provide form analysis."
                )
                legalSection(
                    title: "Disclaimer",
                    body: "Kombat provides automated technique feedback for informational purposes only and is not a substitute for professional coaching or medical advice. Train at your own risk."
                )
                legalSection(
                    title: "Changes",
                    body: "We may update these terms from time to time. Continued use of the app after changes constitutes acceptance of the updated terms."
                )
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.background.ignoresSafeArea())
        .navigationTitle("Terms of Use")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func legalSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.textPrimary)
            Text(body)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }
}

#Preview {
    NavigationStack {
        TermsOfUseView()
    }
}
