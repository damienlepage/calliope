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

    func testNormalizedTitleCollapsesWhitespaceAndStripsControlCharacters() {
        let title = RecordingMetadata.normalizedTitle("  Team \u{0000} Sync \n\t Plan ")

        XCTAssertEqual(title, "Team Sync Plan")
    }

    func testNormalizedTitleCapsLength() {
        let longTitle = String(repeating: "A", count: 120)

        let title = RecordingMetadata.normalizedTitle(longTitle)

        XCTAssertEqual(title?.count, 80)
    }
}
