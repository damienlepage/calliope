//
//  CallReadinessTipsTests.swift
//  CalliopeTests
//
//  Created on [Date]
//

import XCTest
@testable import Calliope

final class CallReadinessTipsTests: XCTestCase {
    func testTipsCoverCoreGuidance() {
        let tips = CallReadinessTips.items

        XCTAssertTrue((3...5).contains(tips.count))
        XCTAssertTrue(tips.contains { $0.localizedCaseInsensitiveContains("headset") })
        XCTAssertTrue(tips.contains { $0.localizedCaseInsensitiveContains("quiet") })
        XCTAssertTrue(
            tips.contains {
                $0.localizedCaseInsensitiveContains("selected input")
                    || $0.localizedCaseInsensitiveContains("input matches")
            }
        )
    }
}
