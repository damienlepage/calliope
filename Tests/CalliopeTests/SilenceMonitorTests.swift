import XCTest
@testable import Calliope

final class SilenceMonitorTests: XCTestCase {
    func testSilenceWarningAfterTimeout() {
        var now = Date(timeIntervalSince1970: 0)
        let monitor = SilenceMonitor(timeout: 5.0, threshold: 0.05, now: { now })

        monitor.reset()
        now = now.addingTimeInterval(4.9)
        XCTAssertFalse(monitor.isSilenceWarningActive())

        now = now.addingTimeInterval(0.2)
        XCTAssertTrue(monitor.isSilenceWarningActive())
    }

    func testRegisterLevelResetsTimer() {
        var now = Date(timeIntervalSince1970: 0)
        let monitor = SilenceMonitor(timeout: 5.0, threshold: 0.05, now: { now })

        now = now.addingTimeInterval(6.0)
        XCTAssertTrue(monitor.isSilenceWarningActive())

        monitor.registerLevel(0.2)
        XCTAssertFalse(monitor.isSilenceWarningActive())

        now = now.addingTimeInterval(4.9)
        XCTAssertFalse(monitor.isSilenceWarningActive())

        now = now.addingTimeInterval(0.2)
        XCTAssertTrue(monitor.isSilenceWarningActive())
    }
}
