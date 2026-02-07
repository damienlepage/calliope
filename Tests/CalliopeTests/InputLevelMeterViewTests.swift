import XCTest
@testable import Calliope

@MainActor
final class InputLevelMeterViewTests: XCTestCase {
    func testInputLevelMeterViewBuilds() {
        let view = InputLevelMeterView(level: 0.42)

        _ = view.body
    }
}
