import XCTest
@testable import Calliope

final class RecordingRetentionPreferencesStoreTests: XCTestCase {
    func testDefaultsDisableAutoCleanAndUseThirtyDays() {
        let suiteName = "RecordingRetentionPreferencesStoreTests.defaults"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Expected test defaults suite")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = RecordingRetentionPreferencesStore(defaults: defaults)

        XCTAssertFalse(store.autoCleanEnabled)
        XCTAssertEqual(store.retentionOption, .days30)
    }

    func testPreferencesPersistAcrossInstances() {
        let suiteName = "RecordingRetentionPreferencesStoreTests.persistence"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Expected test defaults suite")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = RecordingRetentionPreferencesStore(defaults: defaults)
        store.autoCleanEnabled = true
        store.retentionOption = .days90

        let reloaded = RecordingRetentionPreferencesStore(defaults: defaults)

        XCTAssertTrue(reloaded.autoCleanEnabled)
        XCTAssertEqual(reloaded.retentionOption, .days90)
    }
}
