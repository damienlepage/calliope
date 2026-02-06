import XCTest
@testable import Calliope

final class SpeechPermissionStateTests: XCTestCase {
    func testShouldShowGrantAccessOnlyWhenNotDetermined() {
        XCTAssertTrue(SpeechPermissionState.notDetermined.shouldShowGrantAccess)
        XCTAssertFalse(SpeechPermissionState.denied.shouldShowGrantAccess)
        XCTAssertFalse(SpeechPermissionState.restricted.shouldShowGrantAccess)
        XCTAssertFalse(SpeechPermissionState.authorized.shouldShowGrantAccess)
    }

    func testDescriptionForAuthorized() {
        XCTAssertEqual(
            SpeechPermissionState.authorized.description,
            "Speech recognition access is granted."
        )
    }

    func testDescriptionForNotDetermined() {
        XCTAssertEqual(
            SpeechPermissionState.notDetermined.description,
            "Speech recognition access is required for live coaching."
        )
    }

    func testDescriptionForDenied() {
        XCTAssertEqual(
            SpeechPermissionState.denied.description,
            "Speech recognition access is denied. Enable it in System Settings > Privacy & Security > Speech Recognition."
        )
    }

    func testDescriptionForRestricted() {
        XCTAssertEqual(
            SpeechPermissionState.restricted.description,
            "Speech recognition access is restricted by system policy."
        )
    }
}
