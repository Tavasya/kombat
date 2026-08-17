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
/// v2: no user-declared category. Each detected rep is auto-classified
/// (punch/kick/knee, then technique) by geometry and graded with that
/// technique's rules; uncertain reps get only the universal rules. A
/// continuous "guard discipline" rule runs across the whole video.
enum FormScorer {
    static let engineVersion = 2

    /// Tuning knobs, kept in one place so they can move to remote config later.
    struct Config {
        // Segmentation: limb speed in shoulder-widths/second that counts as a strike.
        var minStrikeSpeed = 3.5
        var minPeakSeparation = 0.5
        var repWindowBefore = 0.35
        var repWindowAfter = 0.6

        // Classification boundaries.
        var straightElbowMinDegrees = 145.0
        var hookElbowMaxDegrees = 115.0
        var kneeBentMaxDegrees = 110.0
        var kickExtendedMinDegrees = 140.0
        var roundKickMaxRotationRatio = 0.92
        // Check vs knee strike: a check has a vertical shin and quiet hips.
        var checkShinMaxOffsetWidths = 0.35
        var checkMaxHipDriveWidths = 0.2
        var checkMinKneeAboveHip = -0.2

        // Rule targets: target = full credit, floor = zero credit, linear between.
        var punchExtensionTarget = 165.0, punchExtensionFloor = 120.0
        var hookElbowIdeal = 90.0, hookElbowTolerance = 20.0, hookElbowFloor = 60.0
        var kickExtensionTarget = 150.0, kickExtensionFloor = 110.0
        var kneeHeightTarget = 0.0, kneeHeightFloor = 0.6   // knee above hip (in sw) at peak
        var shinAngleTargetWidths = 0.2, shinAngleFloorWidths = 0.5
        var guardTargetWidths = 0.5, guardFloorWidths = 1.2
        var retractionTargetSeconds = 0.35, retractionFloorSeconds = 0.9
        var rotationTargetRatio = 0.88, rotationFloorRatio = 1.0

        // Guard discipline (whole-video interval rule).
        var disciplineGuardWidths = 0.8
        var disciplineLapseSeconds = 2.0
        var disciplineWeight = 0.15
    }

    enum Technique: String {
        case straightPunch = "Straight Punch"
        case hook = "Hook"
        case teep = "Teep"
        case roundKick = "Round Kick"
        case kneeStrike = "Knee"
        case check = "Check"
        case unknown = "Strike"
    }

    enum Rule: String {
        case armExtension = "Extension"
        case elbowShape = "Hook Shape"
        case kneeHeight = "Knee Height"
        case shinAngle = "Shin Angle"
        case guardPosition = "Guard"
        case retraction = "Retraction"
        case rotation = "Rotation"
        case guardDiscipline = "Guard Discipline"

        func failureMessage(for technique: Technique) -> String {
            switch self {
            case .armExtension: return "\(technique.rawValue) didn't fully extend"
            case .elbowShape: return "Hook lost its shape — keep the elbow near 90°"
            case .kneeHeight:
                return technique == .check ? "Check didn't lift high enough to shield" : "Knee didn't drive high enough"
            case .shinAngle: return "Check's shin wasn't vertical — let the ankle hang under the knee"
            case .guardPosition: return "Off hand drifted from your chin"
            case .retraction: return "Slow return after the \(technique.rawValue.lowercased())"
            case .rotation: return "Little body rotation behind the \(technique.rawValue.lowercased())"
            case .guardDiscipline: return "Hands dropped between strikes"
            }
        }
    }

    private struct Limb: Hashable {
        let isArm: Bool
        let isLeft: Bool

        var strikeJoint: VNHumanBodyPoseObservation.JointName {
            switch (isArm, isLeft) {
            case (true, true): return .leftWrist
            case (true, false): return .rightWrist
            case (false, true): return .leftAnkle
            case (false, false): return .rightAnkle
            }
        }

        var midJoint: VNHumanBodyPoseObservation.JointName {
            switch (isArm, isLeft) {
            case (true, true): return .leftElbow
            case (true, false): return .rightElbow
            case (false, true): return .leftKnee
            case (false, false): return .rightKnee
            }
        }

        var rootJoint: VNHumanBodyPoseObservation.JointName {
            switch (isArm, isLeft) {
            case (true, true): return .leftShoulder
            case (true, false): return .rightShoulder
            case (false, true): return .leftHip
            case (false, false): return .rightHip
            }
        }

        var otherWrist: VNHumanBodyPoseObservation.JointName {
            isLeft ? .rightWrist : .leftWrist
        }

