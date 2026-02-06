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
        let state = SessionViewState(isRecording: false, status: .idle, hasBlockingReasons: false)

        XCTAssertFalse(state.shouldShowTitle)
        XCTAssertTrue(state.shouldShowIdlePrompt)
        XCTAssertFalse(state.shouldShowFeedbackPanel)
        XCTAssertFalse(state.shouldShowStatus)
        XCTAssertFalse(state.shouldShowBlockingReasons)
        XCTAssertEqual(state.primaryButtonTitle, "Start")
        XCTAssertEqual(state.primaryButtonAccessibilityLabel, "Start recording")
        XCTAssertEqual(state.primaryButtonAccessibilityHint, "Begins a new coaching session.")
    }

    func testRecordingStateShowsFeedbackAndStop() {
        let state = SessionViewState(isRecording: true, status: .recording, hasBlockingReasons: false)

        XCTAssertTrue(state.shouldShowTitle)
        XCTAssertFalse(state.shouldShowIdlePrompt)
        XCTAssertTrue(state.shouldShowFeedbackPanel)
        XCTAssertTrue(state.shouldShowStatus)
        XCTAssertFalse(state.shouldShowBlockingReasons)
        XCTAssertEqual(state.primaryButtonTitle, "Stop")
        XCTAssertEqual(state.primaryButtonAccessibilityLabel, "Stop recording")
        XCTAssertEqual(state.primaryButtonAccessibilityHint, "Ends the current coaching session.")
    }

    func testErrorStateShowsStatusWhenIdle() {
        let state = SessionViewState(
            isRecording: false,
            status: .error(.engineStartFailed),
            hasBlockingReasons: false
        )

        XCTAssertTrue(state.shouldShowTitle)
        XCTAssertFalse(state.shouldShowIdlePrompt)
        XCTAssertFalse(state.shouldShowFeedbackPanel)
        XCTAssertTrue(state.shouldShowStatus)
        XCTAssertTrue(state.shouldShowBlockingReasons)
        XCTAssertEqual(state.primaryButtonTitle, "Start")
        XCTAssertEqual(state.primaryButtonAccessibilityLabel, "Start recording")
        XCTAssertEqual(state.primaryButtonAccessibilityHint, "Begins a new coaching session.")
    }

    func testIdleStateShowsBlockingReasonsWhenStartDisabled() {
        let state = SessionViewState(isRecording: false, status: .idle, hasBlockingReasons: true)

        XCTAssertFalse(state.shouldShowTitle)
        XCTAssertFalse(state.shouldShowIdlePrompt)
        XCTAssertFalse(state.shouldShowFeedbackPanel)
        XCTAssertFalse(state.shouldShowStatus)
        XCTAssertTrue(state.shouldShowBlockingReasons)
        XCTAssertEqual(state.primaryButtonTitle, "Start")
        XCTAssertEqual(state.primaryButtonAccessibilityLabel, "Start recording")
        XCTAssertEqual(state.primaryButtonAccessibilityHint, "Begins a new coaching session.")
    }
}
