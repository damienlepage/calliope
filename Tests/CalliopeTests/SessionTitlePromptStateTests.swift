//
//  SessionTitlePromptStateTests.swift
//  CalliopeTests
//
//  Created on [Date]
//

import XCTest
@testable import Calliope

final class SessionTitlePromptStateTests: XCTestCase {
    func testEmptyTitleShowsDefaultPreviewAndInvalid() {
        let defaultTitle = "Session Jan 1, 2026 at 9:00 AM"
        let state = SessionTitlePromptState(draft: "", defaultTitle: defaultTitle)

        XCTAssertFalse(state.isValid)
        XCTAssertEqual(
            state.helperText,
            "Will save as \"\(defaultTitle)\". Enter a title or choose Skip."
        )
        XCTAssertEqual(state.helperTone, .standard)
        XCTAssertFalse(state.wasTruncated)
    }

    func testWhitespaceTitleShowsDefaultPreviewAndInvalid() {
        let defaultTitle = "Session Jan 1, 2026 at 9:00 AM"
        let state = SessionTitlePromptState(draft: "   \n ", defaultTitle: defaultTitle)

        XCTAssertFalse(state.isValid)
        XCTAssertEqual(
            state.helperText,
            "Will save as \"\(defaultTitle)\". Enter a title or choose Skip."
        )
        XCTAssertEqual(state.helperTone, .standard)
        XCTAssertFalse(state.wasTruncated)
    }

    func testValidTitleShowsMaxHelper() {
        let state = SessionTitlePromptState(draft: "Team Sync")

        XCTAssertTrue(state.isValid)
        XCTAssertEqual(state.helperText, "Will save as \"Team Sync\".")
        XCTAssertEqual(state.helperTone, .standard)
        XCTAssertFalse(state.wasTruncated)
    }

    func testLongTitleShowsTruncationHelper() {
        let longTitle = String(repeating: "A", count: RecordingMetadata.maxTitleLength + 5)
        let state = SessionTitlePromptState(draft: longTitle)
        let truncated = String(repeating: "A", count: RecordingMetadata.maxTitleLength)

        XCTAssertTrue(state.isValid)
        XCTAssertEqual(
            state.helperText,
            "Will save as \"\(truncated)\". Titles longer than \(RecordingMetadata.maxTitleLength) characters will be shortened."
        )
        XCTAssertEqual(state.helperTone, .warning)
        XCTAssertTrue(state.wasTruncated)
    }
}
