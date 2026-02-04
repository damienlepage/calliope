import XCTest
@testable import Calliope

final class RecordingEligibilityTests: XCTestCase {
    func testCanStartRequiresPrivacyAndMicPermission() {
        let privacySatisfied = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true,
            hasConfirmedHeadphones: true
        )
        let privacyMissing = PrivacyGuardrails.State(
            hasAcceptedDisclosure: false,
            hasConfirmedHeadphones: true
        )

        XCTAssertTrue(
            RecordingEligibility.canStart(
                privacyState: privacySatisfied,
                microphonePermission: .authorized
            )
        )
        XCTAssertFalse(
            RecordingEligibility.canStart(
                privacyState: privacySatisfied,
                microphonePermission: .denied
            )
        )
        XCTAssertFalse(
            RecordingEligibility.canStart(
                privacyState: privacyMissing,
                microphonePermission: .authorized
            )
        )
    }

    func testBlockingReasonsIncludeMicAndPrivacyFailuresInOrder() {
        let privacyMissing = PrivacyGuardrails.State(
            hasAcceptedDisclosure: false,
            hasConfirmedHeadphones: false
        )

        let reasons = RecordingEligibility.blockingReasons(
            privacyState: privacyMissing,
            microphonePermission: .denied
        )

        XCTAssertEqual(
            reasons,
            [
                .microphonePermissionMissing,
                .disclosureNotAccepted,
                .headphonesNotConfirmed
            ]
        )
    }

    func testBlockingReasonsEmptyWhenAllRequirementsMet() {
        let privacySatisfied = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true,
            hasConfirmedHeadphones: true
        )

        let reasons = RecordingEligibility.blockingReasons(
            privacyState: privacySatisfied,
            microphonePermission: .authorized
        )

        XCTAssertTrue(reasons.isEmpty)
    }
}
