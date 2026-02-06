//
//  RecordingMetadata.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct RecordingMetadata: Codable, Equatable {
    let title: String

    static func normalizedTitle(_ title: String) -> String? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
