//
//  CaptureDiagnosticsFormatterTests.swift
//  CalliopeTests
//
//  Created on [Date]
//

import XCTest
@testable import Calliope

final class CaptureDiagnosticsFormatterTests: XCTestCase {
    func testInputFormatLabelFormatsSampleRateAndChannels() {
        let label = CaptureDiagnosticsFormatter.inputFormatLabel(
            sampleRate: 44_100,
            channelCount: 1
        )
        XCTAssertEqual(label, "44.1 kHz · 1 ch")
    }

    func testInputFormatLabelOmitsDecimalForWholeKilohertz() {
        let label = CaptureDiagnosticsFormatter.inputFormatLabel(
            sampleRate: 48_000,
            channelCount: 2
        )
        XCTAssertEqual(label, "48 kHz · 2 ch")
    }

    func testSelectedInputLabelUsesPreferredWhenAvailable() {
        let label = CaptureDiagnosticsFormatter.selectedInputLabel(
            preferredName: "USB Mic",
            availableNames: ["USB Mic", "Built-in"],
            defaultName: "Built-in"
        )
        XCTAssertEqual(label, "USB Mic")
    }

    func testSelectedInputLabelMarksPreferredUnavailable() {
        let label = CaptureDiagnosticsFormatter.selectedInputLabel(
            preferredName: "Studio Mic",
            availableNames: ["Built-in"],
            defaultName: "Built-in"
        )
        XCTAssertEqual(label, "Studio Mic (Unavailable)")
    }

    func testSelectedInputLabelUsesSystemDefaultName() {
        let label = CaptureDiagnosticsFormatter.selectedInputLabel(
            preferredName: nil,
            availableNames: ["Built-in"],
            defaultName: "Built-in"
        )
        XCTAssertEqual(label, "System Default (Built-in)")
    }

    func testSelectedInputLabelUsesSystemDefaultWhenUnknown() {
        let label = CaptureDiagnosticsFormatter.selectedInputLabel(
            preferredName: nil,
            availableNames: [],
            defaultName: nil
        )
        XCTAssertEqual(label, "System Default")
    }
}
