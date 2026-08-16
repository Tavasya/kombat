//
//  OnboardingView.swift
//  kombat
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var currentPage = 0

    private var pages: [OnboardingPage] { MockData.onboardingPages }
    private var isLastPage: Bool { currentPage == pages.count - 1 }

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                HStack {
                    Spacer()
                    if !isLastPage {
                        Button("Skip") {
                            appState.skipOnboarding()
                        }
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                .frame(height: 20)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.sm)

                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                PageIndicator(pageCount: pages.count, currentPage: currentPage)

                PrimaryButton(title: isLastPage ? "Get Started" : "Next") {
                    if isLastPage {
                        appState.completeOnboarding()
                    } else {
                        withAnimation { currentPage += 1 }
                    }
                }
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.bottom, Theme.Spacing.lg)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
