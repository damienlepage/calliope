import XCTest
@testable import Calliope

final class AppNavigationStateTests: XCTestCase {
    func testDefaultSelectionIsSession() {
        let state = AppNavigationState()

        XCTAssertEqual(state.selection, .session)
    }

    func testSectionTitlesMatchDefaults() {
        XCTAssertEqual(AppSection.session.title, "Session")
        XCTAssertEqual(AppSection.recordings.title, "Recordings")
        XCTAssertEqual(AppSection.settings.title, "Settings")
    }
}
