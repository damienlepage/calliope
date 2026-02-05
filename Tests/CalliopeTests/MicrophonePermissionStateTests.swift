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
}
