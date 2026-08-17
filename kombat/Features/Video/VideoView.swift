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
    @State private var importFailed = false
    @State private var playingSession: ScanSession?

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
        .sheet(item: $playingSession) { session in
            ScanPlayerView(session: session)
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
                    playingSession = session
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

    /// Form analysis isn't built yet, so scans are logged with a placeholder score.
    private func logScan(durationSeconds: Int, videoURL: URL?) {
        Task {
            await scanRepository.addScan(
                category: .combo,
                formScore: Int.random(in: 60...92),
                durationSeconds: durationSeconds,
                videoTempURL: videoURL
            )
        }
    }
}

#Preview {
    NavigationStack {
        VideoView()
    }
    .environmentObject(ScanRepository())
}
