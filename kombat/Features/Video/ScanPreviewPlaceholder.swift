//
//  ScanPreviewPlaceholder.swift
//  kombat
//

import SwiftUI

struct ScanPreviewPlaceholder: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                .fill(Theme.Colors.surface)

            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textTertiary)
                Text("Camera preview coming soon")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            ForEach(Corner.allCases, id: \.self) { corner in
                ViewfinderCorner()
                    .stroke(Theme.Colors.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 28, height: 28)
                    .rotationEffect(corner.rotation)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: corner.alignment)
                    .padding(Theme.Spacing.md)
            }
        }
        .frame(height: 320)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
        .accessibilityLabel("Camera preview placeholder")
    }
}

private enum Corner: CaseIterable {
    case topLeading, topTrailing, bottomLeading, bottomTrailing

    var alignment: Alignment {
        switch self {
        case .topLeading: return .topLeading
        case .topTrailing: return .topTrailing
        case .bottomLeading: return .bottomLeading
        case .bottomTrailing: return .bottomTrailing
        }
    }

    var rotation: Angle {
        switch self {
        case .topLeading: return .degrees(0)
        case .topTrailing: return .degrees(90)
        case .bottomTrailing: return .degrees(180)
        case .bottomLeading: return .degrees(270)
        }
    }
}

private struct ViewfinderCorner: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}
