//
//  VideoView.swift
//  kombat
//

import PhotosUI
import SwiftUI

struct VideoView: View {
    @StateObject private var camera = CameraService()
    @EnvironmentObject private var scanRepository: ScanRepository
    @State private var pickedVideo: PhotosPickerItem?
    @State private var isImporting = false
    @State private var isScoring = false
    @State private var importFailed = false
    @State private var playingSessionID: PlayingSessionID?

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                ScanCameraCard(camera: camera)

                RecordButton(isRecording: recordingBinding)

                Text(statusText)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)

                PhotosPicker(selection: $pickedVideo, matching: .videos) {
                    HStack(spacing: Theme.Spacing.sm) {
                        if isImporting {
                            ProgressView()
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Text(isImporting ? "Importing…" : "Upload a Video")
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(isImporting)

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    SectionHeader(title: "Past Scans")

                    if isScoring {
                        HStack(spacing: Theme.Spacing.sm) {
                            ProgressView()
                            Text("Analyzing and scoring your scan…")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(Theme.Spacing.sm)
                    }

                    if let message = scanRepository.errorMessage {
                        Text(message)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.scoreLow)
                    }

                    if scanRepository.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(Theme.Spacing.lg)
                    } else if scanRepository.scans.isEmpty {
                        Text("No scans yet — record or upload your first one.")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(Theme.Spacing.lg)
                    } else {
                        LazyVStack(spacing: Theme.Spacing.sm) {
                            ForEach(scanRepository.scans) { session in
                                scanRow(session)
                            }
                        }
                    }
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.background.ignoresSafeArea())
        .navigationTitle("Video")
        .onAppear { camera.start() }
        .onDisappear { camera.stop() }
        .onChange(of: camera.lastRecording?.id) {
            guard let recording = camera.lastRecording else { return }
            logScan(durationSeconds: recording.durationSeconds, videoURL: recording.url)
        }
        .onChange(of: pickedVideo) {
            guard let item = pickedVideo else { return }
            pickedVideo = nil
            importVideo(from: item)
        }
        .sheet(item: $playingSessionID) { wrapper in
            // Look up live rather than capturing a snapshot, so the sheet
            // picks up coaching/updates that land after it's already open.
            if let session = scanRepository.scans.first(where: { $0.id == wrapper.id }) {
                ScanPlayerView(session: session)
            }
        }
        .alert("Couldn't import that video", isPresented: $importFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Try a different video from your library.")
        }
    }

    @ViewBuilder
    private func scanRow(_ session: ScanSession) -> some View {
        Group {
            if session.videoURL != nil {
                Button {
                    playingSessionID = PlayingSessionID(id: session.id)
                } label: {
                    ScanHistoryRow(session: session)
                }
                .buttonStyle(.plain)
            } else {
                ScanHistoryRow(session: session)
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                Task { await scanRepository.delete(session) }
            } label: {
                Label("Delete Scan", systemImage: "trash")
            }
        }
    }

    private var recordingBinding: Binding<Bool> {
        Binding(
            get: { camera.isRecording },
            set: { _ in camera.toggleRecording() }
        )
    }

    private var statusText: String {
        switch camera.status {
        case .ready:
            return camera.isRecording ? "Recording…" : "Tap to record, or upload from your library"
        case .denied:
            return "Camera permission needed — you can still upload a video"
        case .failed:
            return "Camera unavailable — you can still upload a video"
        case .idle, .requestingPermission:
            return "Preparing camera…"
        }
    }

    private func importVideo(from item: PhotosPickerItem) {
        isImporting = true
        Task {
            defer { isImporting = false }
            guard let video = try? await item.loadTransferable(type: ImportedVideo.self) else {
                importFailed = true
                return
            }
            logScan(durationSeconds: await video.durationSeconds(), videoURL: video.url)
        }
    }

    /// Analyzes poses, scores the form, and records the scan.
    private func logScan(durationSeconds: Int, videoURL: URL?) {
        Task {
            isScoring = true
            defer { isScoring = false }
            var frames: [PoseFrame] = []
            if let videoURL {
                frames = (try? await PoseAnalyzer.analyze(videoURL: videoURL)) ?? []
            }
            let result = FormScorer.score(frames: frames)
            await scanRepository.addScan(
                category: result.category,
                formScore: result.score,
                durationSeconds: durationSeconds,
                breakdown: result.breakdown,
                videoTempURL: videoURL,
                poseFrames: frames
            )
        }
    }
}

private struct PlayingSessionID: Identifiable {
    let id: UUID
}

#Preview {
    NavigationStack {
        VideoView()
    }
    .environmentObject(ScanRepository())
}
