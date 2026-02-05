import XCTest
@testable import Calliope

final class AnalysisPreferencesStoreTests: XCTestCase {
    func testDefaultsMatchConstants() {
        let suiteName = "AnalysisPreferencesStoreTests.defaults"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Expected test defaults suite")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = AnalysisPreferencesStore(defaults: defaults)

        XCTAssertEqual(store.paceMin, Constants.targetPaceMin)
        XCTAssertEqual(store.paceMax, Constants.targetPaceMax)
        XCTAssertEqual(store.pauseThreshold, Constants.pauseThreshold)
        XCTAssertEqual(store.crutchWords, Constants.crutchWords)
    }

    func testPreferencesPersistAcrossInstances() {
        let suiteName = "AnalysisPreferencesStoreTests.persistence"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Expected test defaults suite")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = AnalysisPreferencesStore(defaults: defaults)
        store.paceMin = 100
        store.paceMax = 160
        store.pauseThreshold = 2.5
        store.crutchWords = ["alpha", "beta", "you know"]

        let reloaded = AnalysisPreferencesStore(defaults: defaults)
        XCTAssertEqual(reloaded.paceMin, 100)
        XCTAssertEqual(reloaded.paceMax, 160)
        XCTAssertEqual(reloaded.pauseThreshold, 2.5)
        XCTAssertEqual(reloaded.crutchWords, ["alpha", "beta", "you know"])
    }
}
