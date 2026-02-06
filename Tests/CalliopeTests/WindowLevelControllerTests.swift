import AppKit
import XCTest
@testable import Calliope

final class WindowLevelControllerTests: XCTestCase {
    func testAlwaysOnTopSetsFloatingLevel() {
        let window = FakeWindow()
        let controllerWindows = [window]

        WindowLevelController.apply(
            alwaysOnTop: true,
            windowsProvider: { controllerWindows },
            scheduler: { $0() }
        )

        XCTAssertEqual(window.level, .floating)
    }

    func testDisablingAlwaysOnTopSetsNormalLevel() {
        let window = FakeWindow()
        window.level = .floating
        let controllerWindows = [window]

        WindowLevelController.apply(
            alwaysOnTop: false,
            windowsProvider: { controllerWindows },
            scheduler: { $0() }
        )

        XCTAssertEqual(window.level, .normal)
    }
}

private final class FakeWindow: WindowLevelTarget {
    var level: NSWindow.Level = .normal
}
