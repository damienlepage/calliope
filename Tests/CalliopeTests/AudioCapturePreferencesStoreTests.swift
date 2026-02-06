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
        XCTAssertNil(store.preferredMicrophoneName)
        XCTAssertNil(store.current.preferredMicrophoneName)
        XCTAssertEqual(store.maxSegmentDuration, Constants.maxRecordingSegmentDuration)
        XCTAssertEqual(store.current.maxSegmentDuration, Constants.maxRecordingSegmentDuration)
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

    func testPreferredMicrophoneNamePersists() {
        let suiteName = "AudioCapturePreferencesStoreTests.preferredMic"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        do {
            let store = AudioCapturePreferencesStore(defaults: defaults)
            store.preferredMicrophoneName = "USB Mic"
        }

        let reloaded = AudioCapturePreferencesStore(defaults: defaults)
        XCTAssertEqual(reloaded.preferredMicrophoneName, "USB Mic")
        XCTAssertEqual(reloaded.current.preferredMicrophoneName, "USB Mic")
    }

    func testPreferredMicrophoneNameClearsWhenSetToNil() {
        let suiteName = "AudioCapturePreferencesStoreTests.preferredMicClear"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        do {
            let store = AudioCapturePreferencesStore(defaults: defaults)
            store.preferredMicrophoneName = "USB Mic"
            store.preferredMicrophoneName = nil
        }

        let reloaded = AudioCapturePreferencesStore(defaults: defaults)
        XCTAssertNil(reloaded.preferredMicrophoneName)
        XCTAssertNil(reloaded.current.preferredMicrophoneName)
    }

    func testMaxSegmentDurationPersists() {
        let suiteName = "AudioCapturePreferencesStoreTests.maxSegmentDuration"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        do {
            let store = AudioCapturePreferencesStore(defaults: defaults)
            store.maxSegmentDuration = 3600
        }

        let reloaded = AudioCapturePreferencesStore(defaults: defaults)
        XCTAssertEqual(reloaded.maxSegmentDuration, 3600)
        XCTAssertEqual(reloaded.current.maxSegmentDuration, 3600)
    }
}
