import XCTest
@testable import Calliope

final class OverlayVisibilityTests: XCTestCase {
    func testCompactOverlayVisibilityTracksToggle() {
        XCTAssertFalse(
            OverlayVisibility.shouldShowCompactOverlay(
                isEnabled: false,
                isRecording: true
            )
        )
        XCTAssertFalse(
            OverlayVisibility.shouldShowCompactOverlay(
                isEnabled: true,
                isRecording: false
            )
        )
        XCTAssertTrue(
            OverlayVisibility.shouldShowCompactOverlay(
                isEnabled: true,
                isRecording: true
            )
        )
    }
}
