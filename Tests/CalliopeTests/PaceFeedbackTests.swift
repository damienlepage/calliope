import XCTest
@testable import Calliope

final class PaceFeedbackTests: XCTestCase {
    func testLevelUsesDefaultThresholds() {
        XCTAssertEqual(PaceFeedback.level(for: Constants.targetPaceMin - 1), .slow)
        XCTAssertEqual(PaceFeedback.level(for: Constants.targetPaceMin), .target)
        XCTAssertEqual(PaceFeedback.level(for: Constants.targetPaceMax), .target)
        XCTAssertEqual(PaceFeedback.level(for: Constants.targetPaceMax + 1), .fast)
    }

    func testLevelRespectsCustomThresholds() {
        let minPace = 100.0
        let maxPace = 140.0

        XCTAssertEqual(PaceFeedback.level(for: 99, minPace: minPace, maxPace: maxPace), .slow)
        XCTAssertEqual(PaceFeedback.level(for: 100, minPace: minPace, maxPace: maxPace), .target)
        XCTAssertEqual(PaceFeedback.level(for: 140, minPace: minPace, maxPace: maxPace), .target)
        XCTAssertEqual(PaceFeedback.level(for: 141, minPace: minPace, maxPace: maxPace), .fast)
    }
}
