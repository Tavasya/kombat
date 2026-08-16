//
//  RecordButton.swift
//  kombat
//

import SwiftUI

struct RecordButton: View {
    @Binding var isRecording: Bool

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isRecording.toggle()
            }
        } label: {
            ZStack {
                Circle()
                    .stroke(Theme.Colors.textPrimary.opacity(0.8), lineWidth: 4)
                    .frame(width: 72, height: 72)

                if isRecording {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Theme.Colors.scoreLow)
                        .frame(width: 28, height: 28)
                } else {
                    Circle()
                        .fill(Theme.Colors.scoreLow)
                        .frame(width: 58, height: 58)
                }
            }
        }
        .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
        .accessibilityAddTraits(.isButton)
    }
}
