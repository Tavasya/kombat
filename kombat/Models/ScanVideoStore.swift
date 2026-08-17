//
//  ScanVideoStore.swift
//  kombat
//

import Foundation

/// Permanent on-device home for scan videos. Files live in Application
/// Support (which survives restarts, unlike tmp); the database row stores
/// only the file name.
enum ScanVideoStore {
    static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Scans", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Moves a freshly captured/imported video out of tmp into permanent
    /// storage and returns the file name to persist.
    static func store(fileAt tempURL: URL) throws -> String {
        let ext = tempURL.pathExtension.isEmpty ? "mov" : tempURL.pathExtension
        let name = "\(UUID().uuidString).\(ext)"
        try FileManager.default.moveItem(at: tempURL, to: url(for: name))
        return name
    }

    static func url(for name: String) -> URL {
        directory.appendingPathComponent(name)
    }

    static func deleteVideo(named name: String) {
        try? FileManager.default.removeItem(at: url(for: name))
    }
}
