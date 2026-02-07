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
            coachingProfileName: "Focused",
            perAppProfile: profile
        ))
    }

    func testLabelUsesCoachingDefaultAndAppDefaultWhenRecordingWithoutProfiles() {
        XCTAssertEqual(
            ActiveProfileLabelFormatter.labelText(
                isRecording: true,
                coachingProfileName: nil,
                perAppProfile: nil
            ),
            "Profile: Default (App: Default)"
        )
    }

    func testLabelUsesCoachingProfileAndAppIdentifierWhenRecording() {
        let profile = PerAppFeedbackProfile.default(for: "com.zoom.us")

        XCTAssertEqual(
            ActiveProfileLabelFormatter.labelText(
                isRecording: true,
                coachingProfileName: "On Air",
                perAppProfile: profile
            ),
            "Profile: On Air (App: com.zoom.us)"
        )
    }
}
