import XCTest
@testable import Calliope

final class InputLevelMeterTests: XCTestCase {
    func testScaledLevelClampsToZeroAndOne() {
        XCTAssertEqual(InputLevelMeter.scaledLevel(for: 0.0), 0.0, accuracy: 0.0001)
        XCTAssertEqual(InputLevelMeter.scaledLevel(for: 0.2), 1.0, accuracy: 0.0001)
    }

    func testScaledLevelAppliesScaleFactor() {
        XCTAssertEqual(InputLevelMeter.scaledLevel(for: 0.1), 0.8, accuracy: 0.0001)
    }

    func testSmoothedLevelBlendsTowardTarget() {
        let level = InputLevelMeter.smoothedLevel(previous: 0.0, target: 1.0)
        XCTAssertEqual(level, 0.3, accuracy: 0.0001)
    }
}
