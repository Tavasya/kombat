//
//  ScoreBadge.swift
//  kombat
//

import SwiftUI

struct ScoreBadge: View {
    let score: Int

    private var color: Color { .scoreColor(for: score) }

    var body: some View {
        Text("\(score)")
            .font(Theme.Typography.caption)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.15), in: Capsule())
            .accessibilityLabel("Form score \(score) out of 100")
    }
}
