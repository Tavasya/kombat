//
//  ImportedVideo.swift
//  kombat
//

import AVFoundation
import CoreTransferable

/// A video pulled from the user's photo library, copied into our temp directory
/// so it outlives the picker's short-lived security-scoped URL.
struct ImportedVideo: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .movie) { received in
            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent("import-\(UUID().uuidString)")
                .appendingPathExtension(received.file.pathExtension.isEmpty ? "mov" : received.file.pathExtension)
            try FileManager.default.copyItem(at: received.file, to: destination)
            return Self(url: destination)
        }
    }

    func durationSeconds() async -> Int {
        let asset = AVURLAsset(url: url)
        guard let duration = try? await asset.load(.duration) else { return 1 }
        return max(Int(duration.seconds.rounded()), 1)
    }
}
