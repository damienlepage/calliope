import XCTest
@testable import Calliope

final class SpeechSettingsActionModelTests: XCTestCase {
    private final class TestOpener: SystemSettingsOpening {
        private(set) var openCount = 0

        func openMicrophonePrivacy() { }

        func openSpeechRecognitionPrivacy() {
            openCount += 1
        }

        func openSoundInput() { }
    }

    func testShouldShowActionForDeniedOrRestricted() {
        let model = SpeechSettingsActionModel(opener: TestOpener())

        XCTAssertTrue(model.shouldShow(state: .denied))
        XCTAssertTrue(model.shouldShow(state: .restricted))
    }

    func testShouldHideActionForNonBlockingStates() {
        let model = SpeechSettingsActionModel(opener: TestOpener())

        XCTAssertFalse(model.shouldShow(state: .authorized))
        XCTAssertFalse(model.shouldShow(state: .notDetermined))
    }

    func testOpenSystemSettingsInvokesOpener() {
        let opener = TestOpener()
        let model = SpeechSettingsActionModel(opener: opener)

        model.openSystemSettings()

        XCTAssertEqual(opener.openCount, 1)
    }
}
