import XCTest
@testable import Calliope

final class PaceFeedbackTests: XCTestCase {
    func testLabelReflectsIdleSlowTargetAndFastRanges() {
        XCTAssertEqual(PaceFeedback.label(for: 0, minPace: 120, maxPace: 160), "Listening")
        XCTAssertEqual(PaceFeedback.label(for: 100, minPace: 120, maxPace: 160), "Slow")
        XCTAssertEqual(PaceFeedback.label(for: 140, minPace: 120, maxPace: 160), "On Target")
        XCTAssertEqual(PaceFeedback.label(for: 180, minPace: 120, maxPace: 160), "Fast")
    }

    func testValueTextFormatsIdleAndActivePace() {
        XCTAssertEqual(PaceFeedback.valueText(for: -5), "—")
        XCTAssertEqual(PaceFeedback.valueText(for: 155.9), "155 WPM")
    }

    func testTargetRangeTextUsesMinMaxOrder() {
        let text = PaceFeedback.targetRangeText(minPace: 150, maxPace: 120)

        XCTAssertEqual(text, "120-150 WPM")
    }

    func testTargetRangeTextFormatsWholeNumbers() {
        let text = PaceFeedback.targetRangeText(minPace: 110.4, maxPace: 169.6)

        XCTAssertEqual(text, "110-169 WPM")
    }

    func testValueTextUsesWPMForPositivePace() {
        let text = PaceFeedback.valueText(for: 165.2)

        XCTAssertEqual(text, "165 WPM")
    }

    func testValueTextShowsDashForIdlePace() {
        let text = PaceFeedback.valueText(for: 0)

        XCTAssertEqual(text, "—")
    }

    func testLabelAndValueFormattingAcrossRanges() {
        let minPace = 120.0
        let maxPace = 160.0

        XCTAssertEqual(PaceFeedback.label(for: 0, minPace: minPace, maxPace: maxPace), "Listening")
        XCTAssertEqual(PaceFeedback.valueText(for: 0), "—")

        XCTAssertEqual(PaceFeedback.label(for: 110, minPace: minPace, maxPace: maxPace), "Slow")
        XCTAssertEqual(PaceFeedback.valueText(for: 110), "110 WPM")

        XCTAssertEqual(PaceFeedback.label(for: 140, minPace: minPace, maxPace: maxPace), "On Target")
        XCTAssertEqual(PaceFeedback.valueText(for: 140), "140 WPM")

        XCTAssertEqual(PaceFeedback.label(for: 190, minPace: minPace, maxPace: maxPace), "Fast")
        XCTAssertEqual(PaceFeedback.valueText(for: 190), "190 WPM")
    }
}
