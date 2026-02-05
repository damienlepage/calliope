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

    func testParseCrutchWordsDeduplicatesAndNormalizes() {
        let input = "Uh, um, uh, You know\nUM\n  so  ,"
        let parsed = AnalysisPreferencesStore.parseCrutchWords(from: input)

        XCTAssertEqual(parsed, ["uh", "um", "you know", "so"])
    }

    func testStoreNormalizesPersistedValuesOnLoad() {
        let suiteName = "AnalysisPreferencesStoreTests.normalizeOnLoad"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Expected test defaults suite")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(200.0, forKey: "analysisPreferences.paceMin")
        defaults.set(120.0, forKey: "analysisPreferences.paceMax")
        defaults.set(-2.0, forKey: "analysisPreferences.pauseThreshold")
        defaults.set([" Uh ", "um", "UM", ""], forKey: "analysisPreferences.crutchWords")

        let store = AnalysisPreferencesStore(defaults: defaults)

        XCTAssertEqual(store.paceMin, 120.0)
        XCTAssertEqual(store.paceMax, 200.0)
        XCTAssertEqual(store.pauseThreshold, Constants.pauseThreshold)
        XCTAssertEqual(store.crutchWords, ["uh", "um"])
    }

    func testResetToDefaultsRestoresValuesAndPersists() {
        let suiteName = "AnalysisPreferencesStoreTests.reset"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Expected test defaults suite")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = AnalysisPreferencesStore(defaults: defaults)
        store.paceMin = 90
        store.paceMax = 190
        store.pauseThreshold = 3.0
        store.crutchWords = ["alpha", "beta"]

        store.resetToDefaults()

        XCTAssertEqual(store.paceMin, Constants.targetPaceMin)
        XCTAssertEqual(store.paceMax, Constants.targetPaceMax)
        XCTAssertEqual(store.pauseThreshold, Constants.pauseThreshold)
        XCTAssertEqual(store.crutchWords, Constants.crutchWords)

        let reloaded = AnalysisPreferencesStore(defaults: defaults)
        XCTAssertEqual(reloaded.paceMin, Constants.targetPaceMin)
        XCTAssertEqual(reloaded.paceMax, Constants.targetPaceMax)
        XCTAssertEqual(reloaded.pauseThreshold, Constants.pauseThreshold)
        XCTAssertEqual(reloaded.crutchWords, Constants.crutchWords)
    }
}
