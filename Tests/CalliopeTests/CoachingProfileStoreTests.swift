import XCTest
@testable import Calliope

final class CoachingProfileStoreTests: XCTestCase {
    func testDefaultProfileIsSeededAndSelected() {
        let defaults = makeDefaults("CoachingProfileStoreTests.seeded")

        let store = CoachingProfileStore(defaults: defaults)

        XCTAssertEqual(store.profiles.count, 1)
        XCTAssertEqual(store.profiles.first?.name, "Default")
        XCTAssertEqual(store.selectedProfileID, store.profiles.first?.id)
    }

    func testAddProfileTrimsNameAndRejectsEmpty() {
        let defaults = makeDefaults("CoachingProfileStoreTests.normalize")
        let store = CoachingProfileStore(defaults: defaults)

        let added = store.addProfile(name: " Focused ", preferences: .default)
        XCTAssertEqual(added?.name, "Focused")

        let rejected = store.addProfile(name: "   ", preferences: .default)
        XCTAssertNil(rejected)
        XCTAssertEqual(store.profiles.count, 2)
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
                    crutchWords: ["um", "like"]
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
        XCTAssertEqual(reloaded.profiles.count, 2)
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

    private func makeDefaults(_ suiteName: String) -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
