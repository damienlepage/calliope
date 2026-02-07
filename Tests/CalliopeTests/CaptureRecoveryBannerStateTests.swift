//
//  CaptureRecoveryBannerStateTests.swift
//  CalliopeTests
//
//  Created on [Date]
//

import XCTest
@testable import Calliope

final class CaptureRecoveryBannerStateTests: XCTestCase {
    func testErrorStatusProducesRecoveryBannerWithRetryPrimaryAction() {
        let banner = CaptureRecoveryBannerState.from(status: .error(.engineStartFailed))

        XCTAssertEqual(banner?.title, "Capture needs attention")
        XCTAssertEqual(banner?.message, AudioCaptureError.engineStartFailed.message)
        XCTAssertEqual(banner?.primaryActionTitle, "Retry Capture")
        XCTAssertEqual(banner?.secondaryActionTitle, "Open Settings")
    }

    func testVoiceIsolationRiskDoesNotShowCaptureBanner() {
        let banner = CaptureRecoveryBannerState.from(status: .error(.voiceIsolationRiskNotAcknowledged))

        XCTAssertNil(banner)
    }

    func testRecordingStatusClearsCaptureBanner() {
        let banner = CaptureRecoveryBannerState.from(status: .recording)

        XCTAssertNil(banner)
    }
}
