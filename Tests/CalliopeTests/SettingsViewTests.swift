import XCTest
@testable import Calliope

@MainActor
final class SettingsViewTests: XCTestCase {
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
}
