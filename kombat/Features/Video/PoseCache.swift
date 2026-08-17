//
//  PoseCache.swift
//  kombat
//

import Foundation

/// Disk cache for analyzed pose timelines, keyed by video file name.
/// Lives in Caches (not backed up, OS-purgeable) because poses are fully
/// regenerable from the video — losing one costs a re-analysis, never data.
enum PoseCache {
    private static var directory: URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Poses", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static func url(for videoFileName: String) -> URL {
        directory.appendingPathComponent(videoFileName).appendingPathExtension("poses.json")
    }

    static func load(for videoFileName: String) -> [PoseFrame]? {
        guard let data = try? Data(contentsOf: url(for: videoFileName)) else { return nil }
        return try? JSONDecoder().decode([PoseFrame].self, from: data)
    }

    static func save(_ frames: [PoseFrame], for videoFileName: String) {
        guard let data = try? JSONEncoder().encode(frames) else { return }
        try? data.write(to: url(for: videoFileName))
    }

    static func delete(for videoFileName: String) {
        try? FileManager.default.removeItem(at: url(for: videoFileName))
    }
}
