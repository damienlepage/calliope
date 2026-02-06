import XCTest
@testable import Calliope

final class ProcessingLatencyTrackerTests: XCTestCase {
    func testReportsHighWhenAverageExceedsThreshold() {
        var tracker = ProcessingLatencyTracker(windowSize: 3, threshold: 0.05)

        XCTAssertEqual(tracker.record(duration: 0.02), .ok)
        XCTAssertEqual(tracker.record(duration: 0.03), .ok)
        XCTAssertEqual(tracker.record(duration: 0.1), .high)
        XCTAssertEqual(tracker.status, .high)
    }

    func testRollingAverageDropsBelowThreshold() {
        var tracker = ProcessingLatencyTracker(windowSize: 3, threshold: 0.05)

        XCTAssertEqual(tracker.record(duration: 0.1), .high)
        XCTAssertEqual(tracker.record(duration: 0.1), .high)
        XCTAssertEqual(tracker.record(duration: 0.1), .high)
        XCTAssertEqual(tracker.status, .high)

        XCTAssertEqual(tracker.record(duration: 0.01), .high)
        XCTAssertEqual(tracker.record(duration: 0.01), .ok)
        XCTAssertEqual(tracker.status, .ok)
    }

    func testResetClearsRollingAverage() {
        var tracker = ProcessingLatencyTracker(windowSize: 2, threshold: 0.05)

        _ = tracker.record(duration: 0.2)
        XCTAssertEqual(tracker.status, .high)

        tracker.reset()
        XCTAssertEqual(tracker.average, 0)
        XCTAssertEqual(tracker.status, .ok)
    }

    func testWindowRollsOverOldestSample() {
        var tracker = ProcessingLatencyTracker(windowSize: 2, threshold: 0.05)

        XCTAssertEqual(tracker.record(duration: 0.1), .high)
        XCTAssertEqual(tracker.record(duration: 0.1), .high)
        XCTAssertEqual(tracker.average, 0.1, accuracy: 0.0001)

        XCTAssertEqual(tracker.record(duration: 0.0), .high)
        XCTAssertEqual(tracker.average, 0.05, accuracy: 0.0001)

        XCTAssertEqual(tracker.record(duration: 0.0), .ok)
        XCTAssertEqual(tracker.average, 0.0, accuracy: 0.0001)
    }
}
