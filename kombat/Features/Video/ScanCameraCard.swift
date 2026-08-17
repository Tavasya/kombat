//
//  ScanCameraCard.swift
//  kombat
//

import SwiftUI

/// The viewfinder card: live camera when available, guidance otherwise.
struct ScanCameraCard: View {
    @ObservedObject var camera: CameraService

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                .fill(Theme.Colors.surface)

            switch camera.status {
            case .ready:
                CameraPreviewView(session: camera.session)
            case .denied:
                message(
                    symbol: "video.slash",
                    text: "Camera access is off. Enable it in Settings to record scans."
                ) {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(Theme.Typography.caption.weight(.semibold))
                    .foregroundStyle(Theme.Colors.accent)
                }
            case .failed(let reason):
                message(symbol: "exclamationmark.triangle", text: reason) { EmptyView() }
            case .idle, .requestingPermission:
                message(symbol: "camera.viewfinder", text: "Starting camera…") { EmptyView() }
            }

            ForEach(Corner.allCases, id: \.self) { corner in
                ViewfinderCorner()
                    .stroke(Theme.Colors.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 28, height: 28)
                    .rotationEffect(corner.rotation)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: corner.alignment)
                    .padding(Theme.Spacing.md)
            }

            if camera.isRecording {
                recordingBadge
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, Theme.Spacing.md)
            }
        }
        .frame(height: 320)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
        .accessibilityLabel("Camera viewfinder")
    }

    private var recordingBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Theme.Colors.scoreLow)
                .frame(width: 8, height: 8)
            Text(timeText)
                .font(Theme.Typography.caption.monospacedDigit())
                .foregroundStyle(.white)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, 4)
        .background(.black.opacity(0.55), in: Capsule())
    }

    private var timeText: String {
        String(format: "%d:%02d", camera.recordingSeconds / 60, camera.recordingSeconds % 60)
    }

    private func message(symbol: String, text: String, @ViewBuilder action: () -> some View) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: symbol)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(Theme.Colors.textTertiary)
            Text(text)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.lg)
            action()
        }
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
