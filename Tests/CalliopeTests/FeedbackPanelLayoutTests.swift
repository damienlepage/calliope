import SwiftUI
import XCTest
@testable import Calliope

final class FeedbackPanelLayoutTests: XCTestCase {
    func testFeedbackPanelLayoutUsesSingleColumnForAccessibilitySizes() {
        XCTAssertTrue(
            FeedbackPanelLayout.usesSingleColumn(dynamicTypeSize: .accessibility2)
        )
        XCTAssertFalse(
            FeedbackPanelLayout.usesSingleColumn(dynamicTypeSize: .large)
        )
    }
}
