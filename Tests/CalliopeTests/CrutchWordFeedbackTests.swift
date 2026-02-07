//
//  CrutchWordFeedbackTests.swift
//  CalliopeTests
//
//  Created on [Date]
//

import XCTest
@testable import Calliope

final class CrutchWordFeedbackTests: XCTestCase {
    func testLevelAtOrBelowThresholdIsCalm() {
        XCTAssertEqual(CrutchWordFeedback.level(for: 0), .calm)
        XCTAssertEqual(CrutchWordFeedback.level(for: CrutchWordFeedback.cautionThreshold), .calm)
    }

    func testLevelAboveThresholdIsCaution() {
        XCTAssertEqual(CrutchWordFeedback.level(for: CrutchWordFeedback.cautionThreshold + 1), .caution)
    }

    func testStatusTextMatchesLevel() {
        XCTAssertEqual(CrutchWordFeedback.statusText(for: 0), "On track")
        XCTAssertEqual(
            CrutchWordFeedback.statusText(for: CrutchWordFeedback.cautionThreshold),
            "On track"
        )
        XCTAssertEqual(
            CrutchWordFeedback.statusText(for: CrutchWordFeedback.cautionThreshold + 1),
            "High"
        )
    }
}
