import XCTest
@testable import Calliope

final class PauseRateFormatterTests: XCTestCase {
    func testRateTextReturnsNilWhenDurationMissingOrZero() {
        XCTAssertNil(PauseRateFormatter.rateText(pauseCount: 2, durationSeconds: nil))
        XCTAssertNil(PauseRateFormatter.rateText(pauseCount: 2, durationSeconds: 0))
    }

    func testRateTextFormatsZeroPauses() {
        XCTAssertEqual(PauseRateFormatter.rateText(pauseCount: 0, durationSeconds: 120), "0/min")
    }
}
