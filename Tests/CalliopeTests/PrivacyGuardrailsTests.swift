import XCTest
@testable import Calliope

final class PrivacyGuardrailsTests: XCTestCase {
    func testCanStartRecordingRequiresDisclosure() {
        let missingDisclosure = PrivacyGuardrails.State(hasAcceptedDisclosure: false)
        XCTAssertFalse(PrivacyGuardrails.canStartRecording(state: missingDisclosure))

        let satisfied = PrivacyGuardrails.State(hasAcceptedDisclosure: true)
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
