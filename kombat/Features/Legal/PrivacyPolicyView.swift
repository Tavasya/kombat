//
//  PrivacyPolicyView.swift
//  kombat
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("Last updated: \(Date.now.formatted(date: .long, time: .omitted))")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)

                legalSection(
                    title: "Information We Collect",
                    body: "When you create an account, we collect your email address (and your name, if you sign in with Apple). When you record or upload a scan, we store the video locally on your device and send only the resulting form-analysis data (score, technique breakdown, timestamps) to our database."
                )
                legalSection(
                    title: "How We Use Your Information",
                    body: "We use your data to provide the app's core features: analyzing your training form, tracking your progress over time, and managing your subscription. We do not sell your personal data or collect information about you from third parties."
                )
                legalSection(
                    title: "AI-Powered Coaching",
                    body: "Your scan's measured scores and metrics (never the video itself or raw pose data) are sent to OpenAI to generate written coaching feedback. To opt out, contact us using the email below."
                )
                legalSection(
                    title: "Social Login",
                    body: "If you sign in with Apple, we receive your name and email from Apple to create your account. We don't offer any other third-party login."
                )
                legalSection(
                    title: "Third-Party Services",
                    body: "We use Supabase for authentication and data storage, and Apple's App Store for subscription billing. Payment information is handled entirely by Apple; we never see or store your payment details."
                )
                legalSection(
                    title: "Video Storage",
                    body: "Videos you record or upload are stored locally on your device and are never uploaded to our servers. They're only viewable on the device that captured or imported them."
                )
                legalSection(
                    title: "Data Retention & Deletion",
                    body: "Your data is retained until you delete your account. You can permanently delete your account and all associated data at any time from Settings."
                )
                legalSection(
                    title: "Contact",
                    body: "Questions about this policy can be directed to ordonez.rex1@gmail.com. The full policy is also available at kombat-website.vercel.app/privacy."
                )
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.background.ignoresSafeArea())
        .navigationTitle("Privacy Policy")
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
        PrivacyPolicyView()
    }
}
