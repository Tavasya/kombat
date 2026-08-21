//
//  TrainingLogView.swift
//  kombat
//

import PhotosUI
import SwiftUI

struct TrainingLogView: View {
    @EnvironmentObject private var logRepository: LogRepository
    @State private var pickedVideo: PhotosPickerItem?
    @State private var isImporting = false
    @State private var importFailed = false
    @State private var openEntry: EntryIDWrapper?
    @State private var showSourceMenu = false
    @State private var showCamera = false
    @State private var showPhotosPicker = false
    @State private var pendingVideo: PendingVideo?

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
                        Text(isImporting ? "Importing…" : "Log Shadowbox")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isImporting)

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    SectionHeader(title: "Training Log")

                    if let message = logRepository.errorMessage {
                        Text(message)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.scoreLow)
                    }

                    if logRepository.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(Theme.Spacing.lg)
                    } else if logRepository.entries.isEmpty {
                        Text("No sessions logged yet — record or upload your first one.")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(Theme.Spacing.lg)
                    } else {
                        LazyVStack(spacing: Theme.Spacing.sm) {
                            ForEach(logRepository.entries) { entry in
                                entryRow(entry)
                            }
                        }
                    }
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.background.ignoresSafeArea())
        .navigationTitle("Log")
        .onChange(of: pickedVideo) {
            guard let item = pickedVideo else { return }
            pickedVideo = nil
            importVideo(from: item)
        }
        .confirmationDialog("Log Shadowbox", isPresented: $showSourceMenu, titleVisibility: .hidden) {
            Button("Record Video") { showCamera = true }
            Button("Choose from Library") { showPhotosPicker = true }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(isPresented: $showPhotosPicker, selection: $pickedVideo, matching: .videos)
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView { url, durationSeconds in
                pendingVideo = PendingVideo(url: url, durationSeconds: durationSeconds)
            }
        }
        .sheet(item: $pendingVideo) { pending in
            LogEntryFormView(videoURL: pending.url, durationSeconds: pending.durationSeconds) { title, sessionDate in
                Task {
                    await logRepository.logEntry(
                        title: title,
                        sessionDate: sessionDate,
                        durationSeconds: pending.durationSeconds,
                        videoTempURL: pending.url
                    )
                }
            }
        }
        .sheet(item: $openEntry) { wrapper in
            LogEntryDetailView(entryID: wrapper.id)
        }
        .alert("Couldn't import that video", isPresented: $importFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Try a different video from your library.")
        }
    }

    @ViewBuilder
    private func entryRow(_ entry: LogEntry) -> some View {
        Group {
            if entry.videoURL != nil {
                Button {
                    openEntry = EntryIDWrapper(id: entry.id)
                } label: {
                    LogEntryRow(entry: entry)
                }
                .buttonStyle(.plain)
            } else {
                LogEntryRow(entry: entry)
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                Task { await logRepository.delete(entry) }
            } label: {
                Label("Delete Entry", systemImage: "trash")
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
            pendingVideo = PendingVideo(url: video.url, durationSeconds: await video.durationSeconds())
        }
    }
}

private struct PendingVideo: Identifiable {
    let id = UUID()
    let url: URL
    let durationSeconds: Int
}

private struct EntryIDWrapper: Identifiable {
    let id: UUID
}

#Preview {
    NavigationStack {
        TrainingLogView()
    }
    .environmentObject(LogRepository())
}
