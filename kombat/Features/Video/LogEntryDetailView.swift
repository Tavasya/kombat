//
//  LogEntryDetailView.swift
//  kombat
//

import AVKit
import SwiftUI

/// Plays back a logged session's video. If it hasn't been analyzed yet, an
/// "Analyze" action runs pose detection + scoring on demand instead of doing
/// it automatically at log time.
struct LogEntryDetailView: View {
    let entryID: UUID

    @EnvironmentObject private var logRepository: LogRepository
    @Environment(\.dismiss) private var dismiss
    @State private var player = AVPlayer()
    @State private var poseFrames: [PoseFrame] = []
    @State private var currentPoses: [TrackedPose] = []
    @State private var timeObserver: Any?

    private var entry: LogEntry? {
        logRepository.entries.first(where: { $0.id == entryID })
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let entry {
                    VideoPlayer(player: player) {
                        PoseOverlayView(poses: currentPoses)
                    }
                    .background(.black)

                    if entry.status == .analyzed, let breakdown = entry.breakdown {
                        BreakdownPanel(score: entry.formScore ?? 0, breakdown: breakdown, coaching: entry.coaching) { time in
                            player.seek(to: CMTime(seconds: max(time - 1, 0), preferredTimescale: 600))
                            player.play()
                        }
                        .frame(maxHeight: 260)
                    } else {
                        analyzeBanner(for: entry)
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .background(Theme.Colors.background)
            .navigationTitle(entry?.title.isEmpty == false ? entry!.title : "Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear { startPlayback() }
        .onDisappear { tearDown() }
        .onChange(of: entry?.status) {
            if entry?.status == .analyzed { loadPoseCache() }
        }
    }

    @ViewBuilder
    private func analyzeBanner(for entry: LogEntry) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            switch entry.status {
            case .analyzing:
                ProgressView()
                Text("Analyzing your form…")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            case .failed:
                Text("Analysis failed — check your connection and try again.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.scoreLow)
                Button("Retry Analysis") { runAnalysis(entry) }
                    .buttonStyle(PrimaryButtonStyle())
            default:
                Text("This session hasn't been analyzed yet.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Button("Analyze This Session") { runAnalysis(entry) }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity)
    }

    private func runAnalysis(_ entry: LogEntry) {
        Task { await logRepository.analyze(entry) }
    }

    private func startPlayback() {
        guard let url = entry?.videoURL else { return }
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
        player.play()

        // Keep the skeleton in step with playback, including scrubbing.
        let interval = CMTime(value: 1, timescale: 30)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            let seconds = time.seconds
            currentPoses = poseFrames.last(where: { $0.time <= seconds + 0.05 })?.poses ?? []
        }

        if entry?.status == .analyzed {
            loadPoseCache()
        }
    }

    private func loadPoseCache() {
        guard let name = entry?.videoFileName, let cached = PoseCache.load(for: name) else { return }
        poseFrames = cached
    }

    private func tearDown() {
        player.pause()
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }
}
