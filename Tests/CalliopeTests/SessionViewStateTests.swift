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
        let state = SessionViewState(isRecording: false, status: .idle)

        XCTAssertTrue(state.shouldShowIdlePrompt)
        XCTAssertFalse(state.shouldShowFeedbackPanel)
        XCTAssertFalse(state.shouldShowRecordingIndicators)
        XCTAssertFalse(state.shouldShowStatus)
        XCTAssertEqual(state.primaryButtonTitle, "Start")
    }

    func testRecordingStateShowsFeedbackAndStop() {
        let state = SessionViewState(isRecording: true, status: .recording)

        XCTAssertFalse(state.shouldShowIdlePrompt)
        XCTAssertTrue(state.shouldShowFeedbackPanel)
        XCTAssertTrue(state.shouldShowRecordingIndicators)
        XCTAssertTrue(state.shouldShowStatus)
        XCTAssertEqual(state.primaryButtonTitle, "Stop")
    }
}
