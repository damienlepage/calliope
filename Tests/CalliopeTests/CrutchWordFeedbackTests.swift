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
}
