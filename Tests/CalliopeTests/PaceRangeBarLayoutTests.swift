//
//  PaceRangeBarLayoutTests.swift
//  CalliopeTests
//
//  Created on [Date]
//

import XCTest
@testable import Calliope

final class PaceRangeBarLayoutTests: XCTestCase {
    func testLayoutPositionsWithinBoundsWhenPaceInRange() {
        let layout = PaceRangeBarLayout.compute(
            pace: 150,
            minPace: 120,
            maxPace: 180,
            padding: 40
        )

        XCTAssertGreaterThanOrEqual(layout.targetStart, 0)
        XCTAssertLessThanOrEqual(layout.targetStart, 1)
        XCTAssertGreaterThan(layout.targetWidth, 0)
        XCTAssertLessThan(layout.targetWidth, 1)
        XCTAssertGreaterThanOrEqual(layout.pacePosition, layout.targetStart)
        XCTAssertLessThanOrEqual(layout.pacePosition, layout.targetStart + layout.targetWidth)
    }

    func testLayoutClampsPaceBelowMinimum() {
        let layout = PaceRangeBarLayout.compute(
            pace: 0,
            minPace: 120,
            maxPace: 180,
            padding: 40
        )

        XCTAssertEqual(layout.pacePosition, 0, accuracy: 0.0001)
    }

    func testLayoutClampsPaceAboveMaximum() {
        let layout = PaceRangeBarLayout.compute(
            pace: 400,
            minPace: 120,
            maxPace: 180,
            padding: 40
        )

        XCTAssertEqual(layout.pacePosition, 1, accuracy: 0.0001)
    }

    func testLayoutPacePositionUpdatesWithChangingPace() {
        let slowLayout = PaceRangeBarLayout.compute(
            pace: 110,
            minPace: 120,
            maxPace: 180,
            padding: 40
        )
        let fastLayout = PaceRangeBarLayout.compute(
            pace: 190,
            minPace: 120,
            maxPace: 180,
            padding: 40
        )

        XCTAssertLessThan(slowLayout.pacePosition, fastLayout.pacePosition)
        XCTAssertNotEqual(slowLayout.pacePosition, fastLayout.pacePosition)
    }
}
