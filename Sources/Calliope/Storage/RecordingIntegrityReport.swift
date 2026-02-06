//
//  RecordingIntegrityReport.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct RecordingIntegrityReport: Codable, Equatable {
    enum Issue: String, Codable, Equatable, CaseIterable {
        case missingAudioFile
        case missingSummary
    }

    let createdAt: Date
    let issues: [Issue]

    static func reportURL(for recordingURL: URL) -> URL {
        recordingURL
            .deletingPathExtension()
            .appendingPathExtension("integrity.json")
    }
}
