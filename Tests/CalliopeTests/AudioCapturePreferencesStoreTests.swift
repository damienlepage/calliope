import XCTest
@testable import Calliope

final class AudioCapturePreferencesStoreTests: XCTestCase {
    func testDefaultsUseVoiceIsolationEnabled() {
        let suiteName = "AudioCapturePreferencesStoreTests.defaults"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = AudioCapturePreferencesStore(defaults: defaults)

        XCTAssertTrue(store.voiceIsolationEnabled)
        XCTAssertEqual(store.current.voiceIsolationEnabled, true)
    }

    func testVoiceIsolationPreferencePersists() {
        let suiteName = "AudioCapturePreferencesStoreTests.persist"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        do {
            let store = AudioCapturePreferencesStore(defaults: defaults)
            store.voiceIsolationEnabled = false
        }

        let reloaded = AudioCapturePreferencesStore(defaults: defaults)
        XCTAssertFalse(reloaded.voiceIsolationEnabled)
        XCTAssertEqual(reloaded.current.voiceIsolationEnabled, false)
    }
}
