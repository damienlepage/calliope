//
//  PauseRateFormatterTests.swift
//  CalliopeTests
//
//  Created on [Date]
//

import XCTest
@testable import Calliope

final class PauseRateFormatterTests: XCTestCase {
    func testRateTextReturnsNilWhenDurationMissing() {
        XCTAssertNil(PauseRateFormatter.rateText(pauseCount: 2, durationSeconds: nil))
    }

    func testRateTextReturnsNilWhenDurationZero() {
        XCTAssertNil(PauseRateFormatter.rateText(pauseCount: 2, durationSeconds: 0))
    }

    func testRateTextFormatsWholeNumberRates() {
        XCTAssertEqual(
            PauseRateFormatter.rateText(pauseCount: 4, durationSeconds: 120),
            "2/min"
        )
    }

    func testRateTextFormatsDecimalRates() {
        XCTAssertEqual(
            PauseRateFormatter.rateText(pauseCount: 5, durationSeconds: 120),
            "2.5/min"
        )
    }

    func testRateTextHandlesShortDurations() {
        XCTAssertEqual(
            PauseRateFormatter.rateText(pauseCount: 1, durationSeconds: 1),
            "60/min"
        )
    }
}
