//
//  ScanPlayerView.swift
//  kombat
//

import AVKit
import SwiftUI

/// Plays back a scan's video with the pose skeleton overlaid.
struct ScanPlayerView: View {
    let session: ScanSession

    @Environment(\.dismiss) private var dismiss
    @State private var player = AVPlayer()
    @State private var poseFrames: [PoseFrame] = []
    @State private var currentPoses: [TrackedPose] = []
    @State private var isAnalyzing = false
    @State private var timeObserver: Any?
    @State private var analysisTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VideoPlayer(player: player) {
                    PoseOverlayView(poses: currentPoses)
                }
                .background(.black)
                .overlay(alignment: .top) {
                    if isAnalyzing {
                        HStack(spacing: Theme.Spacing.sm) {
                            ProgressView()
                                .tint(.white)
                            Text("Analyzing form…")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(.black.opacity(0.55), in: Capsule())
                        .padding(.top, Theme.Spacing.md)
                    }
                }

                if let breakdown = session.breakdown {
                    BreakdownPanel(score: session.formScore, breakdown: breakdown) { time in
                        player.seek(to: CMTime(seconds: max(time - 1, 0), preferredTimescale: 600))
                        player.play()
                    }
                    .frame(maxHeight: 260)
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .background(Theme.Colors.background)
            .navigationTitle(session.category.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear { startPlayback() }
        .onDisappear { tearDown() }
    }

    private func startPlayback() {
        guard let url = session.videoURL else { return }
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
        player.play()

        // Keep the skeleton in step with playback, including scrubbing.
        let interval = CMTime(value: 1, timescale: 30)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            let seconds = time.seconds
            currentPoses = poseFrames.last(where: { $0.time <= seconds + 0.05 })?.poses ?? []
        }

        // Analysis runs once per video; later opens load the cached timeline.
        if let name = session.videoFileName, let cached = PoseCache.load(for: name) {
            poseFrames = cached
            return
        }
        isAnalyzing = true
        analysisTask = Task {
            let frames = (try? await PoseAnalyzer.analyze(videoURL: url)) ?? []
            if !Task.isCancelled {
                poseFrames = frames
                isAnalyzing = false
                if let name = session.videoFileName, !frames.isEmpty {
                    PoseCache.save(frames, for: name)
                }
            }
        }
    }

    private func tearDown() {
        player.pause()
        analysisTask?.cancel()
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }
}
