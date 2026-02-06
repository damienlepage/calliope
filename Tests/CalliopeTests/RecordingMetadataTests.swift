import XCTest
@testable import Calliope

final class RecordingMetadataTests: XCTestCase {
    func testNormalizedTitleTrimsWhitespace() {
        let title = RecordingMetadata.normalizedTitle("  Team Sync  \n")

        XCTAssertEqual(title, "Team Sync")
    }

    func testNormalizedTitleReturnsNilForEmptyOrWhitespace() {
        XCTAssertNil(RecordingMetadata.normalizedTitle(""))
        XCTAssertNil(RecordingMetadata.normalizedTitle("  \n\t "))
    }
}
