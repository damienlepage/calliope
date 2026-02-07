//
//  FeedbackStatusMessagesTests.swift
//  CalliopeTests
//
//  Created on [Date]
//

import XCTest
@testable import Calliope

final class FeedbackStatusMessagesTests: XCTestCase {
    func testBuildReturnsEmptyWhenNoWarningsOrNotes() {
        let messages = FeedbackStatusMessages.build(
            storageStatus: .ok,
            interruptionMessage: nil,
            showSilenceWarning: false,
            showWaitingForSpeech: false
        )

        XCTAssertTrue(messages.isEmpty)
        XCTAssertEqual(messages.warnings, [])
        XCTAssertEqual(messages.notes, [])
    }

    func testBuildIncludesStorageWarning() {
        let messages = FeedbackStatusMessages.build(
            storageStatus: .warning(remainingSeconds: 120),
            interruptionMessage: nil,
            showSilenceWarning: false,
            showWaitingForSpeech: false
        )

        XCTAssertFalse(messages.isEmpty)
        XCTAssertEqual(messages.warnings.count, 1)
        XCTAssertTrue(messages.warnings[0].contains("Low storage"))
    }

    func testBuildIncludesInterruptionMessage() {
        let messages = FeedbackStatusMessages.build(
            storageStatus: .ok,
            interruptionMessage: "Audio input changed.",
            showSilenceWarning: false,
            showWaitingForSpeech: false
        )

        XCTAssertEqual(messages.warnings, ["Audio input changed."])
    }

    func testBuildIncludesSilenceWarningAndNote() {
        let messages = FeedbackStatusMessages.build(
            storageStatus: .ok,
            interruptionMessage: nil,
            showSilenceWarning: true,
            showWaitingForSpeech: false
        )

        XCTAssertTrue(messages.warnings.contains("No mic input detected"))
        XCTAssertTrue(messages.notes.contains("Check your microphone or input selection in Settings."))
    }

    func testBuildIncludesWaitingForSpeechNote() {
        let messages = FeedbackStatusMessages.build(
            storageStatus: .ok,
            interruptionMessage: nil,
            showSilenceWarning: false,
            showWaitingForSpeech: true
        )

        XCTAssertEqual(messages.notes, ["Waiting for speech"])
    }
}
