import Foundation
import XCTest
@testable import Calliope

final class RecordingItemTests: XCTestCase {
    private func expectedDisplayName(
        date: Date,
        title: String? = nil,
        partLabel: String? = nil
    ) -> String {
        let dateText = RecordingMetadataDisplayFormatter.conciseDateText(for: date)
        let baseName = title.map { "\(dateText) - \($0)" } ?? dateText
        guard let partLabel else { return baseName }
        return "\(baseName) - Part \(partLabel)"
    }

    func testDisplayNameUsesSegmentLabelForSessionParts() {
        let timestampMs = 1_700_000_000_000.0
        let date = Date(timeIntervalSince1970: timestampMs / 1000)
        let url = URL(
            fileURLWithPath: "/tmp/recording_\(Int(timestampMs))_ABC_session-1234567890abcdef_part-02.m4a"
        )

        let displayName = RecordingItem.displayName(for: url)

        XCTAssertEqual(
            displayName,
            expectedDisplayName(date: date, partLabel: "02")
        )
    }

    func testDisplayNameFallsBackToFilenameWhenNoSegment() {
        let url = URL(fileURLWithPath: "/tmp/audio_capture.m4a")

        let displayName = RecordingItem.displayName(for: url)

        XCTAssertEqual(displayName, "audio_capture")
    }

    func testDisplayNameUsesModifiedAtWhenTimestampMissing() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let url = URL(fileURLWithPath: "/tmp/audio_capture.m4a")

        let displayName = RecordingItem.displayName(for: url, modifiedAt: date)

