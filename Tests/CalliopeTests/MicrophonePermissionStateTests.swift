import XCTest
@testable import Calliope

final class MicrophonePermissionStateTests: XCTestCase {
    func testShouldShowGrantAccessForNotDetermined() {
        XCTAssertTrue(MicrophonePermissionState.notDetermined.shouldShowGrantAccess)
    }

    func testShouldHideGrantAccessForDenied() {
        XCTAssertFalse(MicrophonePermissionState.denied.shouldShowGrantAccess)
    }

    func testShouldHideGrantAccessForRestricted() {
        XCTAssertFalse(MicrophonePermissionState.restricted.shouldShowGrantAccess)
    }

    func testShouldHideGrantAccessForAuthorized() {
        XCTAssertFalse(MicrophonePermissionState.authorized.shouldShowGrantAccess)
    }

    func testDescriptionForAuthorized() {
        XCTAssertEqual(MicrophonePermissionState.authorized.description, "Microphone access is granted.")
    }

    func testDescriptionForNotDetermined() {
        XCTAssertEqual(
            MicrophonePermissionState.notDetermined.description,
            "Microphone access is required for live coaching."
        )
    }

    func testDescriptionForDenied() {
        XCTAssertEqual(
            MicrophonePermissionState.denied.description,
            "Microphone access is denied. Enable it in System Settings > Privacy & Security > Microphone."
        )
    }

    func testDescriptionForRestricted() {
        XCTAssertEqual(
            MicrophonePermissionState.restricted.description,
            "Microphone access is restricted by system policy."
        )
    }
}
