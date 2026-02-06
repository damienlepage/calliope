//
//  RecordingMetadata.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct RecordingMetadata: Codable, Equatable {
    let title: String

    private static let maxTitleLength = 80

    static func normalizedTitle(_ title: String) -> String? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let filteredScalars = trimmed.unicodeScalars.filter {
            !CharacterSet.controlCharacters.contains($0)
        }
        guard !filteredScalars.isEmpty else { return nil }
        let filtered = String(String.UnicodeScalarView(filteredScalars))
        let collapsed = filtered.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        let limited = String(collapsed.prefix(maxTitleLength))
        return limited.isEmpty ? nil : limited
    }
}
