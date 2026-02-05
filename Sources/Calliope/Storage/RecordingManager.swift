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
        let keys: [URLResourceKey] = [
            .isRegularFileKey,
            .contentModificationDateKey,
            .fileSizeKey
        ]
        guard let files = try? fileManager.contentsOfDirectory(
            at: recordingsDirectory,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        let filtered = files.compactMap { url -> (URL, Date)? in
            let values = try? url.resourceValues(forKeys: Set(keys))
            guard values?.isRegularFile == true else {
                return nil
            }
            let ext = url.pathExtension.lowercased()
            guard ext == "m4a" || ext == "wav" else {
                return nil
            }
            guard let fileSize = values?.fileSize, fileSize > 0 else {
                return nil
            }
            let modified = values?.contentModificationDate ?? .distantPast
            return (url, modified)
        }
        return filtered
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }
    
    func deleteRecording(at url: URL) throws {
        try fileManager.removeItem(at: url)
        try? deleteSummary(for: url)
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

extension RecordingManager: AnalysisSummaryWriting {
    func summaryURL(for recordingURL: URL) -> URL {
        recordingURL
            .deletingPathExtension()
            .appendingPathExtension("summary.json")
    }

    func writeSummary(_ summary: AnalysisSummary, for recordingURL: URL) throws {
        let url = summaryURL(for: recordingURL)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(summary)
        try data.write(to: url, options: [.atomic])
    }

    func deleteSummary(for recordingURL: URL) throws {
        let url = summaryURL(for: recordingURL)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }
}
