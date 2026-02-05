import XCTest
@testable import Calliope

final class OverlayVisibilityTests: XCTestCase {
    func testCompactOverlayVisibilityTracksToggle() {
        XCTAssertFalse(OverlayVisibility.shouldShowCompactOverlay(isEnabled: false))
        XCTAssertTrue(OverlayVisibility.shouldShowCompactOverlay(isEnabled: true))
    }
}
