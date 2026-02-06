//
//  SessionDurationFormatterTests.swift
//  CalliopeTests
//
//  Created on [Date]
//

import XCTest
@testable import Calliope

final class SessionDurationFormatterTests: XCTestCase {
    func testFormatsSecondsAsMinutesAndSeconds() {
        XCTAssertEqual(SessionDurationFormatter.format(seconds: 0), "00:00")
        XCTAssertEqual(SessionDurationFormatter.format(seconds: 5), "00:05")
        XCTAssertEqual(SessionDurationFormatter.format(seconds: 65), "01:05")
        XCTAssertEqual(SessionDurationFormatter.format(seconds: 600), "10:00")
    }

    func testFormatsHoursWhenDurationExceedsOneHour() {
        XCTAssertEqual(SessionDurationFormatter.format(seconds: 3600), "01:00:00")
        XCTAssertEqual(SessionDurationFormatter.format(seconds: 3661), "01:01:01")
        XCTAssertEqual(SessionDurationFormatter.format(seconds: 7325), "02:02:05")
    }

    func testClampsNegativeSecondsToZero() {
        XCTAssertEqual(SessionDurationFormatter.format(seconds: -3), "00:00")
    }

    func testFormatsShortAndLongSessions() {
        XCTAssertEqual(SessionDurationFormatter.format(seconds: 42), "00:42")
        XCTAssertEqual(SessionDurationFormatter.format(seconds: 5400), "01:30:00")
    }
}
