//
//  VideoView.swift
//  kombat
//

import PhotosUI
import SwiftUI

struct VideoView: View {
    @StateObject private var camera = CameraService()
    @State private var sessions: [ScanSession] = MockData.scanSessions
    @State private var pickedVideo: PhotosPickerItem?
    @State private var isImporting = false
    @State private var importFailed = false

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

                    LazyVStack(spacing: Theme.Spacing.sm) {
                        ForEach(sessions) { session in
                            ScanHistoryRow(session: session)
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
            logScan(durationSeconds: recording.durationSeconds)
        }
        .onChange(of: pickedVideo) {
            guard let item = pickedVideo else { return }
            pickedVideo = nil
            importVideo(from: item)
        }
        .alert("Couldn't import that video", isPresented: $importFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Try a different video from your library.")
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
            logScan(durationSeconds: await video.durationSeconds())
        }
    }

    /// Form analysis isn't built yet, so scans are logged with a placeholder score.
    private func logScan(durationSeconds: Int) {
        let session = ScanSession(
            date: .now,
            category: .combo,
            formScore: Int.random(in: 60...92),
            durationSeconds: durationSeconds
        )
        withAnimation { sessions.insert(session, at: 0) }
    }
}

#Preview {
    NavigationStack {
        VideoView()
    }
}
