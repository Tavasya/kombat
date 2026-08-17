//
//  FormScorer.swift
//  kombat
//

import CoreGraphics
import Foundation
import Vision

/// Scores a pose timeline against explicit form rules. Pure math over the
/// analyzed poses — no ML judges form, so every score can explain itself.
///
/// v1 covers punch (jab/cross) rules. Distances are normalized by the
/// person's own shoulder width so camera distance doesn't matter.
enum FormScorer {
    static let engineVersion = 1

    /// Tuning knobs, kept in one place so they can move to remote config later.
    struct Config {
        // Segmentation: wrist speed in shoulder-widths/second that counts as a punch.
        var minPunchSpeed = 3.5
        var minPeakSeparation = 0.5
        var repWindowBefore = 0.35
        var repWindowAfter = 0.6

        // Rules: target = full credit, floor = zero credit, linear in between.
        var extensionTargetDegrees = 165.0
        var extensionFloorDegrees = 120.0
        var guardTargetWidths = 0.5
        var guardFloorWidths = 1.2
        var retractionTargetSeconds = 0.35
        var retractionFloorSeconds = 0.9
        var rotationTargetRatio = 0.88
        var rotationFloorRatio = 1.0

        var weights: [Rule: Double] = [
            .armExtension: 0.30,
            .guardPosition: 0.35,
            .retraction: 0.20,
            .rotation: 0.15
        ]
    }

    enum Rule: String, CaseIterable {
        case armExtension = "Extension"
        case guardPosition = "Guard"
        case retraction = "Retraction"
        case rotation = "Rotation"

        var failureMessage: String {
            switch self {
            case .armExtension: return "Punch didn't fully extend"
            case .guardPosition: return "Rear hand drifted from your chin"
            case .retraction: return "Slow return to guard"
            case .rotation: return "Little body rotation behind the punch"
            }
        }
    }

    private enum Side {
        case left, right

        var wrist: VNHumanBodyPoseObservation.JointName { self == .left ? .leftWrist : .rightWrist }
        var elbow: VNHumanBodyPoseObservation.JointName { self == .left ? .leftElbow : .rightElbow }
        var shoulder: VNHumanBodyPoseObservation.JointName { self == .left ? .leftShoulder : .rightShoulder }
        var other: Side { self == .left ? .right : .left }
    }

    private struct Sample {
        let time: Double
        let joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    }

    private struct Rep {
        let peakTime: Double
        let side: Side
        var ruleScores: [Rule: Double] = [:]
    }

    // MARK: - Entry point

    static func score(frames: [PoseFrame], config: Config = Config()) -> (score: Int, breakdown: ScanBreakdown) {
        let samples = primaryPersonSamples(from: frames)
        guard samples.count >= 10 else {
            return empty(note: "No person was detected in this video.")
        }

        let shoulderWidth = medianShoulderWidth(samples)
        guard shoulderWidth > 0 else {
            return empty(note: "Couldn't read body proportions from this video.")
        }

        let reps = segmentReps(samples: samples, shoulderWidth: shoulderWidth, config: config)
        guard !reps.isEmpty else {
            return empty(note: "No punches were detected in this video.")
        }

        let scored = reps.map { evaluate(rep: $0, samples: samples, shoulderWidth: shoulderWidth, config: config) }

        // Roll up: per-rep weighted score, then averages and findings.
        var repScores: [Double] = []
        var findings: [ScanBreakdown.Finding] = []
        for rep in scored {
            let weighted = Rule.allCases.reduce(0.0) { $0 + (rep.ruleScores[$1] ?? 0) * (config.weights[$1] ?? 0) }
            repScores.append(weighted)
            // Surface the rep's worst rule when it's genuinely weak.
            if let worst = rep.ruleScores.min(by: { $0.value < $1.value }), worst.value < 70 {
                findings.append(ScanBreakdown.Finding(
                    id: UUID(),
                    time: rep.peakTime,
                    rule: worst.key.rawValue,
                    message: worst.key.failureMessage,
                    score: Int(worst.value.rounded())
                ))
            }
        }

        let ruleAverages = Rule.allCases.map { rule in
            let values = scored.compactMap { $0.ruleScores[rule] }
            let average = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
            return ScanBreakdown.RuleScore(rule: rule.rawValue, score: Int(average.rounded()))
        }

        let overall = Int((repScores.reduce(0, +) / Double(repScores.count)).rounded())
        let breakdown = ScanBreakdown(
            engineVersion: engineVersion,
            repCount: scored.count,
            note: nil,
            ruleScores: ruleAverages,
            findings: findings.sorted { $0.time < $1.time }
        )
        return (overall, breakdown)
    }

    private static func empty(note: String) -> (score: Int, breakdown: ScanBreakdown) {
        (0, ScanBreakdown(engineVersion: engineVersion, repCount: 0, note: note, ruleScores: [], findings: []))
    }

    // MARK: - Preparation

    /// The person present in the most frames is the one being scored, so a
    /// partner in frame doesn't pollute the metrics.
    private static func primaryPersonSamples(from frames: [PoseFrame]) -> [Sample] {
        var counts: [Int: Int] = [:]
        for frame in frames {
            for pose in frame.poses {
                counts[pose.id, default: 0] += 1
            }
        }
        guard let primary = counts.max(by: { $0.value < $1.value })?.key else { return [] }
        return frames.compactMap { frame in
            frame.poses.first(where: { $0.id == primary }).map { Sample(time: frame.time, joints: $0.pose.joints) }
        }
    }

    private static func medianShoulderWidth(_ samples: [Sample]) -> Double {
        let widths = samples.compactMap { sample -> Double? in
            guard let l = sample.joints[.leftShoulder], let r = sample.joints[.rightShoulder] else { return nil }
            return distance(l, r)
        }.sorted()
        guard !widths.isEmpty else { return 0 }
        return widths[widths.count / 2]
    }

