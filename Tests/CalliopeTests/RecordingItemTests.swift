import Foundation
import XCTest
@testable import Calliope

final class RecordingItemTests: XCTestCase {
    func testDisplayNameUsesSegmentLabelForSessionParts() {
        let timestampMs = 1_700_000_000_000.0
        let date = Date(timeIntervalSince1970: timestampMs / 1000)
        let url = URL(
            fileURLWithPath: "/tmp/recording_\(Int(timestampMs))_ABC_session-1234567890abcdef_part-02.m4a"
        )

        let displayName = RecordingItem.displayName(for: url)

        XCTAssertEqual(
            displayName,
            "\(RecordingItem.defaultSessionTitle(for: date)) (Part 02)"
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

        XCTAssertEqual(displayName, RecordingItem.defaultSessionTitle(for: date))
    }

    func testDisplayNameUsesMetadataTitleForSingleSegment() {
        let url = URL(fileURLWithPath: "/tmp/recording_123_ABC.m4a")
        let metadata = RecordingMetadata(title: "Team Sync")

        let displayName = RecordingItem.displayName(for: url, metadata: metadata)

        XCTAssertEqual(displayName, "Team Sync")
    }

    func testDisplayNameUsesMetadataTitleWithPartLabelForSegments() {
        let url = URL(fileURLWithPath: "/tmp/recording_123_ABC_session-1234567890abcdef_part-02.m4a")
        let metadata = RecordingMetadata(title: "Weekly Review")

        let displayName = RecordingItem.displayName(for: url, metadata: metadata)

        XCTAssertEqual(displayName, "Weekly Review (Part 02)")
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
}
