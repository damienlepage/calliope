//
//  ActiveProfileLabelFormatterTests.swift
//  CalliopeTests
//
//  Created on [Date]
//

import XCTest
@testable import Calliope

final class ActiveProfileLabelFormatterTests: XCTestCase {
    func testLabelIsNilWhenNotRecording() {
        let profile = PerAppFeedbackProfile.default(for: "com.zoom.us")

        XCTAssertNil(ActiveProfileLabelFormatter.labelText(
            isRecording: false,
            profile: profile
        ))
    }

    func testLabelUsesDefaultWhenRecordingWithoutProfile() {
        XCTAssertEqual(
            ActiveProfileLabelFormatter.labelText(isRecording: true, profile: nil),
            "Profile: Default"
        )
    }

    func testLabelUsesProfileIdentifierWhenRecording() {
        let profile = PerAppFeedbackProfile.default(for: "com.zoom.us")

        XCTAssertEqual(
            ActiveProfileLabelFormatter.labelText(isRecording: true, profile: profile),
            "Profile: com.zoom.us"
        )
    }
}
