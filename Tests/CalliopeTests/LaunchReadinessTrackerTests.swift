//
//  LaunchReadinessTrackerTests.swift
//  CalliopeTests
//
//  Created on [Date]
//

import Foundation
import XCTest
@testable import Calliope

final class LaunchReadinessTrackerTests: XCTestCase {
    func testMarksSessionReadyOnlyOnce() {
        let launchAt = Date(timeIntervalSince1970: 1_700_000_000)
        let tracker = LaunchReadinessTracker(now: launchAt)

        let firstReady = Date(timeIntervalSince1970: 1_700_000_001)
        tracker.markSessionReady(now: firstReady)

        let secondReady = Date(timeIntervalSince1970: 1_700_000_010)
        tracker.markSessionReady(now: secondReady)

        XCTAssertEqual(tracker.sessionReadyAt, firstReady)
    }

    func testLatencyIsComputedFromLaunchTimestamp() {
        let launchAt = Date(timeIntervalSince1970: 1_700_000_000)
        let tracker = LaunchReadinessTracker(now: launchAt)

        tracker.markSessionReady(now: Date(timeIntervalSince1970: 1_700_000_002))

        guard let latency = tracker.sessionReadyLatencySeconds else {
            XCTFail("Expected latency to be recorded")
            return
        }
        XCTAssertEqual(latency, 2.0, accuracy: 0.0001)
    }
}
