//
//  VideoView.swift
//  kombat
//

import PhotosUI
import SwiftUI

struct VideoView: View {
    @EnvironmentObject private var scanRepository: ScanRepository
    @State private var pickedVideo: PhotosPickerItem?
    @State private var isImporting = false
    @State private var isScoring = false
    @State private var importFailed = false
    @State private var playingSessionID: PlayingSessionID?
    @State private var showSourceMenu = false
    @State private var showCamera = false
    @State private var showPhotosPicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                Button {
                    showSourceMenu = true
                } label: {
                    HStack(spacing: Theme.Spacing.sm) {
                        if isImporting {
                            ProgressView()
                        } else {
                            Image(systemName: "plus.circle.fill")
                        }
                        Text(isImporting ? "Importing…" : "New Scan")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
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
        .onChange(of: pickedVideo) {
            guard let item = pickedVideo else { return }
            pickedVideo = nil
            importVideo(from: item)
        }
        .confirmationDialog("New Scan", isPresented: $showSourceMenu, titleVisibility: .hidden) {
            Button("Record Video") { showCamera = true }
            Button("Choose from Library") { showPhotosPicker = true }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(isPresented: $showPhotosPicker, selection: $pickedVideo, matching: .videos)
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView { url, durationSeconds in
                logScan(durationSeconds: durationSeconds, videoURL: url)
            }
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
