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
                crutchWords: ["um", "you know"],
                speakingTimeTargetPercent: 50
            )
            store.setProfile(profile)
        }

        let reloaded = PerAppFeedbackProfileStore(defaults: defaults)
        XCTAssertEqual(reloaded.profiles.count, 1)
        XCTAssertEqual(reloaded.profile(for: "us.zoom.xos")?.paceMin, 130)
        XCTAssertEqual(reloaded.profile(for: "us.zoom.xos")?.crutchWords, ["um", "you know"])
        XCTAssertEqual(reloaded.profile(for: "us.zoom.xos")?.speakingTimeTargetPercent, 50)
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
            crutchWords: [" Um ", "um", " ", "So"],
            speakingTimeTargetPercent: 5
        )

        store.setProfile(profile)

        let normalized = store.profile(for: "com.microsoft.teams")
        XCTAssertEqual(normalized?.paceMin, 140)
        XCTAssertEqual(normalized?.paceMax, 200)
        XCTAssertEqual(normalized?.pauseThreshold, Constants.pauseThreshold)
        XCTAssertEqual(normalized?.crutchWords, ["um", "so"])
        XCTAssertEqual(normalized?.speakingTimeTargetPercent, Constants.speakingTimeTargetPercent)
    }

    func testAddProfileNormalizesIdentifierAndUsesDefaults() {
        let suiteName = "PerAppFeedbackProfileStoreTests.add"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = PerAppFeedbackProfileStore(defaults: defaults)
        let created = store.addProfile(appIdentifier: " Us.Zoom.XOS ")

        XCTAssertEqual(created?.appIdentifier, "us.zoom.xos")
        let profile = store.profile(for: "us.zoom.xos")
        XCTAssertEqual(profile?.paceMin, Constants.targetPaceMin)
        XCTAssertEqual(profile?.paceMax, Constants.targetPaceMax)
        XCTAssertEqual(profile?.pauseThreshold, Constants.pauseThreshold)
        XCTAssertEqual(profile?.speakingTimeTargetPercent, Constants.speakingTimeTargetPercent)
    }

    func testProfileLookupNormalizesIdentifier() {
        let suiteName = "PerAppFeedbackProfileStoreTests.lookup"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = PerAppFeedbackProfileStore(defaults: defaults)
        store.setProfile(
            PerAppFeedbackProfile(
                appIdentifier: "com.microsoft.teams",
                paceMin: 120,
                paceMax: 180,
                pauseThreshold: 1.1,
                crutchWords: ["um"],
                speakingTimeTargetPercent: 35
            )
        )

        XCTAssertNotNil(store.profile(for: " COM.MICROSOFT.TEAMS "))
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