        static let all: [Limb] = [
            Limb(isArm: true, isLeft: true), Limb(isArm: true, isLeft: false),
            Limb(isArm: false, isLeft: true), Limb(isArm: false, isLeft: false)
        ]
    }

    private struct Sample {
        let time: Double
        let joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    }

    private struct Rep {
        let peakTime: Double
        let limb: Limb
        var technique: Technique = .unknown
        var heightLabel: String?
        var ruleScores: [Rule: Double] = [:]
    }

    // MARK: - Entry point

    static func score(
        frames: [PoseFrame],
        config: Config = Config()
    ) -> (score: Int, category: StrikeCategory, breakdown: ScanBreakdown) {
        let samples = primaryPersonSamples(from: frames)
        guard samples.count >= 10 else {
            return empty(note: "No person was detected in this video.")
        }
        let shoulderWidth = medianShoulderWidth(samples)
        guard shoulderWidth > 0 else {
            return empty(note: "Couldn't read body proportions from this video.")
        }

        var reps = segmentReps(samples: samples, shoulderWidth: shoulderWidth, config: config)
        guard !reps.isEmpty else {
            return empty(note: "No strikes were detected in this video.")
        }

        for i in reps.indices {
            classify(rep: &reps[i], samples: samples, shoulderWidth: shoulderWidth, config: config)
            evaluate(rep: &reps[i], samples: samples, shoulderWidth: shoulderWidth, config: config)
        }

        let discipline = guardDiscipline(samples: samples, reps: reps, shoulderWidth: shoulderWidth, config: config)

        // Roll up.
        var findings: [ScanBreakdown.Finding] = []
        var repScores: [Double] = []
        for rep in reps {
            let weights = weightsFor(rep.technique, config: config)
            let totalWeight = rep.ruleScores.keys.reduce(0.0) { $0 + (weights[$1] ?? 0) }
            guard totalWeight > 0 else { continue }
            let weighted = rep.ruleScores.reduce(0.0) { $0 + $1.value * (weights[$1.key] ?? 0) } / totalWeight
            repScores.append(weighted)
            if let worst = rep.ruleScores.min(by: { $0.value < $1.value }), worst.value < 70 {
                findings.append(ScanBreakdown.Finding(
                    id: UUID(),
                    time: rep.peakTime,
                    rule: worst.key.rawValue,
                    message: worst.key.failureMessage(for: rep.technique),
                    score: Int(worst.value.rounded())
                ))
            }
        }
        findings.append(contentsOf: discipline.findings)

        var ruleTotals: [Rule: (sum: Double, count: Int)] = [:]
        for rep in reps {
            for (rule, value) in rep.ruleScores {
                let entry = ruleTotals[rule] ?? (0, 0)
                ruleTotals[rule] = (entry.sum + value, entry.count + 1)
            }
        }
        var ruleScores = ruleTotals.map { rule, entry in
            ScanBreakdown.RuleScore(rule: rule.rawValue, score: Int((entry.sum / Double(entry.count)).rounded()))
        }.sorted { $0.rule < $1.rule }
        ruleScores.append(ScanBreakdown.RuleScore(rule: Rule.guardDiscipline.rawValue, score: discipline.score))

        // Per-technique summary.
        var byTechnique: [Technique: [Double]] = [:]
        for (rep, score) in zip(reps, repScores) {
            byTechnique[rep.technique, default: []].append(score)
        }
        let techniques = byTechnique.map { technique, scores in
            ScanBreakdown.TechniqueCount(
                technique: technique.rawValue,
                count: scores.count,
                averageScore: Int((scores.reduce(0, +) / Double(scores.count)).rounded())
            )
        }.sorted { $0.count > $1.count }

        let repAverage = repScores.isEmpty ? 0 : repScores.reduce(0, +) / Double(repScores.count)
        let overall = Int((repAverage * (1 - config.disciplineWeight) + Double(discipline.score) * config.disciplineWeight).rounded())

        let breakdown = ScanBreakdown(
            engineVersion: engineVersion,
            repCount: reps.count,
            note: nil,
            ruleScores: ruleScores,
            findings: findings.sorted { $0.time < $1.time },
            techniques: techniques
        )
        return (overall, derivedCategory(reps: reps), breakdown)
    }

    private static func empty(note: String) -> (score: Int, category: StrikeCategory, breakdown: ScanBreakdown) {
        (0, .combo, ScanBreakdown(engineVersion: engineVersion, repCount: 0, note: note, ruleScores: [], findings: [], techniques: []))
    }

