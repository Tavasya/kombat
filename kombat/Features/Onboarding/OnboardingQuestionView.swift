//
//  OnboardingQuestionView.swift
//  kombat
//

import SwiftUI

struct OnboardingQuestionView: View {
    let question: OnboardingQuestion
    @Binding var selectedOption: String?

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image(systemName: question.icon)
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(Theme.Colors.accentGradient)
                .frame(width: 88, height: 88)
                .background(Theme.Colors.surface, in: Circle())
                .accessibilityHidden(true)

            Text(question.question)
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.lg)

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(question.options, id: \.self) { option in
                    let isSelected = selectedOption == option

                    Button {
                        withAnimation(.easeOut(duration: 0.15)) { selectedOption = option }
                    } label: {
                        HStack {
                            Text(option)
                                .font(Theme.Typography.headline)
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.Colors.accent)
                            }
                        }
                        .padding(Theme.Spacing.md)
                        .cardStyle(elevated: isSelected)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                                .strokeBorder(isSelected ? Theme.Colors.accent : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)

            Spacer()
            Spacer()
        }
    }
}
