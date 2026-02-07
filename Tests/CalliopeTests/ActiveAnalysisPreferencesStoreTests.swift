import Combine
import XCTest

@testable import Calliope

final class ActiveAnalysisPreferencesStoreTests: XCTestCase {
    func testUsesBasePreferencesWhenNotRecording() {
        let baseDefaults = makeDefaults("ActiveAnalysisPreferencesStoreTests.base.notRecording")
        let profileDefaults = makeDefaults("ActiveAnalysisPreferencesStoreTests.profile.notRecording")
        let coachingDefaults = makeDefaults("ActiveAnalysisPreferencesStoreTests.coaching.notRecording")
        let baseStore = AnalysisPreferencesStore(defaults: baseDefaults)
        baseStore.paceMin = 110
        baseStore.paceMax = 160
        baseStore.pauseThreshold = 1.5
        baseStore.crutchWords = ["uh"]

        let profileStore = PerAppFeedbackProfileStore(defaults: profileDefaults)
        profileStore.setProfile(
            PerAppFeedbackProfile(
                appIdentifier: "us.zoom.xos",
                paceMin: 130,
                paceMax: 170,
                pauseThreshold: 0.8,
                crutchWords: ["like"]
            )
        )
        let coachingStore = CoachingProfileStore(defaults: coachingDefaults)
        let coachingProfile = coachingStore.addProfile(
            name: "Focused",
            preferences: AnalysisPreferences(
                paceMin: 140,
                paceMax: 190,
                pauseThreshold: 0.6,
                crutchWords: ["actually"]
            )
        )
        if let coachingProfile {
            coachingStore.selectProfile(id: coachingProfile.id)
        }

        let frontmost = CurrentValueSubject<String?, Never>(nil)
        let recording = CurrentValueSubject<Bool, Never>(false)
        let store = ActiveAnalysisPreferencesStore(
            basePreferencesStore: baseStore,
            coachingProfileStore: coachingStore,
            perAppProfileStore: profileStore,
            frontmostAppPublisher: frontmost.eraseToAnyPublisher(),
            recordingPublisher: recording.eraseToAnyPublisher()
        )

        let expectation = expectation(description: "resolved base preferences")
        let cancellable = store.$activePreferences
            .dropFirst()
            .sink { _ in expectation.fulfill() }

        frontmost.send("us.zoom.xos")

        wait(for: [expectation], timeout: 1.0)
        cancellable.cancel()

        XCTAssertEqual(store.activePreferences, baseStore.current)
        XCTAssertNil(store.activeProfile)
        XCTAssertNil(store.activeAppIdentifier)
    }

    func testUsesProfileWhenRecording() {
        let baseDefaults = makeDefaults("ActiveAnalysisPreferencesStoreTests.base.recording")
        let profileDefaults = makeDefaults("ActiveAnalysisPreferencesStoreTests.profile.recording")
        let coachingDefaults = makeDefaults("ActiveAnalysisPreferencesStoreTests.coaching.recording")
        let baseStore = AnalysisPreferencesStore(defaults: baseDefaults)
        baseStore.paceMin = 120
        baseStore.paceMax = 180
        baseStore.pauseThreshold = 1.2
        baseStore.crutchWords = ["um"]

        let profile = PerAppFeedbackProfile(
            appIdentifier: "us.zoom.xos",
            paceMin: 135,
            paceMax: 165,
            pauseThreshold: 0.7,
            crutchWords: ["like", "so"]
        )
        let profileStore = PerAppFeedbackProfileStore(defaults: profileDefaults)
        profileStore.setProfile(profile)
        let coachingStore = CoachingProfileStore(defaults: coachingDefaults)
        let coachingProfile = coachingStore.addProfile(
            name: "On Air",
            preferences: AnalysisPreferences(
                paceMin: 150,
                paceMax: 190,
                pauseThreshold: 0.9,
                crutchWords: ["basically"]
            )
        )
        if let coachingProfile {
            coachingStore.selectProfile(id: coachingProfile.id)
        }

        let frontmost = CurrentValueSubject<String?, Never>(nil)
        let recording = CurrentValueSubject<Bool, Never>(false)
        let store = ActiveAnalysisPreferencesStore(
            basePreferencesStore: baseStore,
            coachingProfileStore: coachingStore,
            perAppProfileStore: profileStore,
            frontmostAppPublisher: frontmost.eraseToAnyPublisher(),
            recordingPublisher: recording.eraseToAnyPublisher()
        )

        let expectation = expectation(description: "resolved profile preferences")
        let cancellable = store.$activePreferences
            .dropFirst(2)
            .sink { preferences in
                if preferences.paceMin == profile.paceMin {
                    expectation.fulfill()
                }
            }

        frontmost.send("us.zoom.xos")
        recording.send(true)

        wait(for: [expectation], timeout: 1.0)
        cancellable.cancel()

        XCTAssertEqual(store.activePreferences.paceMin, profile.paceMin)
        XCTAssertEqual(store.activePreferences.paceMax, profile.paceMax)
        XCTAssertEqual(store.activePreferences.pauseThreshold, profile.pauseThreshold)
        XCTAssertEqual(store.activePreferences.crutchWords, profile.crutchWords)
        XCTAssertEqual(store.activeAppIdentifier, "us.zoom.xos")
        XCTAssertEqual(store.activeProfile, profile)
    }

    func testFallsBackWhenNoProfile() {
        let baseDefaults = makeDefaults("ActiveAnalysisPreferencesStoreTests.base.noProfile")
        let profileDefaults = makeDefaults("ActiveAnalysisPreferencesStoreTests.profile.noProfile")
        let coachingDefaults = makeDefaults("ActiveAnalysisPreferencesStoreTests.coaching.noProfile")
        let baseStore = AnalysisPreferencesStore(defaults: baseDefaults)
        baseStore.paceMin = 118
        baseStore.paceMax = 172
        baseStore.pauseThreshold = 1.1
        baseStore.crutchWords = ["uh", "um"]

        let profileStore = PerAppFeedbackProfileStore(defaults: profileDefaults)
        let coachingStore = CoachingProfileStore(defaults: coachingDefaults)
        let coachingProfile = coachingStore.addProfile(
            name: "Interview",
            preferences: AnalysisPreferences(
                paceMin: 130,
                paceMax: 165,
                pauseThreshold: 0.8,
                crutchWords: ["so"]
            )
        )
        if let coachingProfile {
            coachingStore.selectProfile(id: coachingProfile.id)
        }
        let frontmost = CurrentValueSubject<String?, Never>(nil)
        let recording = CurrentValueSubject<Bool, Never>(false)
        let store = ActiveAnalysisPreferencesStore(
            basePreferencesStore: baseStore,
            coachingProfileStore: coachingStore,
            perAppProfileStore: profileStore,
            frontmostAppPublisher: frontmost.eraseToAnyPublisher(),
            recordingPublisher: recording.eraseToAnyPublisher()
        )

        let expectation = expectation(description: "resolved fallback preferences")
        let cancellable = store.$activePreferences
            .dropFirst(2)
            .sink { _ in expectation.fulfill() }

        frontmost.send("com.apple.finder")
        recording.send(true)

        wait(for: [expectation], timeout: 1.0)
        cancellable.cancel()

        XCTAssertEqual(store.activePreferences, coachingProfile?.preferences ?? baseStore.current)
        XCTAssertEqual(store.activeAppIdentifier, "com.apple.finder")
        XCTAssertNil(store.activeProfile)
    }

    private func makeDefaults(_ suiteName: String) -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
