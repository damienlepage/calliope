import XCTest
@testable import Calliope

final class OverlayPreferencesStoreTests: XCTestCase {
    func testDefaultsAreOff() {
        let suiteName = "OverlayPreferencesStoreTests.defaults"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Expected test defaults suite")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = OverlayPreferencesStore(defaults: defaults)

        XCTAssertFalse(store.alwaysOnTop)
    }

    func testAlwaysOnTopPersistsAcrossInstances() {
        let suiteName = "OverlayPreferencesStoreTests.persistence"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Expected test defaults suite")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = OverlayPreferencesStore(defaults: defaults)
        store.alwaysOnTop = true

        let reloaded = OverlayPreferencesStore(defaults: defaults)
        XCTAssertTrue(reloaded.alwaysOnTop)
    }
}
