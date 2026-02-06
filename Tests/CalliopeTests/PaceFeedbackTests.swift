import XCTest
@testable import Calliope

final class PaceFeedbackTests: XCTestCase {
    func testTargetRangeTextUsesMinMaxOrder() {
        let text = PaceFeedback.targetRangeText(minPace: 150, maxPace: 120)

        XCTAssertEqual(text, "120-150 WPM")
    }

    func testTargetRangeTextFormatsWholeNumbers() {
        let text = PaceFeedback.targetRangeText(minPace: 110.4, maxPace: 169.6)

        XCTAssertEqual(text, "110-169 WPM")
    }
}
