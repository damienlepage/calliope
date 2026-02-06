import XCTest
@testable import Calliope

final class ProcessingUtilizationTrackerTests: XCTestCase {
    func testReportsCriticalWhenAverageExceedsCriticalThreshold() {
        var tracker = ProcessingUtilizationTracker(windowSize: 1, highThreshold: 0.8, criticalThreshold: 1.0)

        XCTAssertEqual(tracker.record(utilization: 1.2), .critical)
        XCTAssertEqual(tracker.status, .critical)
    }

    func testRollingAverageDropsBelowCriticalThreshold() {
        var tracker = ProcessingUtilizationTracker(windowSize: 2, highThreshold: 0.8, criticalThreshold: 1.0)

        XCTAssertEqual(tracker.record(utilization: 1.2), .critical)
        XCTAssertEqual(tracker.record(utilization: 0.6), .high)
        XCTAssertEqual(tracker.status, .high)
    }

    func testResetClearsRollingAverage() {
        var tracker = ProcessingUtilizationTracker(windowSize: 2, highThreshold: 0.8, criticalThreshold: 1.0)

        _ = tracker.record(utilization: 1.1)
        XCTAssertEqual(tracker.status, .critical)

        tracker.reset()
        XCTAssertEqual(tracker.average, 0)
        XCTAssertEqual(tracker.status, .ok)
    }
}
