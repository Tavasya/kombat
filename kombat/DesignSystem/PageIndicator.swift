//
//  PageIndicator.swift
//  kombat
//

import SwiftUI

struct PageIndicator: View {
    let pageCount: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<pageCount, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Theme.Colors.accent : Theme.Colors.surfaceElevated)
                    .frame(width: index == currentPage ? 20 : 6, height: 6)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentPage)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(currentPage + 1) of \(pageCount)")
    }
}
