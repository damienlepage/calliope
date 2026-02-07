import XCTest
@testable import Calliope

@MainActor
final class SettingsViewTests: XCTestCase {
    private struct StubMicrophoneProvider: MicrophoneDeviceProviding {
        let devices: [AudioInputDevice]
        let defaultDevice: AudioInputDevice?

        func availableMicrophones() -> [AudioInputDevice] {
            devices
        }

        func defaultMicrophone() -> AudioInputDevice? {
            defaultDevice
        }
    }

    func testSettingsViewBuilds() {
        let view = SettingsView(
            microphonePermission: MicrophonePermissionManager(),
            speechPermission: SpeechPermissionManager(),
            microphoneDevices: MicrophoneDeviceManager(),
            preferencesStore: AnalysisPreferencesStore(),
            overlayPreferencesStore: OverlayPreferencesStore(),
            audioCapturePreferencesStore: AudioCapturePreferencesStore(),
            coachingProfileStore: CoachingProfileStore(),
            hasAcceptedDisclosure: true,
            recordingsPath: "/Users/you/Recordings",
            showOpenSettingsAction: false,
            showOpenSoundSettingsAction: false,
            showOpenSpeechSettingsAction: false,
            onRequestMicAccess: {},
            onRequestSpeechAccess: {},
            onOpenSystemSettings: {},
            onOpenSoundSettings: {},
            onOpenSpeechSettings: {}
        )

        _ = view.body
    }

    func testSettingsViewBuildsWithNoMicrophone() {
        let emptyProvider = StubMicrophoneProvider(devices: [], defaultDevice: nil)
        let microphoneDevices = MicrophoneDeviceManager(provider: emptyProvider)
        let view = SettingsView(
            microphonePermission: MicrophonePermissionManager(),
            speechPermission: SpeechPermissionManager(),
            microphoneDevices: microphoneDevices,
            preferencesStore: AnalysisPreferencesStore(),
            overlayPreferencesStore: OverlayPreferencesStore(),
            audioCapturePreferencesStore: AudioCapturePreferencesStore(),
            coachingProfileStore: CoachingProfileStore(),
            hasAcceptedDisclosure: false,
            recordingsPath: "/Users/you/Recordings",
            showOpenSettingsAction: true,
            showOpenSoundSettingsAction: true,
            showOpenSpeechSettingsAction: true,
            onRequestMicAccess: {},
            onRequestSpeechAccess: {},
            onOpenSystemSettings: {},
            onOpenSoundSettings: {},
            onOpenSpeechSettings: {}
        )

        _ = view.body
    }
}
