//
//  DetectedPose.swift
//  kombat
//

import CoreGraphics
import Vision

/// A single frame's body pose. Joint points are normalized (0–1) with a
/// top-left origin in the upright frame, ready for view mapping.
struct DetectedPose {
    let joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    /// Width / height of the upright video frame, needed for letterbox mapping.
    let imageAspect: CGFloat

    /// Bone connections to draw, as joint pairs.
    static let bones: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        // Arms
        (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
        // Torso
        (.leftShoulder, .rightShoulder),
        (.leftShoulder, .leftHip), (.rightShoulder, .rightHip),
        (.leftHip, .rightHip),
        // Legs
        (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee), (.rightKnee, .rightAnkle),
        // Head
        (.neck, .nose)
    ]
}

/// A pose pinned to a moment in the video's timeline.
struct PoseFrame {
    let time: Double
    let pose: DetectedPose
}
