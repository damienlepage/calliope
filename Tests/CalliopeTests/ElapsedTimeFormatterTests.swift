import XCTest
@testable import Calliope

final class ElapsedTimeFormatterTests: XCTestCase {
    func testLabelTextReturnsNilForMissingValue() {
        XCTAssertNil(ElapsedTimeFormatter.labelText(nil))
        XCTAssertNil(ElapsedTimeFormatter.labelText(""))
    }

    func testLabelTextFormatsElapsed() {
        XCTAssertEqual(ElapsedTimeFormatter.labelText("00:32"), "Elapsed 00:32")
    }
}
