//
//  DetectedPose.swift
//  kombat
//

import CoreGraphics
import Vision

/// A single frame's body pose. Joint points are normalized (0–1) with a
/// top-left origin in the upright frame, ready for view mapping.
struct DetectedPose: Codable {
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

    // Joint names are string wrappers, not directly Codable; store them by raw value.
    enum CodingKeys: String, CodingKey {
        case joints
        case imageAspect
    }

    init(joints: [VNHumanBodyPoseObservation.JointName: CGPoint], imageAspect: CGFloat) {
        self.joints = joints
        self.imageAspect = imageAspect
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let raw = try container.decode([String: CGPoint].self, forKey: .joints)
        joints = Dictionary(uniqueKeysWithValues: raw.map {
            (VNHumanBodyPoseObservation.JointName(rawValue: VNRecognizedPointKey(rawValue: $0.key)), $0.value)
        })
        imageAspect = try container.decode(CGFloat.self, forKey: .imageAspect)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let raw = Dictionary(uniqueKeysWithValues: joints.map { ($0.key.rawValue.rawValue, $0.value) })
        try container.encode(raw, forKey: .joints)
        try container.encode(imageAspect, forKey: .imageAspect)
    }
}

/// A pose with a stable identity across frames, so each person keeps
/// their own skeleton color as they move.
struct TrackedPose: Identifiable, Codable {
    let id: Int
    let pose: DetectedPose

    /// Average of all joint positions; used to match people across frames.
    var centroid: CGPoint {
        let points = pose.joints.values
        guard !points.isEmpty else { return .zero }
        let sum = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        return CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count))
    }
}

/// All detected poses at a moment in the video's timeline.
struct PoseFrame: Codable {
    let time: Double
    let poses: [TrackedPose]
}
