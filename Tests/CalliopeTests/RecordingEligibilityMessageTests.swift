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

    func testVoiceIsolationRiskMessageMentionsOtherParticipants() {
        let message = RecordingEligibility.Reason.voiceIsolationRiskUnacknowledged.message
        XCTAssertTrue(message.lowercased().contains("other participants"))
    }
}
