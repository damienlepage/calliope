import XCTest
@testable import Calliope

final class ProcessingLatencyFormatterTests: XCTestCase {
    func testFormatsAverageAsMilliseconds() {
        let result = ProcessingLatencyFormatter.statusText(status: .ok, average: 0.0124)

        XCTAssertEqual(result, "OK (12 ms avg)")
    }

    func testRoundsToNearestMillisecond() {
        let result = ProcessingLatencyFormatter.statusText(status: .high, average: 0.0126)

        XCTAssertEqual(result, "High (13 ms avg)")
    }

    func testClampsNegativeAverageToZero() {
        let result = ProcessingLatencyFormatter.statusText(status: .ok, average: -0.5)

        XCTAssertEqual(result, "OK (0 ms avg)")
    }

    func testWarningTextWhenHigh() {
        let result = ProcessingLatencyFormatter.warningText(status: .high)

        XCTAssertEqual(result, "High processing latency. Feedback may lag.")
    }

    func testWarningTextWhenOk() {
        let result = ProcessingLatencyFormatter.warningText(status: .ok)

        XCTAssertNil(result)
    }
}
