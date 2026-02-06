import XCTest
@testable import Calliope

final class RecordingEligibilityMessageTests: XCTestCase {
    func testBlockingReasonMessagesPointToSettings() {
        let reasons: [RecordingEligibility.Reason] = [
            .microphonePermissionNotDetermined,
            .microphonePermissionDenied,
            .microphonePermissionRestricted,
            .microphoneUnavailable,
            .disclosureNotAccepted
        ]

        for reason in reasons {
            XCTAssertTrue(
                reason.message.contains("Settings"),
                "Expected reason \(reason) to direct users to Settings."
            )
        }
    }
}
