import XCTest
@testable import Calliope

final class MicTestEligibilityTests: XCTestCase {
    func testCanRunRequiresAuthorizedPermissionAndMicrophone() {
        XCTAssertTrue(
            MicTestEligibility.canRun(
                microphonePermission: .authorized,
                hasMicrophoneInput: true
            )
        )

        XCTAssertFalse(
            MicTestEligibility.canRun(
                microphonePermission: .denied,
                hasMicrophoneInput: true
            )
        )

        XCTAssertFalse(
            MicTestEligibility.canRun(
                microphonePermission: .authorized,
                hasMicrophoneInput: false
            )
        )
    }

    func testBlockingReasonsIncludePermissionAndMicrophoneFailures() {
        let reasons = MicTestEligibility.blockingReasons(
            microphonePermission: .notDetermined,
            hasMicrophoneInput: false
        )

        XCTAssertEqual(
            reasons,
            [
                .microphonePermissionNotDetermined,
                .microphoneUnavailable
            ]
        )
    }

    func testBlockingReasonsReturnPermissionSpecificReasons() {
        XCTAssertEqual(
            MicTestEligibility.blockingReasons(
                microphonePermission: .notDetermined,
                hasMicrophoneInput: true
            ),
            [.microphonePermissionNotDetermined]
        )

        XCTAssertEqual(
            MicTestEligibility.blockingReasons(
                microphonePermission: .denied,
                hasMicrophoneInput: true
            ),
            [.microphonePermissionDenied]
        )

        XCTAssertEqual(
            MicTestEligibility.blockingReasons(
                microphonePermission: .restricted,
                hasMicrophoneInput: true
            ),
            [.microphonePermissionRestricted]
        )
    }
}
