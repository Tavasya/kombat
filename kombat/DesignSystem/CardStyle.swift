//
//  CardStyle.swift
//  kombat
//

import SwiftUI

struct CardBackground: ViewModifier {
    var elevated: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .fill(elevated ? Theme.Colors.surfaceElevated : Theme.Colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .strokeBorder(Theme.Colors.cardBorder, lineWidth: 1)
            )
            .shadow(color: Theme.Colors.shadow, radius: elevated ? 12 : 6, y: elevated ? 6 : 3)
    }
}

extension View {
    func cardStyle(elevated: Bool = false) -> some View {
        modifier(CardBackground(elevated: elevated))
    }
}
