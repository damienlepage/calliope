import XCTest
@testable import Calliope

final class QuickStartStoreTests: XCTestCase {
    func testQuickStartSeenPersistsInDefaults() {
        let suiteName = "QuickStartStoreTests"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Expected test defaults suite")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = QuickStartStore(defaults: defaults)
        XCTAssertFalse(store.hasSeenQuickStart)

        store.hasSeenQuickStart = true
        let reloaded = QuickStartStore(defaults: defaults)
        XCTAssertTrue(reloaded.hasSeenQuickStart)
    }
}
