//
//  RecordingMetadata.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct RecordingMetadata: Codable, Equatable {
    let title: String

    static let maxTitleLength = 80

    struct TitleInfo: Equatable {
        let normalized: String
        let wasTruncated: Bool
    }

    static func normalizedTitleInfo(_ title: String) -> TitleInfo? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let filteredScalars = trimmed.unicodeScalars.filter {
            !CharacterSet.controlCharacters.contains($0)
        }
        guard !filteredScalars.isEmpty else { return nil }
        let filtered = String(String.UnicodeScalarView(filteredScalars))
        let collapsed = filtered.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        let wasTruncated = collapsed.count > maxTitleLength
        let limited = String(collapsed.prefix(maxTitleLength))
        return limited.isEmpty ? nil : TitleInfo(normalized: limited, wasTruncated: wasTruncated)
    }

    static func normalizedTitle(_ title: String) -> String? {
        normalizedTitleInfo(title)?.normalized
    }
}
