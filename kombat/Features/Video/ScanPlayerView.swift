//
//  ScanPlayerView.swift
//  kombat
//

import AVKit
import SwiftUI

/// Plays back a scan's video. The pose skeleton overlay will layer on top of this.
struct ScanPlayerView: View {
    let session: ScanSession

    @Environment(\.dismiss) private var dismiss
    @State private var player = AVPlayer()

    var body: some View {
        NavigationStack {
            VideoPlayer(player: player)
                .ignoresSafeArea(edges: .bottom)
                .background(.black)
                .navigationTitle(session.category.rawValue)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
        }
        .onAppear {
            guard let url = session.videoURL else { return }
            player.replaceCurrentItem(with: AVPlayerItem(url: url))
            player.play()
        }
        .onDisappear {
            player.pause()
        }
    }
}
