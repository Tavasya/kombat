//
//  OnboardingView.swift
//  kombat
//

import SwiftUI

private enum OnboardingStep {
    case question(OnboardingQuestion)
    case info(OnboardingPage)
}

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var currentPage = 0
    @State private var answers: [UUID: String] = [:]

    private var steps: [OnboardingStep] {
        MockData.onboardingQuestions.map { .question($0) } + MockData.onboardingPages.map { .info($0) }
    }

    private var isLastPage: Bool { currentPage == steps.count - 1 }

    private var canAdvance: Bool {
        switch steps[currentPage] {
        case .question(let question):
            return answers[question.id] != nil
        case .info:
            return true
        }
    }

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
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        stepView(step)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                PageIndicator(pageCount: steps.count, currentPage: currentPage)

                PrimaryButton(title: isLastPage ? "Get Started" : "Next") {
                    if isLastPage {
                        appState.completeOnboarding()
                    } else {
                        withAnimation { currentPage += 1 }
                    }
                }
                .disabled(!canAdvance)
                .opacity(canAdvance ? 1 : 0.5)
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.bottom, Theme.Spacing.lg)
            }
        }
    }

    @ViewBuilder
    private func stepView(_ step: OnboardingStep) -> some View {
        switch step {
        case .question(let question):
            OnboardingQuestionView(
                question: question,
                selectedOption: Binding(
                    get: { answers[question.id] },
                    set: { answers[question.id] = $0 }
                )
            )
        case .info(let page):
            OnboardingPageView(page: page)
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
