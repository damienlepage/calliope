import XCTest
@testable import Calliope

final class OverlayVisibilityTests: XCTestCase {
    func testCompactOverlayVisibilityTracksToggle() {
        XCTAssertFalse(
            OverlayVisibility.shouldShowCompactOverlay(
                isEnabled: false,
                isRecording: true,
                isSessionVisible: false
            )
        )
        XCTAssertFalse(
            OverlayVisibility.shouldShowCompactOverlay(
                isEnabled: true,
                isRecording: false,
                isSessionVisible: false
            )
        )
        XCTAssertTrue(
            OverlayVisibility.shouldShowCompactOverlay(
                isEnabled: true,
                isRecording: true,
                isSessionVisible: false
            )
        )
    }

    func testCompactOverlayHiddenDuringSession() {
        XCTAssertFalse(
            OverlayVisibility.shouldShowCompactOverlay(
                isEnabled: true,
                isRecording: true,
                isSessionVisible: true
            )
        )
    }
}
