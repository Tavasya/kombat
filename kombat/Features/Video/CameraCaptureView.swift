//
//  CameraCaptureView.swift
//  kombat
//

import AVFoundation
import SwiftUI
import UIKit

/// Wraps the system's own Camera app (`UIImagePickerController`) for video
/// capture, rather than a hand-rolled AVFoundation UI — same lens/zoom
/// controls, flash, and flip-camera your users already know.
struct CameraCaptureView: UIViewControllerRepresentable {
    let onFinish: (URL, Int) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        // Must be set before cameraCaptureMode — UIImagePickerController checks
        // mediaTypes at the moment captureMode is assigned, and throws if
        // "public.movie" isn't in it yet.
        picker.mediaTypes = ["public.movie"]
        picker.cameraCaptureMode = .video
        // The default is 10 seconds, far too short for a training scan.
        picker.videoMaximumDuration = 10 * 60
        picker.videoQuality = .typeHigh
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraCaptureView

        init(_ parent: CameraCaptureView) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            guard let sourceURL = info[.mediaURL] as? URL else {
                parent.dismiss()
                return
            }
            // The picker's temp file is cleaned up once it dismisses; copy it
            // out first so it survives long enough to be moved into storage.
            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent("scan-\(UUID().uuidString)")
                .appendingPathExtension("mov")
            try? FileManager.default.copyItem(at: sourceURL, to: destination)
            let asset = AVURLAsset(url: destination)
            let durationSeconds = max(Int(asset.duration.seconds.rounded()), 1)
            parent.onFinish(destination, durationSeconds)
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
