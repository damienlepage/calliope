import XCTest
@testable import Calliope

final class PerAppFeedbackProfileStoreTests: XCTestCase {
    func testDefaultsAreEmpty() {
        let suiteName = "PerAppFeedbackProfileStoreTests.defaults"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = PerAppFeedbackProfileStore(defaults: defaults)

        XCTAssertTrue(store.profiles.isEmpty)
    }

    func testProfilePersistsAcrossLoads() {
        let suiteName = "PerAppFeedbackProfileStoreTests.persist"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        do {
            let store = PerAppFeedbackProfileStore(defaults: defaults)
            let profile = PerAppFeedbackProfile(
                appIdentifier: "us.zoom.xos",
                paceMin: 130,
                paceMax: 190,
                pauseThreshold: 1.2,
                crutchWords: ["um", "you know"]
            )
            store.setProfile(profile)
        }

        let reloaded = PerAppFeedbackProfileStore(defaults: defaults)
        XCTAssertEqual(reloaded.profiles.count, 1)
        XCTAssertEqual(reloaded.profile(for: "us.zoom.xos")?.paceMin, 130)
        XCTAssertEqual(reloaded.profile(for: "us.zoom.xos")?.crutchWords, ["um", "you know"])
    }

    func testProfileNormalizationAdjustsInvalidValues() {
        let suiteName = "PerAppFeedbackProfileStoreTests.normalize"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = PerAppFeedbackProfileStore(defaults: defaults)
        let profile = PerAppFeedbackProfile(
            appIdentifier: "com.microsoft.teams",
            paceMin: 200,
            paceMax: 140,
            pauseThreshold: 0,
            crutchWords: [" Um ", "um", " ", "So"]
        )

        store.setProfile(profile)

        let normalized = store.profile(for: "com.microsoft.teams")
        XCTAssertEqual(normalized?.paceMin, 140)
        XCTAssertEqual(normalized?.paceMax, 200)
        XCTAssertEqual(normalized?.pauseThreshold, Constants.pauseThreshold)
        XCTAssertEqual(normalized?.crutchWords, ["um", "so"])
    }

    func testRemoveProfileClearsEntry() {
        let suiteName = "PerAppFeedbackProfileStoreTests.remove"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = PerAppFeedbackProfileStore(defaults: defaults)
        store.setProfile(PerAppFeedbackProfile.default(for: "com.google.meet"))
        store.removeProfile(appIdentifier: "com.google.meet")

        XCTAssertNil(store.profile(for: "com.google.meet"))
        XCTAssertTrue(store.profiles.isEmpty)
    }
}