    /// The scan's category label is derived from what was actually thrown.
    private static func derivedCategory(reps: [Rep]) -> StrikeCategory {
        let arms = reps.filter { $0.limb.isArm }.count
        let ratio = Double(arms) / Double(reps.count)
        if ratio >= 0.7 { return .jabCross }
        if ratio <= 0.3 { return .roundKick }
        return .combo
    }

    // MARK: - Preparation

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

    private static func segmentReps(samples: [Sample], shoulderWidth: Double, config: Config) -> [Rep] {
        var reps: [Rep] = []
        for limb in Limb.all {
            let speeds = jointSpeeds(samples: samples, joint: limb.strikeJoint, shoulderWidth: shoulderWidth)
            guard speeds.count > 2 else { continue }
            for i in 1..<(speeds.count - 1) {
                let s = speeds[i]
                guard s.speed > config.minStrikeSpeed,
                      s.speed >= speeds[i - 1].speed,
                      s.speed >= speeds[i + 1].speed else { continue }
                if let last = reps.last(where: { $0.limb == limb }),
                   s.time - last.peakTime < config.minPeakSeparation { continue }
                reps.append(Rep(peakTime: s.time, limb: limb))
            }
        }
        return reps.sorted { $0.peakTime < $1.peakTime }
    }

    private static func jointSpeeds(
        samples: [Sample],
        joint: VNHumanBodyPoseObservation.JointName,
        shoulderWidth: Double
    ) -> [(time: Double, speed: Double)] {
        guard !samples.isEmpty else { return [] }
        var result: [(Double, Double)] = [(samples[0].time, 0)]
        for i in 1..<samples.count {
            let dt = samples[i].time - samples[i - 1].time
            guard dt > 0,
                  let a = samples[i - 1].joints[joint],
                  let b = samples[i].joints[joint] else {
                result.append((samples[i].time, 0))
                continue
            }
            result.append((samples[i].time, distance(a, b) / dt / shoulderWidth))
        }
        // Light smoothing so single-frame jitter doesn't fake a strike.
        return result.enumerated().map { i, entry in
            let lo = max(0, i - 1), hi = min(result.count - 1, i + 1)
            let avg = (lo...hi).reduce(0.0) { $0 + result[$1].1 } / Double(hi - lo + 1)
            return (entry.0, avg)
        }
    }

    // MARK: - Classification

    private static func classify(rep: inout Rep, samples: [Sample], shoulderWidth: Double, config: Config) {
        let window = window(for: rep, in: samples, config: config)
        guard !window.isEmpty else { return }
        let limb = rep.limb

        let peakLimbAngle = window.compactMap { sample -> Double? in
            guard let root = sample.joints[limb.rootJoint],
                  let mid = sample.joints[limb.midJoint],
                  let end = sample.joints[limb.strikeJoint] else { return nil }
            return angleDegrees(at: mid, from: root, to: end)
        }.max() ?? 0

        if limb.isArm {
            if peakLimbAngle >= config.straightElbowMinDegrees {
                rep.technique = .straightPunch
            } else if peakLimbAngle <= config.hookElbowMaxDegrees, peakLimbAngle > 0 {
                rep.technique = .hook
            } else {
                rep.technique = .unknown
            }
            return
        }

        // Leg family: check vs knee strike vs teep vs round kick.
        let rotation = minShoulderRatio(in: window, baseline: shoulderWidth)

        // Measure at the moment the knee is highest.
        var kneeAboveHip = -1.0
        var shinOffset = Double.infinity
        var ankleBelowKnee = false
        for sample in window {
            guard let knee = sample.joints[limb.midJoint],
                  let hip = sample.joints[limb.rootJoint],
                  let ankle = sample.joints[limb.strikeJoint] else { continue }
            let above = Double(hip.y - knee.y) / shoulderWidth   // positive = knee above hip
            if above > kneeAboveHip {
                kneeAboveHip = above
                shinOffset = Double(abs(ankle.x - knee.x)) / shoulderWidth
                ankleBelowKnee = ankle.y > knee.y
            }
        }
        let hipXs = window.compactMap { $0.joints[limb.rootJoint]?.x }
        let hipDrive = hipXs.isEmpty ? 0 : Double((hipXs.max()! - hipXs.min()!)) / shoulderWidth

        if peakLimbAngle <= config.kneeBentMaxDegrees, peakLimbAngle > 0 {
            if ankleBelowKnee,
               shinOffset <= config.checkShinMaxOffsetWidths,
               hipDrive <= config.checkMaxHipDriveWidths,
               kneeAboveHip >= config.checkMinKneeAboveHip {
                rep.technique = .check
            } else if kneeAboveHip > 0 {
                rep.technique = .kneeStrike
            } else {
                rep.technique = .unknown
            }
        } else if peakLimbAngle >= config.kickExtendedMinDegrees {
            rep.technique = rotation < config.roundKickMaxRotationRatio ? .roundKick : .teep
            if rep.technique == .roundKick {
                rep.heightLabel = kickHeightLabel(rep: rep, window: window)
            }
        } else {
            rep.technique = .unknown
        }
    }

