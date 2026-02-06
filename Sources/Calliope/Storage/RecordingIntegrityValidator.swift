//
//  RecordingIntegrityValidator.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

protocol RecordingIntegrityValidating {
    func validate(recordingURLs: [URL])
}

struct RecordingIntegrityValidator: RecordingIntegrityValidating {
    private let fileManager: FileManager
    private let summaryURLProvider: (URL) -> URL
    private let integrityWriter: RecordingIntegrityWriting
    private let now: () -> Date

    init(
        fileManager: FileManager = .default,
        summaryURLProvider: @escaping (URL) -> URL = { RecordingManager.shared.summaryURL(for: $0) },
        integrityWriter: RecordingIntegrityWriting = RecordingManager.shared,
        now: @escaping () -> Date = Date.init
    ) {
        self.fileManager = fileManager
        self.summaryURLProvider = summaryURLProvider
        self.integrityWriter = integrityWriter
        self.now = now
    }

    func validate(recordingURLs: [URL]) {
        for recordingURL in recordingURLs {
            var issues: [RecordingIntegrityReport.Issue] = []
            if !fileExistsWithData(at: recordingURL) {
                issues.append(.missingAudioFile)
            }
            let summaryURL = summaryURLProvider(recordingURL)
            if !fileExistsWithData(at: summaryURL) {
                issues.append(.missingSummary)
            }
            if issues.isEmpty {
                try? integrityWriter.deleteIntegrityReport(for: recordingURL)
            } else {
                let report = RecordingIntegrityReport(createdAt: now(), issues: issues)
                try? integrityWriter.writeIntegrityReport(report, for: recordingURL)
            }
        }
    }

    private func fileExistsWithData(at url: URL) -> Bool {
        guard fileManager.fileExists(atPath: url.path) else {
            return false
        }
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        let fileSize = values?.fileSize ?? 0
        return fileSize > 0
    }
}
