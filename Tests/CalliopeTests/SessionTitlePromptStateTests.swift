//
//  SessionTitlePromptStateTests.swift
//  CalliopeTests
//
//  Created on [Date]
//

import XCTest
@testable import Calliope

final class SessionTitlePromptStateTests: XCTestCase {
    func testEmptyTitleShowsHelperWarningAndInvalid() {
        let state = SessionTitlePromptState(draft: "")

        XCTAssertFalse(state.isValid)
        XCTAssertEqual(state.helperText, "Enter a title or choose Skip.")
        XCTAssertEqual(state.helperTone, .warning)
        XCTAssertFalse(state.wasTruncated)
    }

    func testWhitespaceTitleShowsHelperWarningAndInvalid() {
        let state = SessionTitlePromptState(draft: "   \n ")

        XCTAssertFalse(state.isValid)
        XCTAssertEqual(state.helperText, "Enter a title or choose Skip.")
        XCTAssertEqual(state.helperTone, .warning)
        XCTAssertFalse(state.wasTruncated)
    }

    func testValidTitleShowsMaxHelper() {
        let state = SessionTitlePromptState(draft: "Team Sync")

        XCTAssertTrue(state.isValid)
        XCTAssertEqual(state.helperText, "Max \(RecordingMetadata.maxTitleLength) characters.")
        XCTAssertEqual(state.helperTone, .standard)
        XCTAssertFalse(state.wasTruncated)
    }

    func testLongTitleShowsTruncationHelper() {
        let longTitle = String(repeating: "A", count: RecordingMetadata.maxTitleLength + 5)
        let state = SessionTitlePromptState(draft: longTitle)

        XCTAssertTrue(state.isValid)
        XCTAssertEqual(
            state.helperText,
            "Titles longer than \(RecordingMetadata.maxTitleLength) characters will be shortened."
        )
        XCTAssertEqual(state.helperTone, .warning)
        XCTAssertTrue(state.wasTruncated)
    }
}
