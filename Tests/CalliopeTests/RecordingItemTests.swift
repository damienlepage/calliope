import Foundation
import XCTest
@testable import Calliope

final class RecordingItemTests: XCTestCase {
    func testDisplayNameUsesSegmentLabelForSessionParts() {
        let url = URL(fileURLWithPath: "/tmp/recording_123_ABC_session-1234567890abcdef_part-02.m4a")

        let displayName = RecordingItem.displayName(for: url)

        XCTAssertEqual(displayName, "Session 12345678 Part 02")
    }

    func testDisplayNameFallsBackToFilenameWhenNoSegment() {
        let url = URL(fileURLWithPath: "/tmp/recording_123_ABC.m4a")

        let displayName = RecordingItem.displayName(for: url)

        XCTAssertEqual(displayName, "recording_123_ABC")
    }
}
