//
//  VideoView.swift
//  kombat
//

import SwiftUI

struct VideoView: View {
    @StateObject private var camera = CameraService()
    @State private var sessions: [ScanSession] = MockData.scanSessions

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                ScanCameraCard(camera: camera)

                RecordButton(isRecording: recordingBinding)

                Text(statusText)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)

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
            // Form analysis isn't built yet, so log the scan with a placeholder score.
            let session = ScanSession(
                date: .now,
                category: .combo,
                formScore: Int.random(in: 60...92),
                durationSeconds: recording.durationSeconds
            )
            withAnimation { sessions.insert(session, at: 0) }
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
            return camera.isRecording ? "Recording…" : "Tap to start a scan"
        case .denied:
            return "Camera permission needed"
        case .failed:
            return "Camera unavailable"
        case .idle, .requestingPermission:
            return "Preparing camera…"
        }
    }
}

#Preview {
    NavigationStack {
        VideoView()
    }
}