    private static func kickHeightLabel(rep: Rep, window: [Sample]) -> String {
        // Compare the ankle's highest point against shoulder and hip lines.
        var best: (ankleY: CGFloat, shoulderY: CGFloat, hipY: CGFloat)?
        for sample in window {
            guard let ankle = sample.joints[rep.limb.strikeJoint],
                  let ls = sample.joints[.leftShoulder], let rs = sample.joints[.rightShoulder],
                  let lh = sample.joints[.leftHip], let rh = sample.joints[.rightHip] else { continue }
            if best == nil || ankle.y < best!.ankleY {
                best = (ankle.y, (ls.y + rs.y) / 2, (lh.y + rh.y) / 2)
            }
        }
        guard let best else { return "Low Kick" }
        if best.ankleY <= best.shoulderY { return "Head Kick" }
        if best.ankleY <= best.hipY { return "Body Kick" }
        return "Low Kick"
    }

    // MARK: - Grading

    private static func weightsFor(_ technique: Technique, config: Config) -> [Rule: Double] {
        switch technique {
        case .straightPunch:
            return [.armExtension: 0.30, .guardPosition: 0.35, .retraction: 0.20, .rotation: 0.15]
        case .hook:
            return [.elbowShape: 0.30, .guardPosition: 0.30, .retraction: 0.15, .rotation: 0.25]
        case .teep:
            return [.armExtension: 0.40, .guardPosition: 0.30, .retraction: 0.30]
        case .roundKick:
            return [.armExtension: 0.25, .guardPosition: 0.25, .retraction: 0.15, .rotation: 0.35]
        case .kneeStrike:
            return [.kneeHeight: 0.40, .guardPosition: 0.35, .retraction: 0.25]
        case .check:
            return [.kneeHeight: 0.30, .shinAngle: 0.30, .guardPosition: 0.25, .retraction: 0.15]
        case .unknown:
            return [.guardPosition: 0.6, .retraction: 0.4]
        }
    }

    private static func evaluate(rep: inout Rep, samples: [Sample], shoulderWidth: Double, config: Config) {
        let window = window(for: rep, in: samples, config: config)
        guard !window.isEmpty else { return }
        let limb = rep.limb
        let rules = weightsFor(rep.technique, config: config)

        let peakLimbAngle = window.compactMap { sample -> Double? in
            guard let root = sample.joints[limb.rootJoint],
                  let mid = sample.joints[limb.midJoint],
                  let end = sample.joints[limb.strikeJoint] else { return nil }
            return angleDegrees(at: mid, from: root, to: end)
        }.max() ?? 0

        if rules.keys.contains(.armExtension) {
            let (target, floor) = limb.isArm
                ? (config.punchExtensionTarget, config.punchExtensionFloor)
                : (config.kickExtensionTarget, config.kickExtensionFloor)
            rep.ruleScores[.armExtension] = linearScore(peakLimbAngle, target: target, floor: floor, higherIsBetter: true)
        }

        if rules.keys.contains(.elbowShape) {
            let deviation = abs(peakLimbAngle - config.hookElbowIdeal)
            rep.ruleScores[.elbowShape] = linearScore(
                deviation, target: config.hookElbowTolerance, floor: config.hookElbowFloor, higherIsBetter: false
            )
        }

        if rules.keys.contains(.kneeHeight) {
            let kneeAboveHip = window.compactMap { sample -> Double? in
                guard let knee = sample.joints[limb.midJoint], let hip = sample.joints[limb.rootJoint] else { return nil }
                return Double(hip.y - knee.y) / shoulderWidth
            }.max() ?? -config.kneeHeightFloor
            // Higher above the hip is better; at-or-above hip line is full credit.
            rep.ruleScores[.kneeHeight] = linearScore(
                kneeAboveHip, target: config.kneeHeightTarget, floor: -config.kneeHeightFloor, higherIsBetter: true
            )
        }

        if rules.keys.contains(.shinAngle) {
            var offset = config.shinAngleFloorWidths
            var bestAbove = -Double.infinity
            for sample in window {
                guard let knee = sample.joints[limb.midJoint],
                      let hip = sample.joints[limb.rootJoint],
                      let ankle = sample.joints[limb.strikeJoint] else { continue }
                let above = Double(hip.y - knee.y) / shoulderWidth
                if above > bestAbove {
                    bestAbove = above
                    offset = Double(abs(ankle.x - knee.x)) / shoulderWidth
                }
            }
            rep.ruleScores[.shinAngle] = linearScore(
                offset, target: config.shinAngleTargetWidths, floor: config.shinAngleFloorWidths, higherIsBetter: false
            )
        }

        if rules.keys.contains(.guardPosition) {
            let guardDistances = window.compactMap { sample -> Double? in
                guard let chin = sample.joints[.nose] ?? sample.joints[.neck] else { return nil }
                if limb.isArm {
                    guard let wrist = sample.joints[limb.otherWrist] else { return nil }
                    return distance(wrist, chin) / shoulderWidth
                }
                // Leg techniques: both hands should stay up; judge the worse one.
                guard let lw = sample.joints[.leftWrist], let rw = sample.joints[.rightWrist] else { return nil }
                return max(distance(lw, chin), distance(rw, chin)) / shoulderWidth
            }
            let mean = guardDistances.isEmpty
                ? config.guardFloorWidths
                : guardDistances.reduce(0, +) / Double(guardDistances.count)
            rep.ruleScores[.guardPosition] = linearScore(
                mean, target: config.guardTargetWidths, floor: config.guardFloorWidths, higherIsBetter: false
            )
        }

        if rules.keys.contains(.retraction) {
            let speeds = jointSpeeds(samples: samples, joint: limb.strikeJoint, shoulderWidth: shoulderWidth)
            let retracted = speeds.first(where: { $0.time > rep.peakTime + 0.1 && $0.speed < 1.0 })
            let retractionTime = retracted.map { $0.time - rep.peakTime } ?? config.retractionFloorSeconds
            rep.ruleScores[.retraction] = linearScore(
                retractionTime, target: config.retractionTargetSeconds, floor: config.retractionFloorSeconds, higherIsBetter: false
            )
        }

        if rules.keys.contains(.rotation) {
            let ratio = minShoulderRatio(in: window, baseline: shoulderWidth)
            rep.ruleScores[.rotation] = linearScore(
                ratio, target: config.rotationTargetRatio, floor: config.rotationFloorRatio, higherIsBetter: false
            )
        }
    }

