//
//  SecondaryButtonStyle.swift
//  kombat
//

import SwiftUI

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.headline)
            .foregroundStyle(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.pill, style: .continuous)
                    .fill(Theme.Colors.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.pill, style: .continuous)
                    .strokeBorder(Theme.Colors.cardBorder, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
        }
        .buttonStyle(SecondaryButtonStyle())
    }
}

/// A borderless text-style link, e.g. "Already have an account? Log In".
struct TextLinkButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.accent)
        }
        .accessibilityAddTraits(.isLink)
    }
}
