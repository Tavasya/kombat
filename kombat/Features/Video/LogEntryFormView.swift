//
//  LogEntryFormView.swift
//  kombat
//

import SwiftUI

/// Shown right after recording/picking a video: name it, confirm the date,
/// and save. Analysis is a separate step the user triggers later from the
/// entry itself — logging a session shouldn't require waiting on it.
struct LogEntryFormView: View {
    let videoURL: URL
    let durationSeconds: Int
    let onSave: (String, Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var sessionDate = Date.now
    @State private var isSaving = false

    private static let defaultTitleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name this session", text: $title, prompt: Text(defaultTitle))
                    DatePicker("Date", selection: $sessionDate, in: ...Date.now, displayedComponents: .date)
                }

                Section {
                    Label(durationText, systemImage: "video.fill")
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .navigationTitle("Log Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        isSaving = true
                        onSave(title.isEmpty ? defaultTitle : title, sessionDate)
                        dismiss()
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private var defaultTitle: String {
        "Shadowbox — \(Self.defaultTitleFormatter.string(from: sessionDate))"
    }

    private var durationText: String {
        String(format: "%d:%02d recorded", durationSeconds / 60, durationSeconds % 60)
    }
}
