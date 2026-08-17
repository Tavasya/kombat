//
//  HomeView.swift
//  kombat
//

import SwiftUI

struct HomeView: View {
    let onStartScan: () -> Void

    private var summary: UserSummary { MockData.userSummary }
    private var sessions: [ScanSession] { MockData.scanSessions }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Welcome back, \(summary.displayName)")
                        .font(Theme.Typography.title)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("Ready to sharpen your form today?")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                StreakSummaryRow(summary: summary)

                Button(action: onStartScan) {
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 28, weight: .semibold))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Start a Scan")
                                .font(Theme.Typography.headline)
                            Text("Get instant feedback on your form")
                                .font(Theme.Typography.caption)
                                .opacity(0.9)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundStyle(.white)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.accentGradient, in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                }
                .buttonStyle(.plain)

                SectionHeader(title: "Recent Activity")

                LazyVStack(spacing: Theme.Spacing.sm) {
                    ForEach(sessions) { session in
                        RecentActivityRow(session: session)
                    }
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.background.ignoresSafeArea())
        .navigationTitle("Home")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
                .accessibilityLabel("Settings")
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(onStartScan: {})
    }
}
