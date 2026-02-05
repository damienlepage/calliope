import XCTest
@testable import Calliope

final class RecordingEligibilityTests: XCTestCase {
    func testCanStartRequiresPrivacyAndMicPermission() {
        let privacySatisfied = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )
        let privacyMissing = PrivacyGuardrails.State(
            hasAcceptedDisclosure: false
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
            hasAcceptedDisclosure: false
        )

        let reasons = RecordingEligibility.blockingReasons(
            privacyState: privacyMissing,
            microphonePermission: .denied
        )

        XCTAssertEqual(
            reasons,
            [
                .microphonePermissionDenied,
                .disclosureNotAccepted
            ]
        )
    }

    func testBlockingReasonsReturnPermissionSpecificMessages() {
        let privacySatisfied = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )

        XCTAssertEqual(
            RecordingEligibility.blockingReasons(
                privacyState: privacySatisfied,
                microphonePermission: .notDetermined
            ),
            [.microphonePermissionNotDetermined]
        )

        XCTAssertEqual(
            RecordingEligibility.blockingReasons(
                privacyState: privacySatisfied,
                microphonePermission: .denied
            ),
            [.microphonePermissionDenied]
        )

        XCTAssertEqual(
            RecordingEligibility.blockingReasons(
                privacyState: privacySatisfied,
                microphonePermission: .restricted
            ),
            [.microphonePermissionRestricted]
        )
    }

    func testBlockingReasonsIncludeMicrophoneUnavailable() {
        let privacySatisfied = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )

        let reasons = RecordingEligibility.blockingReasons(
            privacyState: privacySatisfied,
            microphonePermission: .authorized,
            hasMicrophoneInput: false
        )

        XCTAssertEqual(reasons, [.microphoneUnavailable])
    }

    func testBlockingReasonsEmptyWhenAllRequirementsMet() {
        let privacySatisfied = PrivacyGuardrails.State(
            hasAcceptedDisclosure: true
        )

        let reasons = RecordingEligibility.blockingReasons(
            privacyState: privacySatisfied,
            microphonePermission: .authorized
        )

        XCTAssertTrue(reasons.isEmpty)
    }
}
