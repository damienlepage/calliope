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
}
