//
//  RecordingMetadata.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct RecordingMetadata: Codable, Equatable {
    let title: String
    let createdAt: Date?

    static let maxTitleLength = 80
    private static let recordingPrefix = "recording_"
    private static let defaultNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    init(title: String, createdAt: Date? = nil) {
        self.title = title
        self.createdAt = createdAt
    }

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

    static func defaultSessionTitle(for date: Date) -> String {
        "Session \(defaultNameFormatter.string(from: date))"
    }

    static func inferredCreatedAt(from recordingURL: URL) -> Date? {
        let name = recordingURL.deletingPathExtension().lastPathComponent
        guard name.hasPrefix(recordingPrefix) else { return nil }
        let suffix = name.dropFirst(recordingPrefix.count)
        guard let underscoreIndex = suffix.firstIndex(of: "_") else { return nil }
        let timestampString = String(suffix[..<underscoreIndex])
        guard let timestampMs = Double(timestampString) else { return nil }
        let seconds = timestampMs / 1000
        guard seconds > 0 else { return nil }
        return Date(timeIntervalSince1970: seconds)
    }
}
