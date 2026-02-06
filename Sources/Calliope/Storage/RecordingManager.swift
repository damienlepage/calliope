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
    
    func getNewRecordingURL(sessionID: String? = nil, segmentIndex: Int? = nil) -> URL {
        ensureDirectoryExists()
        let timestamp = Int64(now().timeIntervalSince1970 * 1000)
        let identifier = uuid().uuidString
        var filename = "recording_\(timestamp)_\(identifier)"
        if let sessionID, let segmentIndex {
            let partLabel = String(format: "%02d", segmentIndex)
            filename += "_session-\(sessionID)_part-\(partLabel)"
        }
        filename += ".m4a"
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
        try? deleteIntegrityReport(for: url)
        try? deleteMetadata(for: url)
    }

    func deleteAllRecordings() throws {
        ensureDirectoryExists()
        let urls = (try? fileManager.contentsOfDirectory(
            at: recordingsDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )) ?? []
        var firstError: Error?
        for url in urls {
            let path = url.path.lowercased()
            if path.hasSuffix(".m4a") || path.hasSuffix(".wav") {
                do {
                    try deleteRecording(at: url)
                } catch {
                    firstError = firstError ?? error
                }
                continue
            }
            if path.hasSuffix(".summary.json")
                || path.hasSuffix(".integrity.json")
                || path.hasSuffix(".metadata.json") {
                guard fileManager.fileExists(atPath: url.path) else {
                    continue
                }
                do {
                    try fileManager.removeItem(at: url)
                } catch {
                    firstError = firstError ?? error
                }
            }
        }
        if let firstError {
            throw firstError
        }
    }

    @discardableResult
    func deleteRecordings(olderThan cutoff: Date) -> Int {
        ensureDirectoryExists()
        let keys: [URLResourceKey] = [
            .isRegularFileKey,
            .contentModificationDateKey
        ]
        let urls = (try? fileManager.contentsOfDirectory(
            at: recordingsDirectory,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        )) ?? []
        var deletedCount = 0
        for url in urls {
            let values = try? url.resourceValues(forKeys: Set(keys))
            guard values?.isRegularFile == true else { continue }
            let ext = url.pathExtension.lowercased()
            guard ext == "m4a" || ext == "wav" else { continue }
            let modified = values?.contentModificationDate ?? .distantPast
            guard modified < cutoff else { continue }
            do {
                try deleteRecording(at: url)
                deletedCount += 1
            } catch {
                continue
            }
        }
        return deletedCount
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

extension RecordingManager: RecordingIntegrityWriting {
    func integrityReportURL(for recordingURL: URL) -> URL {
        RecordingIntegrityReport.reportURL(for: recordingURL)
    }

    func writeIntegrityReport(_ report: RecordingIntegrityReport, for recordingURL: URL) throws {
        let url = integrityReportURL(for: recordingURL)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(report)
        try data.write(to: url, options: [.atomic])
    }

    func deleteIntegrityReport(for recordingURL: URL) throws {
        let url = integrityReportURL(for: recordingURL)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    func readIntegrityReport(for recordingURL: URL) -> RecordingIntegrityReport? {
        let url = integrityReportURL(for: recordingURL)
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(RecordingIntegrityReport.self, from: data)
    }
}

extension RecordingManager {
    private func metadataEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private func metadataDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    func metadataURL(for recordingURL: URL) -> URL {
        recordingURL
            .deletingPathExtension()
            .appendingPathExtension("metadata.json")
    }

    func writeMetadata(_ metadata: RecordingMetadata, for recordingURL: URL) throws {
        let url = metadataURL(for: recordingURL)
        let data = try metadataEncoder().encode(metadata)
        try data.write(to: url, options: [.atomic])
    }

    func writeDefaultMetadataIfNeeded(for recordingURLs: [URL], createdAt: Date) {
        let defaultTitle = RecordingMetadata.defaultSessionTitle(for: createdAt)
        guard let normalizedTitle = RecordingMetadata.normalizedTitle(defaultTitle) else {
            return
        }
        let metadata = RecordingMetadata(title: normalizedTitle, createdAt: createdAt)
        for recordingURL in recordingURLs {
            if let existing = readMetadata(for: recordingURL), existing.createdAt != nil {
                continue
            }
            try? writeMetadata(metadata, for: recordingURL)
        }
    }

    func deleteMetadata(for recordingURL: URL) throws {
        let url = metadataURL(for: recordingURL)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    func readMetadata(for recordingURL: URL) -> RecordingMetadata? {
        let url = metadataURL(for: recordingURL)
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        do {
            let metadata = try metadataDecoder().decode(RecordingMetadata.self, from: data)
            guard let normalizedTitle = RecordingMetadata.normalizedTitle(metadata.title) else {
                try? fileManager.removeItem(at: url)
                return nil
            }
            let normalizedCreatedAt = RecordingMetadata.normalizedCreatedAt(
                metadata.createdAt,
                inferred: RecordingMetadata.inferredCreatedAt(from: recordingURL),
                now: now()
            )
            let normalizedMetadata = RecordingMetadata(
                title: normalizedTitle,
                createdAt: normalizedCreatedAt
            )
            if normalizedMetadata == metadata {
                return metadata
            }
            try? writeMetadata(normalizedMetadata, for: recordingURL)
            return normalizedMetadata
        } catch {
            try? fileManager.removeItem(at: url)
            return nil
        }
    }

    func backfillMetadataIfNeeded(for recordings: [URL]) {
        let currentTime = now()
        for recordingURL in recordings {
            let existingMetadata = readMetadata(for: recordingURL)
            let normalizedCreatedAt = RecordingMetadata.normalizedCreatedAt(
                existingMetadata?.createdAt,
                inferred: RecordingMetadata.inferredCreatedAt(from: recordingURL),
                now: currentTime
            )
            if existingMetadata?.createdAt != nil,
               normalizedCreatedAt == existingMetadata?.createdAt {
                continue
            }
            guard let normalizedCreatedAt else {
                continue
            }
            let title: String
            if let existingMetadata {
                title = existingMetadata.title
            } else {
                title = RecordingMetadata.defaultSessionTitle(for: normalizedCreatedAt)
            }
            guard let normalizedTitle = RecordingMetadata.normalizedTitle(title) else {
                continue
            }
            let backfilled = RecordingMetadata(title: normalizedTitle, createdAt: normalizedCreatedAt)
            try? writeMetadata(backfilled, for: recordingURL)
        }
    }

    func cleanupOrphanedMetadata(for recordings: [URL]) {
        ensureDirectoryExists()
        var recordingByBaseName: [String: URL] = [:]
        for recordingURL in recordings {
            let baseName = recordingURL.deletingPathExtension().lastPathComponent
            if recordingByBaseName[baseName] == nil {
                recordingByBaseName[baseName] = recordingURL
            }
        }
        let urls = (try? fileManager.contentsOfDirectory(
            at: recordingsDirectory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )) ?? []
        for url in urls {
            guard url.path.lowercased().hasSuffix(".metadata.json") else {
                continue
            }
            let baseName = url
                .deletingPathExtension()
                .deletingPathExtension()
                .lastPathComponent
            guard let recordingURL = recordingByBaseName[baseName] else {
                try? fileManager.removeItem(at: url)
                continue
            }
            _ = readMetadata(for: recordingURL)
        }
    }
}
