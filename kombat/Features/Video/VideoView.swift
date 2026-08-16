//
//  VideoView.swift
//  kombat
//

import SwiftUI

struct VideoView: View {
    @State private var isRecording = false

    private var sessions: [ScanSession] { MockData.scanSessions }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                ScanPreviewPlaceholder()

                RecordButton(isRecording: $isRecording)

                Text(isRecording ? "Recording…" : "Tap to start a scan")
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
    }
}

#Preview {
    NavigationStack {
        VideoView()
    }
}
