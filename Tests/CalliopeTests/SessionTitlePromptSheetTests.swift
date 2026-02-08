import SwiftUI
import XCTest
@testable import Calliope

@MainActor
final class SessionTitlePromptSheetTests: XCTestCase {
    func testSessionTitlePromptSheetBuilds() {
        let view = SessionTitlePromptSheet(
            defaultTitle: "Session Feb 8 at 9:00am",
            draft: .constant(""),
            onSave: {},
            onSkip: {}
        )

        _ = view.body
    }
}
