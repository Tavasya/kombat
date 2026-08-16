//
//  PrimaryButtonStyle.swift
//  kombat
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var isProminent: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.pill, style: .continuous)
                    .fill(isProminent ? AnyShapeStyle(Theme.Colors.accentGradient) : AnyShapeStyle(Theme.Colors.surfaceElevated))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct PrimaryButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .tracking(0.5)
        }
        .buttonStyle(PrimaryButtonStyle())
    }
}