        XCTAssertEqual(displayName, expectedDisplayName(date: date))
    }

    func testDisplayNameUsesMetadataCreatedAtWhenTimestampMissing() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let url = URL(fileURLWithPath: "/tmp/audio_capture.m4a")
        let metadata = RecordingMetadata(title: "   \n ", createdAt: date)

        let displayName = RecordingItem.displayName(for: url, metadata: metadata)

        XCTAssertEqual(displayName, expectedDisplayName(date: date))
    }

    func testDisplayNamePrefersMetadataCreatedAtOverInferredTimestamp() {
        let inferredTimestampMs = 1_700_000_000_000.0
        let inferredDate = Date(timeIntervalSince1970: inferredTimestampMs / 1000)
        let metadataDate = Date(timeIntervalSince1970: 1_600_000_000)
        let url = URL(
            fileURLWithPath: "/tmp/recording_\(Int(inferredTimestampMs))_ABC.m4a"
        )
        let metadata = RecordingMetadata(title: "  \n ", createdAt: metadataDate)

        let displayName = RecordingItem.displayName(for: url, metadata: metadata)

        XCTAssertEqual(displayName, expectedDisplayName(date: metadataDate))
        XCTAssertNotEqual(displayName, expectedDisplayName(date: inferredDate))
    }

    func testDisplayNameIgnoresUnreasonableMetadataCreatedAt() {
        let inferredTimestampMs = 1_700_000_000_000.0
        let inferredDate = Date(timeIntervalSince1970: inferredTimestampMs / 1000)
        let futureDate = Date().addingTimeInterval(60 * 60 * 48)
        let url = URL(
            fileURLWithPath: "/tmp/recording_\(Int(inferredTimestampMs))_ABC.m4a"
        )
        let metadata = RecordingMetadata(title: "  \n ", createdAt: futureDate)

        let displayName = RecordingItem.displayName(for: url, metadata: metadata)

        XCTAssertEqual(displayName, expectedDisplayName(date: inferredDate))
    }

    func testDisplayNameUsesMetadataTitleForSingleSegment() {
        let url = URL(fileURLWithPath: "/tmp/recording_123_ABC.m4a")
        let metadata = RecordingMetadata(title: "Team Sync")

        let displayName = RecordingItem.displayName(for: url, metadata: metadata)

        XCTAssertEqual(displayName, "Team Sync")
    }

    func testDisplayNameNormalizesMetadataTitle() {
        let url = URL(fileURLWithPath: "/tmp/recording_123_ABC.m4a")
        let metadata = RecordingMetadata(title: "  Weekly \n Review  ")

        let displayName = RecordingItem.displayName(for: url, metadata: metadata)

        XCTAssertEqual(displayName, "Weekly Review")
    }

    func testDisplayNameIncludesDateAndTitleWhenAvailable() {
        let timestampMs = 1_700_000_000_000.0
        let date = Date(timeIntervalSince1970: timestampMs / 1000)
        let url = URL(fileURLWithPath: "/tmp/recording_\(Int(timestampMs))_ABC.m4a")
        let metadata = RecordingMetadata(title: "Team Sync")

        let displayName = RecordingItem.displayName(for: url, metadata: metadata)

        XCTAssertEqual(displayName, expectedDisplayName(date: date, title: "Team Sync"))
    }

    func testDisplayNameUsesMetadataTitleWithPartLabelForSegments() {
        let url = URL(fileURLWithPath: "/tmp/recording_123_ABC_session-1234567890abcdef_part-02.m4a")
        let metadata = RecordingMetadata(title: "Weekly Review")

        let displayName = RecordingItem.displayName(for: url, metadata: metadata)

        XCTAssertEqual(displayName, "Weekly Review - Part 02")
    }

    func testSessionDatePrefersMetadataCreatedAt() {
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let modifiedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let url = URL(fileURLWithPath: "/tmp/recording.m4a")
        let metadata = RecordingMetadata(title: "Weekly Review", createdAt: createdAt)
        let item = RecordingItem(
            url: url,
            modifiedAt: modifiedAt,
            duration: nil,
            fileSizeBytes: nil,
            summary: nil,
            integrityReport: nil,
            metadata: metadata
        )

        XCTAssertEqual(item.sessionDate, createdAt)
    }

    func testSessionDateFallsBackToInferredDate() {
        let timestampMs = 1_700_000_000_000.0
        let inferred = Date(timeIntervalSince1970: timestampMs / 1000)
        let url = URL(fileURLWithPath: "/tmp/recording_\(Int(timestampMs))_ABC.m4a")
        let modifiedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let item = RecordingItem(
            url: url,
            modifiedAt: modifiedAt,
            duration: nil,
            fileSizeBytes: nil,
            summary: nil,
            integrityReport: nil
        )

        XCTAssertEqual(item.sessionDate, inferred)
    }

    func testSessionDateIgnoresUnreasonableMetadataCreatedAt() {
        let timestampMs = 1_700_000_000_000.0
        let inferred = Date(timeIntervalSince1970: timestampMs / 1000)
        let url = URL(fileURLWithPath: "/tmp/recording_\(Int(timestampMs))_ABC.m4a")
        let modifiedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let metadata = RecordingMetadata(
            title: "Weekly Review",
            createdAt: Date().addingTimeInterval(60 * 60 * 48)
        )
        let item = RecordingItem(
            url: url,
            modifiedAt: modifiedAt,
            duration: nil,
            fileSizeBytes: nil,
            summary: nil,
            integrityReport: nil,
            metadata: metadata
        )

        XCTAssertEqual(item.sessionDate, inferred)
    }

    func testSessionDateFallsBackToModifiedAtWhenMetadataAndInferredUnreasonable() {
        let metadataDate = Date(timeIntervalSince1970: 100)
        let modifiedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let url = URL(fileURLWithPath: "/tmp/recording_no_timestamp.m4a")
        let metadata = RecordingMetadata(title: "Weekly Review", createdAt: metadataDate)
        let item = RecordingItem(
            url: url,
            modifiedAt: modifiedAt,
            duration: nil,
            fileSizeBytes: nil,
            summary: nil,
            integrityReport: nil,
            metadata: metadata
        )

        XCTAssertEqual(item.sessionDate, modifiedAt)
    }

    func testCoachingProfileTextUsesMetadataName() {
        let metadata = RecordingMetadata(
            title: "Weekly Review",
            coachingProfileName: "  Focused \n"
        )
        let item = RecordingItem(
            url: URL(fileURLWithPath: "/tmp/recording.m4a"),
            modifiedAt: Date(timeIntervalSince1970: 0),
            duration: nil,
            fileSizeBytes: nil,
            summary: nil,
            integrityReport: nil,
            metadata: metadata
        )

        XCTAssertEqual(item.coachingProfileText, "Profile: Focused")
    }

    func testCoachingProfileTextIsNilWhenMissing() {
        let item = RecordingItem(
            url: URL(fileURLWithPath: "/tmp/recording.m4a"),
            modifiedAt: Date(timeIntervalSince1970: 0),
            duration: nil,
            fileSizeBytes: nil,
            summary: nil,
            integrityReport: nil
        )

        XCTAssertNil(item.coachingProfileText)
    }

    func testIntegrityWarningTextUsesMissingSummaryMessage() {
        let report = RecordingIntegrityReport(
            createdAt: Date(timeIntervalSince1970: 0),
            issues: [.missingSummary]
        )
        let item = RecordingItem(
            url: URL(fileURLWithPath: "/tmp/recording.m4a"),
            modifiedAt: Date(timeIntervalSince1970: 0),
            duration: nil,
            fileSizeBytes: nil,
            summary: nil,
            integrityReport: report
        )

        XCTAssertEqual(
            item.integrityWarningText,
            "Analysis summary is missing. Try recording again to capture full insights."
        )
    }

    func testIntegrityWarningTextIsNilWhenNoReport() {
        let item = RecordingItem(
            url: URL(fileURLWithPath: "/tmp/recording.m4a"),
            modifiedAt: Date(timeIntervalSince1970: 0),
            duration: nil,
            fileSizeBytes: nil,
            summary: nil,
            integrityReport: nil
        )

        XCTAssertNil(item.integrityWarningText)
    }

    func testSpeakingDetailLinesIncludeTimeTurnsAndPercent() {
        let summary = AnalysisSummary(
            version: 1,
            createdAt: Date(timeIntervalSince1970: 1),
            durationSeconds: 300,
            pace: AnalysisSummary.PaceStats(
                averageWPM: 120,
                minWPM: 100,
                maxWPM: 140,
                totalWords: 300
            ),
            pauses: AnalysisSummary.PauseStats(
                count: 2,
                thresholdSeconds: 1.0,
                averageDurationSeconds: 1.2
            ),
            crutchWords: AnalysisSummary.CrutchWordStats(
                totalCount: 1,
                counts: ["um": 1]
            ),
            speaking: AnalysisSummary.SpeakingStats(
                timeSeconds: 90,
                turnCount: 4
            )
        )
        let item = RecordingItem(
            url: URL(fileURLWithPath: "/tmp/recording.m4a"),
            modifiedAt: Date(timeIntervalSince1970: 0),
            duration: 300,
            fileSizeBytes: nil,
            summary: summary,
            integrityReport: nil
        )

        XCTAssertEqual(
            item.speakingDetailLines,
            ["Speaking time: 01:30", "Speaking turns: 4", "Speaking %: 30%"]
        )
    }

    func testMetadataTextConsistentForStandardDuration() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let item = RecordingItem(
            url: URL(fileURLWithPath: "/tmp/recording.m4a"),
            modifiedAt: date,
            duration: 180,
            fileSizeBytes: nil,
            summary: nil,
            integrityReport: nil
        )

        XCTAssertEqual(item.detailText, item.detailMetadataText)
        XCTAssertTrue(item.detailText.contains("• 03:00"))
    }

    func testMetadataTextConsistentForLongDuration() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let item = RecordingItem(
            url: URL(fileURLWithPath: "/tmp/recording.m4a"),
            modifiedAt: date,
            duration: 3661,
            fileSizeBytes: nil,
            summary: nil,
            integrityReport: nil
        )

        XCTAssertEqual(item.detailText, item.detailMetadataText)
        XCTAssertTrue(item.detailText.contains("• 1:01:01"))
    }
}
