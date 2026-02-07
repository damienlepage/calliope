import XCTest
@testable import Calliope

final class CoachingProfileStoreTests: XCTestCase {
    func testDefaultProfileIsSeededAndSelected() {
        let defaults = makeDefaults("CoachingProfileStoreTests.seeded")

        let store = CoachingProfileStore(defaults: defaults)

        XCTAssertEqual(store.profiles.count, 3)
        XCTAssertEqual(store.profiles.first?.name, "Default")
        XCTAssertTrue(store.profiles.map(\.name).contains("Focused"))
        XCTAssertTrue(store.profiles.map(\.name).contains("Conversational"))
        XCTAssertEqual(store.selectedProfile?.name, "Default")
        XCTAssertEqual(store.selectedProfileID, store.profiles.first?.id)
    }

    func testAddProfileTrimsNameAndRejectsEmpty() {
        let defaults = makeDefaults("CoachingProfileStoreTests.normalize")
        let store = CoachingProfileStore(defaults: defaults)

        let added = store.addProfile(name: " Interview Prep ", preferences: .default)
        XCTAssertEqual(added?.name, "Interview Prep")

        let rejected = store.addProfile(name: "   ", preferences: .default)
        XCTAssertNil(rejected)
        XCTAssertEqual(store.profiles.count, 4)
    }

    func testProfilePersistsAcrossLoads() {
        let defaults = makeDefaults("CoachingProfileStoreTests.persist")
        let profileID: UUID

        do {
            let store = CoachingProfileStore(defaults: defaults)
            guard let created = store.addProfile(
                name: "Interview Prep",
                preferences: AnalysisPreferences(
                    paceMin: 130,
                    paceMax: 170,
                    pauseThreshold: 1.1,
                    crutchWords: ["um", "like"],
                    speakingTimeTargetPercent: 45
                )
            ) else {
                XCTFail("Expected to create a coaching profile")
                profileID = UUID()
                return
            }
            profileID = created.id
            store.selectProfile(id: created.id)
        }

        let reloaded = CoachingProfileStore(defaults: defaults)
        XCTAssertEqual(reloaded.profiles.count, 4)
        XCTAssertNotNil(reloaded.profiles.first { $0.id == profileID })
        XCTAssertEqual(reloaded.selectedProfileID, profileID)
    }

    func testSelectionFallsBackWhenProfileIsRemoved() {
        let defaults = makeDefaults("CoachingProfileStoreTests.selectionFallback")
        let store = CoachingProfileStore(defaults: defaults)
        let second = store.addProfile(name: "Second", preferences: .default)
        if let second {
            store.selectProfile(id: second.id)
        }

        if let second {
            store.removeProfile(id: second.id)
        }

        XCTAssertEqual(store.selectedProfileID, store.profiles.first?.id)
    }

    func testSetProfileNormalizesNameAndPreferences() {
        let defaults = makeDefaults("CoachingProfileStoreTests.setProfile")
        let store = CoachingProfileStore(defaults: defaults)
        guard let existing = store.profiles.first else {
            XCTFail("Expected a seeded profile")
            return
        }

        var updated = existing
        updated.name = " Focused "
        updated.preferences = AnalysisPreferences(
            paceMin: 190,
            paceMax: 140,
            pauseThreshold: 0,
            crutchWords: ["Um", " ", "um", "Like"],
            speakingTimeTargetPercent: 5
        )
        store.setProfile(updated)

        guard let stored = store.profiles.first(where: { $0.id == existing.id }) else {
            XCTFail("Expected updated profile")
            return
        }
        XCTAssertEqual(stored.name, "Focused")
        XCTAssertLessThanOrEqual(stored.preferences.paceMin, stored.preferences.paceMax)
        XCTAssertGreaterThan(stored.preferences.pauseThreshold, 0)
        XCTAssertEqual(stored.preferences.crutchWords, ["um", "like"])
        XCTAssertEqual(stored.preferences.speakingTimeTargetPercent, Constants.speakingTimeTargetPercent)
    }

    private func makeDefaults(_ suiteName: String) -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
