//
//  SessionViewStateTests.swift
//  CalliopeTests
//
//  Created on [Date]
//

import XCTest
@testable import Calliope

final class SessionViewStateTests: XCTestCase {
    func testIdleStateShowsPromptAndStart() {
        let state = SessionViewState(
            isRecording: false,
            status: .idle,
            hasBlockingReasons: false,
            activeProfileLabel: nil
        )

        XCTAssertFalse(state.shouldShowTitle)
        XCTAssertTrue(state.shouldShowIdlePrompt)
        XCTAssertTrue(state.shouldShowFeedbackPanel)
        XCTAssertFalse(state.shouldShowRecordingDetails)
        XCTAssertFalse(state.shouldShowStatus)
        XCTAssertFalse(state.shouldShowBlockingReasons)
        XCTAssertFalse(state.shouldShowActiveProfileLabel)
        XCTAssertEqual(state.primaryButtonTitle, "Start")
        XCTAssertEqual(state.primaryButtonAccessibilityLabel, "Start recording")
        XCTAssertEqual(state.primaryButtonAccessibilityHint, "Begins a new coaching session.")
    }

    func testRecordingStateShowsFeedbackAndStop() {
        let state = SessionViewState(
            isRecording: true,
            status: .recording,
            hasBlockingReasons: false,
            activeProfileLabel: "Profile: Default"
        )

        XCTAssertTrue(state.shouldShowTitle)
        XCTAssertFalse(state.shouldShowIdlePrompt)
        XCTAssertTrue(state.shouldShowFeedbackPanel)
        XCTAssertTrue(state.shouldShowRecordingDetails)
        XCTAssertFalse(state.shouldShowStatus)
        XCTAssertFalse(state.shouldShowBlockingReasons)
        XCTAssertTrue(state.shouldShowActiveProfileLabel)
        XCTAssertEqual(state.primaryButtonTitle, "Stop")
        XCTAssertEqual(state.primaryButtonAccessibilityLabel, "Stop recording")
        XCTAssertEqual(state.primaryButtonAccessibilityHint, "Ends the current coaching session.")
    }

    func testErrorStateShowsStatusWhenIdle() {
        let state = SessionViewState(
            isRecording: false,
            status: .error(.engineStartFailed),
            hasBlockingReasons: false,
            activeProfileLabel: nil
        )

        XCTAssertTrue(state.shouldShowTitle)
        XCTAssertFalse(state.shouldShowIdlePrompt)
        XCTAssertTrue(state.shouldShowFeedbackPanel)
        XCTAssertFalse(state.shouldShowRecordingDetails)
        XCTAssertFalse(state.shouldShowStatus)
        XCTAssertTrue(state.shouldShowBlockingReasons)
        XCTAssertFalse(state.shouldShowActiveProfileLabel)
        XCTAssertEqual(state.primaryButtonTitle, "Start")
        XCTAssertEqual(state.primaryButtonAccessibilityLabel, "Start recording")
        XCTAssertEqual(state.primaryButtonAccessibilityHint, "Begins a new coaching session.")
    }

    func testIdleStateShowsBlockingReasonsWhenStartDisabled() {
        let state = SessionViewState(
            isRecording: false,
            status: .idle,
            hasBlockingReasons: true,
            activeProfileLabel: "Profile: Default"
        )

        XCTAssertFalse(state.shouldShowTitle)
        XCTAssertFalse(state.shouldShowIdlePrompt)
        XCTAssertTrue(state.shouldShowFeedbackPanel)
        XCTAssertFalse(state.shouldShowRecordingDetails)
        XCTAssertFalse(state.shouldShowStatus)
        XCTAssertTrue(state.shouldShowBlockingReasons)
        XCTAssertFalse(state.shouldShowActiveProfileLabel)
        XCTAssertEqual(state.primaryButtonTitle, "Start")
        XCTAssertEqual(state.primaryButtonAccessibilityLabel, "Start recording")
        XCTAssertEqual(state.primaryButtonAccessibilityHint, "Begins a new coaching session.")
    }
}
