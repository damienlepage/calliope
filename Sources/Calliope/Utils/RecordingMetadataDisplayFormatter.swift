//
//  RecordingMetadataDisplayFormatter.swift
//  Calliope
//
//  Created on [Date]
//

import Foundation

struct RecordingMetadataDisplayFormatter {
    private static let dateTimeFormat = Date.FormatStyle(
        date: .abbreviated,
        time: .shortened
    )
    private static let conciseDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d 'at' h:mma"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        return formatter
    }()

    static func dateTimeText(for date: Date) -> String {
        date.formatted(dateTimeFormat)
    }

    static func conciseDateText(for date: Date) -> String {
        conciseDateFormatter.string(from: date)
    }

    static func durationMinutesText(for duration: TimeInterval?) -> String? {
        guard let duration, duration > 0 else { return nil }
        let minutes = max(1, Int(ceil(duration / 60)))
        return "\(minutes)min"
    }

    static func displayName(
        for url: URL,
        metadata: RecordingMetadata? = nil,
        modifiedAt: Date? = nil,
        duration: TimeInterval? = nil
    ) -> String {
        let name = url.deletingPathExtension().lastPathComponent
        let normalizedTitle = (metadata?.title).flatMap { RecordingMetadata.normalizedTitle($0) }
        let segmentInfo = segmentInfo(from: name)
        let now = Date()
        let inferredCreatedAt = RecordingMetadata.inferredCreatedAt(from: url)
        let sessionDate = RecordingMetadata.resolvedCreatedAt(
            createdAt: metadata?.createdAt,
            inferred: inferredCreatedAt,
            modifiedAt: modifiedAt,
            now: now
        )
        let baseName: String
        if let normalizedTitle {
            baseName = normalizedTitle
        } else if let sessionDate {
            baseName = conciseDateText(for: sessionDate)
        } else if let segmentLabel = segmentLabel(from: name) {
            baseName = segmentLabel
        } else {
            baseName = name
        }

        guard let segmentInfo else { return baseName }
        if baseName.localizedCaseInsensitiveContains("Part \(segmentInfo.partLabel)") {
            return baseName
        }
        return "\(baseName) - Part \(segmentInfo.partLabel)"
    }

    private struct SegmentInfo {
        let sessionID: String
        let partLabel: String
    }

    private static func segmentInfo(from name: String) -> SegmentInfo? {
        guard let sessionRange = name.range(of: "_session-") else { return nil }
        let sessionPart = name[sessionRange.upperBound...]
        guard let partRange = sessionPart.range(of: "_part-") else { return nil }
        let sessionID = String(sessionPart[..<partRange.lowerBound])
        let partLabel = String(sessionPart[partRange.upperBound...])
        guard !sessionID.isEmpty, !partLabel.isEmpty else { return nil }
        return SegmentInfo(sessionID: sessionID, partLabel: partLabel)
    }

    private static func segmentLabel(from name: String) -> String? {
        guard let segmentInfo = segmentInfo(from: name) else { return nil }
        let shortSessionID = segmentInfo.sessionID.count > 8
            ? String(segmentInfo.sessionID.prefix(8))
            : segmentInfo.sessionID
        return "Session \(shortSessionID) Part \(segmentInfo.partLabel)"
    }
}
