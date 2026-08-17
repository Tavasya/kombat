//
//  PoseOverlayView.swift
//  kombat
//

import SwiftUI
import Vision

/// Draws every detected skeleton over the video player, one color per person.
/// The player letterboxes the video (aspect-fit), so points map through the
/// same fit transform.
struct PoseOverlayView: View {
    let poses: [TrackedPose]

    private static let palette: [Color] = [Theme.Colors.accent, .cyan, .green, .orange]

    var body: some View {
        Canvas { context, size in
            for tracked in poses {
                draw(tracked.pose, color: Self.palette[tracked.id % Self.palette.count], in: &context, size: size)
            }
        }
        .allowsHitTesting(false)
    }

    private func draw(_ pose: DetectedPose, color: Color, in context: inout GraphicsContext, size: CGSize) {
        let viewAspect = size.width / size.height
        var drawWidth = size.width
        var drawHeight = size.height
        if pose.imageAspect > viewAspect {
            drawHeight = size.width / pose.imageAspect
        } else {
            drawWidth = size.height * pose.imageAspect
        }
        let xOffset = (size.width - drawWidth) / 2
        let yOffset = (size.height - drawHeight) / 2

        func viewPoint(_ joint: VNHumanBodyPoseObservation.JointName) -> CGPoint? {
            guard let p = pose.joints[joint] else { return nil }
            return CGPoint(x: xOffset + p.x * drawWidth, y: yOffset + p.y * drawHeight)
        }

        for (from, to) in DetectedPose.bones {
            guard let a = viewPoint(from), let b = viewPoint(to) else { continue }
            var path = Path()
            path.move(to: a)
            path.addLine(to: b)
            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }

        for joint in pose.joints.keys {
            guard let p = viewPoint(joint) else { continue }
            let dot = CGRect(x: p.x - 4, y: p.y - 4, width: 8, height: 8)
            context.fill(Path(ellipseIn: dot), with: .color(.white))
        }
    }
}
