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
        XCTAssertFalse(state.shouldShowRecordingIndicators)
        XCTAssertFalse(state.shouldShowStatus)
        XCTAssertFalse(state.shouldShowDeviceSelectionMessage)
        XCTAssertFalse(state.shouldShowBlockingReasons)
        XCTAssertEqual(state.primaryButtonTitle, "Start")
    }

    func testRecordingStateShowsFeedbackAndStop() {
        let state = SessionViewState(isRecording: true, status: .recording, hasBlockingReasons: false)

        XCTAssertTrue(state.shouldShowTitle)
        XCTAssertFalse(state.shouldShowIdlePrompt)
        XCTAssertTrue(state.shouldShowFeedbackPanel)
        XCTAssertTrue(state.shouldShowRecordingIndicators)
        XCTAssertTrue(state.shouldShowStatus)
        XCTAssertTrue(state.shouldShowDeviceSelectionMessage)
        XCTAssertFalse(state.shouldShowBlockingReasons)
        XCTAssertEqual(state.primaryButtonTitle, "Stop")
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
        XCTAssertFalse(state.shouldShowRecordingIndicators)
        XCTAssertTrue(state.shouldShowStatus)
        XCTAssertTrue(state.shouldShowDeviceSelectionMessage)
        XCTAssertTrue(state.shouldShowBlockingReasons)
        XCTAssertEqual(state.primaryButtonTitle, "Start")
    }

    func testIdleStateShowsBlockingReasonsWhenStartDisabled() {
        let state = SessionViewState(isRecording: false, status: .idle, hasBlockingReasons: true)

        XCTAssertFalse(state.shouldShowTitle)
        XCTAssertFalse(state.shouldShowIdlePrompt)
        XCTAssertFalse(state.shouldShowFeedbackPanel)
        XCTAssertFalse(state.shouldShowRecordingIndicators)
        XCTAssertFalse(state.shouldShowStatus)
        XCTAssertFalse(state.shouldShowDeviceSelectionMessage)
        XCTAssertTrue(state.shouldShowBlockingReasons)
        XCTAssertEqual(state.primaryButtonTitle, "Start")
    }
}
