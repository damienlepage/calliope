import AppKit
import XCTest
@testable import Calliope

@MainActor
final class AppLifecycleMonitorTests: XCTestCase {
    func testUpdatesIsActiveOnNotifications() {
        let notificationCenter = NotificationCenter()
        let monitor = AppLifecycleMonitor(
            notificationCenter: notificationCenter,
            initialIsActive: true
        )

        XCTAssertTrue(monitor.isActive)

        notificationCenter.post(name: NSApplication.willResignActiveNotification, object: nil)

        let resignExpectation = expectation(description: "Resign active handled")
        DispatchQueue.main.async {
            resignExpectation.fulfill()
        }
        wait(for: [resignExpectation], timeout: 1.0)

        XCTAssertFalse(monitor.isActive)

        notificationCenter.post(name: NSApplication.didBecomeActiveNotification, object: nil)

        let becomeExpectation = expectation(description: "Become active handled")
        DispatchQueue.main.async {
            becomeExpectation.fulfill()
        }
        wait(for: [becomeExpectation], timeout: 1.0)

        XCTAssertTrue(monitor.isActive)
    }
}
