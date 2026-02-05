import XCTest
@testable import Calliope

final class SoundSettingsActionModelTests: XCTestCase {
    private final class TestOpener: SystemSettingsOpening {
        private(set) var openSoundCount = 0

        func openMicrophonePrivacy() { }

        func openSoundInput() {
            openSoundCount += 1
        }
    }

    func testShouldShowActionWhenOnlyMicrophoneUnavailable() {
        let model = SoundSettingsActionModel(opener: TestOpener())

        XCTAssertTrue(
            model.shouldShow(for: [.microphoneUnavailable])
        )
    }

    func testShouldHideActionWhenOtherBlockingReasonsPresent() {
        let model = SoundSettingsActionModel(opener: TestOpener())

        XCTAssertFalse(
            model.shouldShow(for: [.microphoneUnavailable, .microphonePermissionDenied])
        )
        XCTAssertFalse(
            model.shouldShow(for: [.microphoneUnavailable, .disclosureNotAccepted])
        )
        XCTAssertFalse(
            model.shouldShow(for: [])
        )
    }

    func testOpenSoundSettingsInvokesOpener() {
        let opener = TestOpener()
        let model = SoundSettingsActionModel(opener: opener)

        model.openSoundSettings()

        XCTAssertEqual(opener.openSoundCount, 1)
    }
}
