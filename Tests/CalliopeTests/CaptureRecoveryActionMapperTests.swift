//
//  CaptureRecoveryActionMapperTests.swift
//  CalliopeTests
//
//  Created on [Date]
//

import XCTest
@testable import Calliope

final class CaptureRecoveryActionMapperTests: XCTestCase {
    func testMapsPermissionDeniedToOpenSettingsAction() {
        let action = CaptureRecoveryActionMapper.recoveryAction(for: .microphonePermissionDenied)

        XCTAssertEqual(action.kind, .openSettings)
        XCTAssertEqual(action.actionTitle, "Open Settings")
        XCTAssertEqual(action.hint, "Enable microphone access in Settings to resume.")
    }

    func testMapsEngineStartFailedToRetryAction() {
        let action = CaptureRecoveryActionMapper.recoveryAction(for: .engineStartFailed)

        XCTAssertEqual(action.kind, .retryStart)
        XCTAssertEqual(action.actionTitle, "Retry Start")
        XCTAssertEqual(action.hint, "Retry capture. If it persists, check your input device.")
    }

    func testMapsVoiceIsolationAcknowledgementToUnderstandAction() {
        let action = CaptureRecoveryActionMapper.recoveryAction(for: .voiceIsolationRiskNotAcknowledged)

        XCTAssertEqual(action.kind, .acknowledgeVoiceIsolationRisk)
        XCTAssertEqual(action.actionTitle, "I Understand")
        XCTAssertEqual(action.hint, "Acknowledge the voice isolation warning to continue.")
    }
}
