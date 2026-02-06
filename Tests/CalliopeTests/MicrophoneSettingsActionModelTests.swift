import XCTest
@testable import Calliope

final class MicrophoneSettingsActionModelTests: XCTestCase {
    private final class TestOpener: SystemSettingsOpening {
        private(set) var openCount = 0

        func openMicrophonePrivacy() {
            openCount += 1
        }

        func openSpeechRecognitionPrivacy() { }

        func openSoundInput() { }
    }

    func testShouldShowActionForDeniedOrRestricted() {
        let model = MicrophoneSettingsActionModel(opener: TestOpener())

        XCTAssertTrue(
            model.shouldShow(for: [.microphonePermissionDenied])
        )
        XCTAssertTrue(
            model.shouldShow(for: [.microphonePermissionRestricted])
        )
        XCTAssertTrue(
            model.shouldShow(for: [.disclosureNotAccepted, .microphonePermissionDenied])
        )
    }

    func testShouldHideActionForNonBlockingPermissionStates() {
        let model = MicrophoneSettingsActionModel(opener: TestOpener())

        XCTAssertFalse(
            model.shouldShow(for: [.microphonePermissionNotDetermined])
        )
        XCTAssertFalse(
            model.shouldShow(for: [.microphoneUnavailable])
        )
        XCTAssertFalse(
            model.shouldShow(for: [])
        )
    }

    func testOpenSystemSettingsInvokesOpener() {
        let opener = TestOpener()
        let model = MicrophoneSettingsActionModel(opener: opener)

        model.openSystemSettings()

        XCTAssertEqual(opener.openCount, 1)
    }
}