    // MARK: - Segmentation

    /// Wrist-speed spikes (either arm) above threshold become reps.
    private static func segmentReps(samples: [Sample], shoulderWidth: Double, config: Config) -> [Rep] {
        var reps: [Rep] = []
        for side in [Side.left, Side.right] {
            let speeds = wristSpeeds(samples: samples, side: side, shoulderWidth: shoulderWidth)
            for i in 1..<max(speeds.count - 1, 1) {
                let s = speeds[i]
                guard s.speed > config.minPunchSpeed,
                      s.speed >= speeds[i - 1].speed,
                      s.speed >= speeds[i + 1].speed else { continue }
                if let last = reps.last(where: { $0.side == side }),
                   s.time - last.peakTime < config.minPeakSeparation { continue }
                reps.append(Rep(peakTime: s.time, side: side))
            }
        }
        return reps.sorted { $0.peakTime < $1.peakTime }
    }

    private static func wristSpeeds(samples: [Sample], side: Side, shoulderWidth: Double) -> [(time: Double, speed: Double)] {
        var result: [(Double, Double)] = [(samples[0].time, 0)]
        for i in 1..<samples.count {
            let dt = samples[i].time - samples[i - 1].time
            guard dt > 0,
                  let a = samples[i - 1].joints[side.wrist],
                  let b = samples[i].joints[side.wrist] else {
                result.append((samples[i].time, 0))
                continue
            }
            result.append((samples[i].time, distance(a, b) / dt / shoulderWidth))
        }
        // Light smoothing so single-frame jitter doesn't fake a punch.
        return result.enumerated().map { i, entry in
            let lo = max(0, i - 1), hi = min(result.count - 1, i + 1)
            let avg = (lo...hi).reduce(0.0) { $0 + result[$1].1 } / Double(hi - lo + 1)
            return (entry.0, avg)
        }
    }

    // MARK: - Rules

    private static func evaluate(rep: Rep, samples: [Sample], shoulderWidth: Double, config: Config) -> Rep {
        var rep = rep
        let window = samples.filter {
            $0.time >= rep.peakTime - config.repWindowBefore && $0.time <= rep.peakTime + config.repWindowAfter
        }
        guard !window.isEmpty else { return rep }
        let side = rep.side

        // Extension: peak elbow angle of the striking arm.
        let peakAngle = window.compactMap { sample -> Double? in
            guard let s = sample.joints[side.shoulder],
                  let e = sample.joints[side.elbow],
                  let w = sample.joints[side.wrist] else { return nil }
            return angleDegrees(at: e, from: s, to: w)
        }.max() ?? 0
        rep.ruleScores[.armExtension] = linearScore(
            peakAngle, target: config.extensionTargetDegrees, floor: config.extensionFloorDegrees, higherIsBetter: true
        )

        // Guard: the off hand stays near the chin while the strike happens.
        let guardDistances = window.compactMap { sample -> Double? in
            guard let wrist = sample.joints[side.other.wrist],
                  let chin = sample.joints[.nose] ?? sample.joints[.neck] else { return nil }
            return distance(wrist, chin) / shoulderWidth
        }
        let meanGuard = guardDistances.isEmpty ? config.guardFloorWidths : guardDistances.reduce(0, +) / Double(guardDistances.count)
        rep.ruleScores[.guardPosition] = linearScore(
            meanGuard, target: config.guardTargetWidths, floor: config.guardFloorWidths, higherIsBetter: false
        )

        // Retraction: how quickly the striking wrist slows back down after the peak.
        let speeds = wristSpeeds(samples: samples, side: side, shoulderWidth: shoulderWidth)
        let retracted = speeds.first(where: { $0.time > rep.peakTime + 0.1 && $0.speed < 1.0 })
        let retractionTime = retracted.map { $0.time - rep.peakTime } ?? config.retractionFloorSeconds
        rep.ruleScores[.retraction] = linearScore(
            retractionTime, target: config.retractionTargetSeconds, floor: config.retractionFloorSeconds, higherIsBetter: false
        )

        // Rotation (2D proxy): shoulders turning compresses their apparent width.
        let minWidth = window.compactMap { sample -> Double? in
            guard let l = sample.joints[.leftShoulder], let r = sample.joints[.rightShoulder] else { return nil }
            return distance(l, r)
        }.min() ?? shoulderWidth
        rep.ruleScores[.rotation] = linearScore(
            minWidth / shoulderWidth, target: config.rotationTargetRatio, floor: config.rotationFloorRatio, higherIsBetter: false
        )

        return rep
    }

    // MARK: - Math

    private static func linearScore(_ value: Double, target: Double, floor: Double, higherIsBetter: Bool) -> Double {
        let progress: Double
        if higherIsBetter {
            progress = (value - floor) / (target - floor)
        } else {
            progress = (floor - value) / (floor - target)
        }
        return min(max(progress, 0), 1) * 100
    }

    private static func distance(_ a: CGPoint, _ b: CGPoint) -> Double {
        Double(hypot(a.x - b.x, a.y - b.y))
    }

    private static func angleDegrees(at vertex: CGPoint, from a: CGPoint, to b: CGPoint) -> Double {
        let v1 = CGVector(dx: a.x - vertex.x, dy: a.y - vertex.y)
        let v2 = CGVector(dx: b.x - vertex.x, dy: b.y - vertex.y)
        let dot = Double(v1.dx * v2.dx + v1.dy * v2.dy)
        let mag = Double(hypot(v1.dx, v1.dy) * hypot(v2.dx, v2.dy))
        guard mag > 0 else { return 0 }
        return acos(min(max(dot / mag, -1), 1)) * 180 / .pi
    }
}
