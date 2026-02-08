//
//  SessionViewStateTests.swift
//  CalliopeTests
//
//  Created on [Date]
//

import XCTest
@testable import Calliope

final class SessionViewStateTests: XCTestCase {
    func testIdleStateShowsFeedbackAndStart() {
        let state = SessionViewState(
            isRecording: false,
            hasPausedSession: false
        )

        XCTAssertEqual(state.primaryButtonTitle, "Start")
        XCTAssertEqual(state.primaryButtonAccessibilityLabel, "Start recording")
        XCTAssertEqual(state.primaryButtonAccessibilityHint, "Begins a new coaching session.")
    }

    func testRecordingStateShowsFeedbackAndStop() {
        let state = SessionViewState(
            isRecording: true,
            hasPausedSession: false
        )

        XCTAssertEqual(state.primaryButtonTitle, "Stop")
        XCTAssertEqual(state.primaryButtonAccessibilityLabel, "Stop recording")
        XCTAssertEqual(state.primaryButtonAccessibilityHint, "Ends the current coaching session.")
    }

    func testPausedStateShowsResume() {
        let state = SessionViewState(
            isRecording: false,
            hasPausedSession: true
        )

        XCTAssertEqual(state.primaryButtonTitle, "Resume")
        XCTAssertEqual(state.primaryButtonAccessibilityLabel, "Resume recording")
        XCTAssertEqual(state.primaryButtonAccessibilityHint, "Continues the current coaching session.")
    }
}
