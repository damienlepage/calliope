import XCTest
@testable import Calliope

final class PrivacyGuardrailsTests: XCTestCase {
    func testCanStartRecordingRequiresDisclosureAndHeadphones() {
        let missingBoth = PrivacyGuardrails.State(
            hasAcceptedDisclosure: false,
            hasConfirmedHeadphones: false
        )
        XCTAssertFalse(PrivacyGuardrails.canStartRecording(state: missingBoth))

        let missingDisclosure = PrivacyGuardrails.State(
            hasAcceptedDisclosure: false,
            hasConfirmedHeadphones: true
        )
        XCTAssertFalse(PrivacyGuardrails.canStartRecording(state: missingDisclosure))

        let missingHeadphones = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true,
            hasConfirmedHeadphones: false
        )
        XCTAssertFalse(PrivacyGuardrails.canStartRecording(state: missingHeadphones))

        let satisfied = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true,
            hasConfirmedHeadphones: true
        )
        XCTAssertTrue(PrivacyGuardrails.canStartRecording(state: satisfied))
    }

    func testSettingsStatementsHighlightLocalOnlyMicCapture() {
        XCTAssertEqual(
            PrivacyGuardrails.settingsStatements,
            [
                "All audio processing stays on this Mac.",
                "Only your microphone input is analyzed.",
                "System audio and other participants are never recorded."
            ]
        )
    }
}