    // MARK: - Guard discipline (interval rule)

    private static func guardDiscipline(
        samples: [Sample],
        reps: [Rep],
        shoulderWidth: Double,
        config: Config
    ) -> (score: Int, findings: [ScanBreakdown.Finding]) {
        // Only judge the stretches between strikes.
        let isStriking: (Double) -> Bool = { time in
            reps.contains { abs($0.peakTime - time) < config.repWindowAfter }
        }

        var judged = 0
        var up = 0
        var lapseStart: Double?
        var findings: [ScanBreakdown.Finding] = []

        func closeLapse(at time: Double) {
            if let start = lapseStart, time - start >= config.disciplineLapseSeconds {
                findings.append(ScanBreakdown.Finding(
                    id: UUID(),
                    time: start,
                    rule: Rule.guardDiscipline.rawValue,
                    message: Rule.guardDiscipline.failureMessage(for: .unknown),
                    score: 0
                ))
            }
            lapseStart = nil
        }

        for sample in samples {
            guard !isStriking(sample.time),
                  let lw = sample.joints[.leftWrist],
                  let rw = sample.joints[.rightWrist],
                  let chin = sample.joints[.nose] ?? sample.joints[.neck] else { continue }
            judged += 1
            let worst = max(distance(lw, chin), distance(rw, chin)) / shoulderWidth
            if worst <= config.disciplineGuardWidths {
                up += 1
                closeLapse(at: sample.time)
            } else if lapseStart == nil {
                lapseStart = sample.time
            }
        }
        if let last = samples.last { closeLapse(at: last.time + config.disciplineLapseSeconds) }

        guard judged > 0 else { return (100, []) }
        return (Int((Double(up) / Double(judged) * 100).rounded()), findings)
    }

    // MARK: - Math

    private static func window(for rep: Rep, in samples: [Sample], config: Config) -> [Sample] {
        samples.filter {
            $0.time >= rep.peakTime - config.repWindowBefore && $0.time <= rep.peakTime + config.repWindowAfter
        }
    }

    private static func minShoulderRatio(in window: [Sample], baseline: Double) -> Double {
        let minWidth = window.compactMap { sample -> Double? in
            guard let l = sample.joints[.leftShoulder], let r = sample.joints[.rightShoulder] else { return nil }
            return distance(l, r)
        }.min() ?? baseline
        return minWidth / baseline
    }

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
