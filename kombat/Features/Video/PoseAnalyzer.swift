//
//  PoseAnalyzer.swift
//  kombat
//

@preconcurrency import AVFoundation
import Vision

/// Reads a video file frame-by-frame and produces a timeline of body poses.
enum PoseAnalyzer {
    /// Frames are sampled at most this often; camera footage is 30–60fps but
    /// the skeleton doesn't need more than this to look smooth.
    private static let sampleInterval = 1.0 / 15.0
    private static let confidenceThreshold: Float = 0.3
    private static let minimumJoints = 4

    static func analyze(videoURL: URL) async throws -> [PoseFrame] {
        let asset = AVURLAsset(url: videoURL)
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            return []
        }
        let naturalSize = try await track.load(.naturalSize)
        let transform = try await track.load(.preferredTransform)

        // Portrait phone footage is stored landscape with a rotation transform;
        // Vision needs to know which way is up, and the overlay needs the
        // upright (display) aspect ratio.
        let orientation = orientation(from: transform)
        let displaySize = naturalSize.applying(transform)
        let imageAspect = abs(displaySize.width) / abs(displaySize.height)

        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ])
        reader.add(output)
        reader.startReading()

        let request = VNDetectHumanBodyPoseRequest()
        var frames: [PoseFrame] = []
        var lastSampledTime = -sampleInterval

        while let sampleBuffer = output.copyNextSampleBuffer() {
            try Task.checkCancellation()
            let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
            guard time - lastSampledTime >= sampleInterval,
                  let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { continue }
            lastSampledTime = time

            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation)
            try? handler.perform([request])

            guard let observation = request.results?.first,
                  let recognized = try? observation.recognizedPoints(.all) else { continue }

            var joints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
            for (name, point) in recognized where point.confidence > confidenceThreshold {
                // Vision uses a bottom-left origin; flip to top-left for drawing.
                joints[name] = CGPoint(x: point.location.x, y: 1 - point.location.y)
            }
            if joints.count >= minimumJoints {
                frames.append(PoseFrame(time: time, pose: DetectedPose(joints: joints, imageAspect: imageAspect)))
            }
        }
        return frames
    }

    private static func orientation(from transform: CGAffineTransform) -> CGImagePropertyOrientation {
        let angle = atan2(transform.b, transform.a) * 180 / .pi
        switch Int(angle.rounded()) {
        case 90: return .right
        case 180, -180: return .down
        case -90: return .left
        default: return .up
        }
    }
}
