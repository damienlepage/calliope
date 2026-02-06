import XCTest
@testable import Calliope

final class ProcessingUtilizationFormatterTests: XCTestCase {
    func testFormatsAverageAsPercent() {
        let result = ProcessingUtilizationFormatter.statusText(status: .ok, average: 0.423)

        XCTAssertEqual(result, "OK (42% avg)")
    }

    func testRoundsToNearestPercent() {
        let result = ProcessingUtilizationFormatter.statusText(status: .high, average: 0.755)

        XCTAssertEqual(result, "High (76% avg)")
    }

    func testClampsNegativeAverageToZero() {
        let result = ProcessingUtilizationFormatter.statusText(status: .ok, average: -0.5)

        XCTAssertEqual(result, "OK (0% avg)")
    }

    func testWarningTextWhenHigh() {
        let result = ProcessingUtilizationFormatter.warningText(status: .high)

        XCTAssertEqual(result, "High processing load. Feedback may lag.")
    }

    func testWarningTextWhenCritical() {
        let result = ProcessingUtilizationFormatter.warningText(status: .critical)

        XCTAssertEqual(result, "Critical processing load. Feedback may lag.")
    }

    func testWarningTextWhenOk() {
        let result = ProcessingUtilizationFormatter.warningText(status: .ok)

        XCTAssertNil(result)
    }
}
