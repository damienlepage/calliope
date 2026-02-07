//
//  AccessibilityFormattingTests.swift
//  CalliopeTests
//
//  Created on [Date]
//

import XCTest
@testable import Calliope

final class AccessibilityFormattingTests: XCTestCase {
    func testPaceValueIncludesComponents() {
        let value = AccessibilityFormatting.paceValue(
            pace: 155,
            minPace: 120,
            maxPace: 180
        )

        XCTAssertTrue(value.contains("WPM"))
        XCTAssertTrue(value.contains("Target"))
    }

    func testInputLevelValueCombinesStatusAndPercent() {
        let value = AccessibilityFormatting.inputLevelValue(level: 0.42, statusText: "Low signal")

        XCTAssertTrue(value.contains("Low signal"))
        XCTAssertTrue(value.contains("42%"))
    }

    func testMetricValueCombinesParts() {
        let value = AccessibilityFormatting.metricValue(
            value: "3",
            subtitle: "Target: <= 5",
            accessory: "0.8/min"
        )

        XCTAssertEqual(value, "3, Target: <= 5, 0.8/min")
    }

    func testPercentTextClampsInput() {
        XCTAssertEqual(AccessibilityFormatting.percentText(for: -0.1), "0%")
        XCTAssertEqual(AccessibilityFormatting.percentText(for: 1.2), "100%")
    }

    func testWarningValueFallsBackWhenEmpty() {
        XCTAssertEqual(AccessibilityFormatting.warningValue(text: "  "), "Warning")
        XCTAssertEqual(AccessibilityFormatting.warningValue(text: "Low storage"), "Low storage")
    }

    func testStatusValueCombinesWarningsAndNotes() {
        let value = AccessibilityFormatting.statusValue(
            warnings: ["Low storage", "Mic disconnected"],
            notes: ["Waiting for speech"]
        )

        XCTAssertTrue(value.contains("Warnings: Low storage; Mic disconnected"))
        XCTAssertTrue(value.contains("Notes: Waiting for speech"))
    }

    func testStatusValueHandlesEmptyInputs() {
        XCTAssertEqual(
            AccessibilityFormatting.statusValue(warnings: ["  "], notes: []),
            "No status updates"
        )
    }

    func testDetailLinesValueFiltersAndJoins() {
        XCTAssertEqual(
            AccessibilityFormatting.detailLinesValue(["Average: 120 WPM", " ", "Range: 90-140 WPM"]),
            "Average: 120 WPM, Range: 90-140 WPM"
        )
        XCTAssertEqual(
            AccessibilityFormatting.detailLinesValue(["  "]),
            "No details available"
        )
    }
}
