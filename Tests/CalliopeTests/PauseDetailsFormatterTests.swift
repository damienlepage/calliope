import XCTest
@testable import Calliope

final class PauseDetailsFormatterTests: XCTestCase {
    func testDetailsTextIncludesAverageDuration() {
        let text = PauseDetailsFormatter.detailsText(pauseCount: 2, averageDuration: 1.25, rateText: nil)
        XCTAssertEqual(text, "Avg 1.2s")
    }

    func testDetailsTextIncludesRateWhenProvided() {
        let text = PauseDetailsFormatter.detailsText(pauseCount: 3, averageDuration: 0.9, rateText: "2/min")
        XCTAssertEqual(text, "Avg 0.9s • 2/min")
    }

    func testDetailsTextShowsPlaceholderWhenNoPauses() {
        let text = PauseDetailsFormatter.detailsText(pauseCount: 0, averageDuration: 0, rateText: "0/min")
        XCTAssertEqual(text, "Avg -- • 0/min")
    }
}
