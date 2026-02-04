//
//  RecordingManager.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

class RecordingManager {
    static let shared = RecordingManager()
    
    private let recordingsDirectory: URL
    private let fileManager: FileManager
    private let now: () -> Date
    private let uuid: () -> UUID
    
    init(
        baseDirectory: URL? = nil,
        fileManager: FileManager = .default,
        now: @escaping () -> Date = Date.init,
        uuid: @escaping () -> UUID = UUID.init
    ) {
        self.fileManager = fileManager
        self.now = now
        self.uuid = uuid

        let documentsPath = baseDirectory ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordingsDirectory = documentsPath.appendingPathComponent("CalliopeRecordings", isDirectory: true)
        
        ensureDirectoryExists()
    }
    
    func getNewRecordingURL() -> URL {
        ensureDirectoryExists()
        let timestamp = Int64(now().timeIntervalSince1970 * 1000)
        let filename = "recording_\(timestamp)_\(uuid().uuidString).m4a"
        return recordingsDirectory.appendingPathComponent(filename)
    }
    
    func getAllRecordings() -> [URL] {
        ensureDirectoryExists()
        guard let files = try? fileManager.contentsOfDirectory(at: recordingsDirectory, includingPropertiesForKeys: nil) else {
            return []
        }
        return files.filter { $0.pathExtension == "m4a" || $0.pathExtension == "wav" }
    }
    
    func deleteRecording(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }

    func recordingsDirectoryURL() -> URL {
        ensureDirectoryExists()
        return recordingsDirectory
    }

    private func ensureDirectoryExists() {
        if !fileManager.fileExists(atPath: recordingsDirectory.path) {
            try? fileManager.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true)
        }
    }
}
