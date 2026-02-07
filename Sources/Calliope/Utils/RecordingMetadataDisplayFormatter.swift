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

    static func dateTimeText(for date: Date) -> String {
        date.formatted(dateTimeFormat)
    }

    static func displayName(
        for url: URL,
        metadata: RecordingMetadata? = nil,
        modifiedAt: Date? = nil
    ) -> String {
        let name = url.deletingPathExtension().lastPathComponent
        if let title = metadata?.title,
           let normalizedTitle = RecordingMetadata.normalizedTitle(title) {
            if let segmentInfo = segmentInfo(from: name) {
                return "\(normalizedTitle) (Part \(segmentInfo.partLabel))"
            }
            return normalizedTitle
        }
        let now = Date()
        let inferredCreatedAt = RecordingMetadata.inferredCreatedAt(from: url)
        let sessionDate = RecordingMetadata.resolvedCreatedAt(
            createdAt: metadata?.createdAt,
            inferred: inferredCreatedAt,
            modifiedAt: modifiedAt,
            now: now
        )
        if let sessionDate {
            let sessionTitle = RecordingMetadata.defaultSessionTitle(for: sessionDate)
            if let segmentInfo = segmentInfo(from: name) {
                return "\(sessionTitle) (Part \(segmentInfo.partLabel))"
            }
            return sessionTitle
        }
        if let segmentLabel = segmentLabel(from: name) {
            return segmentLabel
        }
        return name
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
